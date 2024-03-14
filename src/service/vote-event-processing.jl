function process_vote_events_stream(db::SQLite.DB, input_stream, output_stream)
    last_processed_vote_event_id = get_last_processed_vote_event_id(db)
    @info "Last processed vote event: $last_processed_vote_event_id"

    for line in eachline(input_stream)
        vote_event = as_vote_event_or_throw(IOBuffer(line))
        @info (
            "Got vote event $(vote_event.vote_event_id) on post:"
                * " $(vote_event.post_id) ($(vote_event.vote)) at $(Dates.format(now(), "HH:MM:SS"))"
        )

        # The anonymous function provided here is used by the score_tree function to output
        # both `EffectEvent`s and `ScoreEvent`s. The `object` parameter is thus either a
        # ScoreEvent or an EffectEvent.
        output_event = (vote_event_id::Int, vote_event_time::Int, object) -> begin
            e = as_event(vote_event_id, vote_event_time, object)
            insert_event(db, e)
            json_data = JSON.json(e)
            write(output_stream, json_data * "\n")
        end
        successfully_processed =
            process_vote_event(output_event::Function, db::SQLite.DB, vote_event)
        if !successfully_processed
            @info "Already processed vote event $(vote_event.vote_event_id)"
        else
            flush(output_stream)
        end
    end

    close(db)
end


function process_vote_event(
    output_event::Function,
    db::SQLite.DB,
    vote_event::VoteEvent
)::Bool
    last_processed_vote_event_id = get_last_processed_vote_event_id(db)
    if vote_event.vote_event_id <= last_processed_vote_event_id
        return false
    end

    insert_vote_event(db, vote_event)

    update_scores(db, last_processed_vote_event_id) do event
        output_event(vote_event.vote_event_id, vote_event.vote_event_time, event)
    end

    set_last_processed_vote_event_id(db, vote_event.vote_event_id)

    return true
end


function update_scores(output_event::Function, db::SQLite.DB, vote_event_id::Int)
    tallies = get_tallies(db, nothing, nothing, nothing)

    if length(tallies) == 0
        throw("No tallies found in the database: vote_event_id=$vote_event_id")
    end

    return score_tree(output_event, tallies)
end
