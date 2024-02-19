

function process_vote_events_stream(db::SQLite.DB, input_stream::IOStream)

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

            csv = CSV.File(IOBuffer(line); header=column_names)
            df = DataFrame(csv)

            vote_event_id = df[1, :voteEventId]
            post_id = df[1, :postId]

            @info "Got vote event $vote_event_id on post: $post_id"

            if vote_event_id <= last_processed_vote_event_id
                @info "Already processed vote event $vote_event_id"
                continue
            end

            # println("Inserting vote events", df)
            results = SQLite.load!(df, db, "VoteEventImport")

            @info "Updating scores"

            calculate_score_changes(db)

            @info "Press enter to process next event"
            readline() # For debugging

        # catch e
            # @error "Error processing vote event: $e. At $now."
        # end

        @info "Processed new events at ", Dates.format(now(), "HH:MM:SS")
    end

    close(db)
end

function calculate_score_changes(db::SQLite.DB)
    tallies = get_tallies(db, nothing, nothing)

    if length(tallies) == 0
        @info "No updated tallies to process"
        return
    end

    scores = score_tree(
        tallies,  
        (score_data) -> begin
            for s in score_data
                @info "Writing updated score data for post $(s.post_id)"
                insert_score_data(db, s)
            end
        end
    )

    set_last_processed_vote_event_id(db)
end


