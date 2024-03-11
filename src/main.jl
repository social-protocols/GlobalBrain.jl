function julia_main()::Cint
    @info "Starting scheduled scorer..."

    database_path = ARGS[1]
    vote_events_path = ARGS[2]
    output_path = ARGS[3]

    global_brain_service(database_path, vote_events_path, output_path)
end

function global_brain_service(database_path::String, vote_events_path::String, output_path::String)

    if length(database_path) == 0
        error("Missing vote database filename argument")
    end

    if length(vote_events_path) == 0
        error("Missing vote events filename argument")
    end

    @info "Reading vote events from $vote_events_path"

    db = get_score_db(database_path)

    input_stream = if vote_events_path == "-"
        stdin
    else
        open(vote_events_path, "r")
    end

    open(output_path, "a") do output_stream
        process_vote_events_stream(db, input_stream, output_stream)
    end

    return 0
end
