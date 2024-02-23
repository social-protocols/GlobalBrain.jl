
function process_vote_events_stream(db::SQLite.DB, input_stream, output_stream::IOStream)

    column_names = []

    firstLine = true

    last_processed_vote_event_id = get_last_processed_vote_event_id(db)
    @info "Last processed vote event: $last_processed_vote_event_id"

    for line in eachline(input_stream)
        if firstLine
            column_names = [String(s) for s in split(line, ',')]
            firstLine = false 
            continue
        end

        json = JSON.parse(IOBuffer(line))
        df = DataFrame(json)

        vote_event_id = df[1, :voteEventId]
        post_id = df[1, :postId]

        @info "Got vote event $vote_event_id on post: $post_id at $(Dates.format(now(), "HH:MM:SS"))"

        if vote_event_id <= last_processed_vote_event_id
            @info "Already processed vote event $vote_event_id"
            continue
        end

        results = SQLite.load!(df, db, "VoteEventImport"; on_conflict="REPLACE")

        output_score_changes(db,output_stream)

        @info """Processed new events at $(Dates.format(now(), "HH:MM:SS"))"""
    end

    close(db)
end

function output_score_changes(db::SQLite.DB, output_stream)
    tallies = get_tallies(db, nothing, nothing)

    if length(tallies) == 0
        @info "No updated tallies to process"
        return
    end

    scores = score_tree(
        tallies,  
        (score_data) -> begin
            timestamp = Dates.value(now())
            for s in score_data
                @info "Writing updated score data for post $(s.post_id): p=$(s.self_probability), effect=$(s.effect), topNoteEffect=$(s.effect)"

                r = as_score_data_record(s, timestamp)

                insert_score_data(db, r)

                json_data = JSON.json(r) 
                write(output_stream, json_data * "\n")
            end
            flush(output_stream)
        end
    )

    set_last_processed_vote_event_id(db)
end


