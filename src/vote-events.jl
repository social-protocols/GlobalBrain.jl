
function check_schema(input::Dict{String, Any})
    required_keys = Set(
        ["vote_event_id", "user_id", "tag_id", "parent_id", "post_id", "note_id", "vote", "vote_event_time"]
    )
    if !issubset(required_keys, collect(keys(input)))
        error("Invalid JSON for VoteEvent: $input")
    end
end

function parse_vote_event(input::Dict{String, Any})::VoteEvent

    return VoteEvent(
        vote_event_id = input["vote_event_id"],
        vote_event_time = input["vote_event_time"],
        user_id = input["user_id"],
        tag_id = input["tag_id"],
        parent_id = input["parent_id"],
        post_id = input["post_id"],
        note_id = input["note_id"],
        vote = input["vote"],
    )
end

function process_vote_events_stream(db::SQLite.DB, input_stream, output_stream)
    last_processed_vote_event_id = get_last_processed_vote_event_id(db)
    @info "Last processed vote event: $last_processed_vote_event_id"




    for line in eachline(input_stream)
        json = JSON.parse(IOBuffer(line))

        check_schema(json)

        vote_event = parse_vote_event(json)
        @info (
            "Got vote event $(vote_event.vote_event_id) on post:"
                * " $(vote_event.post_id) at $(Dates.format(now(), "HH:MM:SS"))"
        )


        function emit_event(vote_event_id::Int, vote_event_time::Int, object)
        end

        processed = process_vote_event(db::SQLite.DB, vote_event) do vote_event_id::Int, vote_event_time::Int, object
            e = create_event(vote_event_id, vote_event_time, object)
            insert_event(db, e)

            json_data = JSON.json(e)
            write(output_stream, json_data * "\n")
        end

        if !processed
            @info "Already processed vote event $(vote_event.vote_event_id)"
        else
            flush(output_stream)
        end

        @info """Processed new events at $(Dates.format(now(), "HH:MM:SS"))"""
    end

    close(db)
end


function process_vote_event(output_event::Function, db::SQLite.DB, vote_event::VoteEvent)
    last_processed_vote_event_id = get_last_processed_vote_event_id(db)
    if vote_event.vote_event_id <= last_processed_vote_event_id
        return false
    end

    insert_vote_event(db, vote_event)

    update_scores(db) do event
        output_event(vote_event.vote_event_id, vote_event.vote_event_time, event)
    end

    last_processed_vote_event_id = vote_event.vote_event_id
    set_last_processed_vote_event_id(db, vote_event.vote_event_id)

    return true
end


function update_scores(output_event::Function, db::SQLite.DB)
    tallies = get_tallies(db, nothing, nothing, nothing)

    if length(tallies) == 0
        throw("No tallies found in the database: vote_event_id=$vote_event_id")
    end

    score_tree(
        output_event,
        tallies
    )
end
