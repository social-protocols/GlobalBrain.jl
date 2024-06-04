function process_vote_events_stream(db::SQLite.DB, input_stream, output_stream)
    last_processed_vote_event_id = get_last_processed_vote_event_id(db)
    @info "Last processed vote event: $last_processed_vote_event_id"

    for line in eachline(input_stream)
        if line == ""
            continue
        end
        vote_event = as_vote_event_or_throw(IOBuffer(line))
        @info (
            "Got vote event $(vote_event.vote_event_id) on post:" *
            " $(vote_event.post_id) ($(vote_event.vote)) at $(Dates.format(now(), "HH:MM:SS"))"
        )

        # The anonymous function provided here is used by the score_tree function to output
        # both `EffectEvent`s and `ScoreEvent`s. The `object` parameter is thus either a
        # ScoreEvent or an EffectEvent.
        process_vote_event(db::SQLite.DB, vote_event) do object
            e = as_event(vote_event.vote_event_id, vote_event.vote_event_time, object)
            insert_event(db, e)
            json_data = JSON.json(e)
            write(output_stream, json_data * "\n")
        end
    end

    close(db)
end


function replay_vote_event(output_event::Function, db::SQLite.DB, vote_event::VoteEvent)

    existing_vote_event = get_vote_event(db, vote_event.vote_event_id)

    @info "Existing vote event $existing_vote_event"
    if existing_vote_event == nothing
        @error "Vote event $(vote_event.vote_event_id) not found in the database"
        return
    end

    if existing_vote_event != vote_event
        @error "Vote event $(vote_event) not identical to previous event with same id ($existing_vote_event)"
        return
    end

    for event in get_effects_for_vote_event(db, vote_event.vote_event_id)
        output_event(event)
    end

    score_events = get_scores_for_vote_event(db, vote_event.vote_event_id)

    # There is always a score event, but not necessarily an effect event.
    if length(score_events) == 0
        throw("Missing score event for vote_event_id=$(vote_event.vote_event_id)")
    end


    for event in score_events
        output_event(event)
    end

end


function process_vote_event(output_event::Function, db::SQLite.DB, vote_event::VoteEvent)
    last_processed_vote_event_id = get_last_processed_vote_event_id(db)
    if vote_event.vote_event_id <= last_processed_vote_event_id
        replay_vote_event(output_event, db, vote_event)
        return
    end

    insert_vote_event(db, vote_event)

    tallies_data = get_tallies_data(db, vote_event.tag_id, nothing)

    score_posts(output_event, tallies_data)

    set_last_processed_vote_event_id(db, vote_event.vote_event_id)

    return
end


global dbs = Dict{String,SQLite.DB}()


# C-compatible wrapper. This should only be called by the node binding in binding.cc
Base.@ccallable function process_vote_event_json_c(
    database_path_c::Cstring,
    voteEvent_c::Cstring,
)::Cstring
    try
        # Convert C strings to Julia strings
        database_path = unsafe_string(database_path_c)
        voteEvent = unsafe_string(voteEvent_c)

        # Call the original Julia function
        result = process_vote_event_json(database_path, voteEvent)

        # Malloc a new buffer for the results. This buffer should be freed by the
        # caller, which is the node binding.
        byte_len = sizeof(result)

        # Allocate memory, adding 1 byte for the null terminator
        buffer = Libc.malloc(byte_len + 1)

        if buffer == C_NULL
            @error "Failed to allocate memory in process_vote_event_json_c"
            return
        end

        # copy results to this new buffer.
        unsafe_copyto!(Ptr{UInt8}(buffer), pointer(result, 1), byte_len)

        # add null terminator
        unsafe_store!(Ptr{UInt8}(buffer) + byte_len, 0)

        return buffer
    catch e
        stacktrace(catch_backtrace())
        @error "Error in process_vote_event_json_c" exception = e
        return
    end
end

function process_vote_event_json(database_path::String, voteEvent::String)::String
    # SQLite instance needs to be initiated lazily when calling from Javascript
    if (!haskey(dbs, database_path))
        dbs[database_path] = get_score_db(database_path)
    end
    db = dbs[database_path]

    vote_event = as_vote_event_or_throw(IOBuffer(voteEvent))
    @info (
        "Got vote event $(vote_event.vote_event_id) on post:" *
        " $(vote_event.post_id) ($(vote_event.vote)) at $(Dates.format(now(), "HH:MM:SS"))"
    )

    results = IOBuffer()

    # The anonymous function provided here is used by the score_tree function to output
    # both `EffectEvent`s and `ScoreEvent`s. The `object` parameter is thus either a
    # ScoreEvent or an EffectEvent.
    n = 0
    successfully_processed = process_vote_event(db::SQLite.DB, vote_event) do object
        e = as_event(vote_event.vote_event_id, vote_event.vote_event_time, object)
        insert_event(db, e)
        json_data = JSON.json(e)
        write(results, json_data * "\n")
        n = n + 1
    end

    @debug "Produced $(n) score events $(vote_event.vote_event_id)"
    return String(take!(results))
end
