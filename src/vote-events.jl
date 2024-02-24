struct VoteEvent
    id::Int
    user_id::String
    tag_id::Int
    parent_id::Union{Int, Nothing}
    post_id::Int
    note_id::Union{Int, Nothing}
    vote::Int
    created_at::Int
end

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
        if vote_event.id <= last_processed_vote_event_id
            @info "Already processed vote event $(vote_event.id)"
            continue
        end

        DBInterface.execute(
            db,
            """
                insert into VoteEventImport
                (
                      voteEventId
                    , userId
                    , tagId
                    , parentId
                    , postId
                    , noteId
                    , vote
                    , createdAt
                )
                values (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                vote_event.id,
                vote_event.user_id,
                vote_event.tag_id,
                vote_event.parent_id,
                vote_event.post_id,
                vote_event.note_id,
                vote_event.vote,
                vote_event.created_at
            )
        )

        output_score_changes(db, output_stream, vote_event.id, vote_event.created_at)
        @info """Processed new events at $(Dates.format(now(), "HH:MM:SS"))"""
    end

    close(db)
end

function output_score_changes(db::SQLite.DB, output_stream, vote_event_id::Int, vote_event_time::Int)
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
                @info (
                    "Writing updated score data for post $(s.post_id):"
                        * " effect=$(s.effect),"
                        * " topNoteEffect=$(s.effect)"
                )
                r = as_score(s, vote_event_id, vote_event_time)
                println("Inserting score data $r")
                score_event_id = insert_score_event(db, r)

                json_data = JSON.json(with_score_event_id(r, score_event_id))
                write(output_stream, json_data * "\n")
            end
            flush(output_stream)
        end
    )
    set_last_processed_vote_event_id(db)

end
