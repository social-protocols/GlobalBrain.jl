
function check_schema(input::Dict{String, Any})
    required_keys = Set(
        ["voteEventId", "userId", "tagId", "parentId", "postId", "noteId", "vote", "createdAt"]
    )
    if !issubset(required_keys, collect(keys(input)))
        error("Invalid JSON for VoteEvent: $input")
    end
end

function parse_vote_event(input::Dict{String, Any})::VoteEvent
    return VoteEvent(
        input["voteEventId"],
        input["userId"],
        input["tagId"],
        input["parentId"],
        input["postId"],
        input["noteId"],
        input["vote"],
        input["createdAt"],
    )
end

function process_vote_events_stream(db::SQLite.DB, input_stream, output_stream)
    last_processed_vote_event_id = get_last_processed_vote_event_id(db)
    @info "Last processed vote event: $last_processed_vote_event_id"

    for line in eachline(input_stream)
        json = JSON.parse(IOBuffer(line))
        try
            check_schema(json)
        catch
            @warn "Invalid JSON for VoteEvent: $line"
            continue
        end
        vote_event = parse_vote_event(json)
        @info (
            "Got vote event $(vote_event.id) on post:"
                * " $(vote_event.post_id) at $(Dates.format(now(), "HH:MM:SS"))"
        )

        processed = process_vote_event(db::SQLite.DB, vote_event) do score_event
            json_data = JSON.json(score_event)
            write(output_stream, json_data * "\n")
        end

        if !processed
            @info "Already processed vote event $(vote_event.id)"
        else
            flush(output_stream)
        end

        @info """Processed new events at $(Dates.format(now(), "HH:MM:SS"))"""
    end

    close(db)
end


function process_vote_event(output_score_event::Function, db::SQLite.DB, vote_event::VoteEvent)
    last_processed_vote_event_id = get_last_processed_vote_event_id(db)
    if vote_event.id <= last_processed_vote_event_id
        return false
    end

    insert_vote_event(db, vote_event)

    update_scores(
        db, 
        vote_event.id, 
        vote_event.created_at
    ) do score_event
        output_score_event(score_event)
    end

    last_processed_vote_event_id = vote_event.id
    set_last_processed_vote_event_id(db, vote_event.id)

    return true
end


function update_scores(output_score_event::Function, db::SQLite.DB, vote_event_id::Int, vote_event_time::Int)
    tallies = get_tallies(db, nothing, nothing)

    if length(tallies) == 0
        @info "No updated tallies to process"
        return
    end

    score_tree(
        tallies,  
        (score_data) -> begin
            timestamp = Dates.value(now())
            for s in score_data
                # @info (
                #     "Writing updated score data for post $(s.post_id):"
                #         * " effect=$(s.effect),"
                #         * " topNoteEffect=$(s.effect)"
                # )
                r = as_score_event(s, vote_event_id, vote_event_time)
                insert_score_event(db, r)
                output_score_event(r)
            end
        end
    )
end
