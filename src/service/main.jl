function julia_main()::Cint
    @info "Starting Global Brain service..."

    database_path = ARGS[1]
    vote_events_path = ARGS[2]
    output_path = ARGS[3]

    global_brain_service(database_path, vote_events_path, output_path)
end

function global_brain_service(
    database_path::String,
    vote_events_path::String,
    output_path::String,
)
    if length(database_path) == 0
        error("Missing vote database filename argument")
    end
    if length(vote_events_path) == 0
        error("Missing vote events filename argument")
    end

    @info "Reading vote events from $vote_events_path"

    db = get_score_db(database_path)
    input_stream = vote_events_path == "-" ? stdin : open(vote_events_path, "r")

    output_stream = output_path == "-" ? stdout : open(output_path, "a")

    process_vote_events_stream(db, input_stream, output_stream)

    return 0
end
