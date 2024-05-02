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
        successfully_processed = process_vote_event(db::SQLite.DB, vote_event) do object
            e = as_event(vote_event.vote_event_id, vote_event.vote_event_time, object)
            insert_event(db, e)
            json_data = JSON.json(e)
            write(output_stream, json_data * "\n")
        end
        if !successfully_processed
            @info "Already processed vote event $(vote_event.vote_event_id)"
        else
            @info "Successfully processed vote event $(vote_event.vote_event_id)"
            flush(output_stream)
        end
    end

    close(db)
end


function process_vote_event(
    output_event::Function,
    db::SQLite.DB,
    vote_event::VoteEvent,
)::Bool
    last_processed_vote_event_id = get_last_processed_vote_event_id(db)
    if vote_event.vote_event_id <= last_processed_vote_event_id
        return false
    end

    insert_vote_event(db, vote_event)

    tallies_data = get_tallies_data(db, vote_event.tag_id, nothing)

    score_posts(output_event, tallies_data)

    set_last_processed_vote_event_id(db, vote_event.vote_event_id)

    return true
end


struct GlobalBrainResult
    scoreEvents::String
end

global dbs = Dict{String,SQLite.DB}()

function process_vote_event_json(database_path::String, voteEvent::String)
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
    return GlobalBrainResult(String(take!(results)))
end
