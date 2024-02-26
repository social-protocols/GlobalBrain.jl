module GlobalBrainService

using GlobalBrain
using JSON
using SQLite
using DataFrames
using Dates
# using FileWatching
using Base: run

include("ScoreDB/ScoreDB.jl")

using .ScoreDB

include("vote-events.jl")

function julia_main()::Cint
    @info "Starting scheduled scorer..."

    database_path = ARGS[1]
    vote_events_path = ARGS[2]
    score_events_path = ARGS[3]

    global_brain_service(database_path, vote_events_path, score_events_path)
end

function global_brain_service(database_path::String, vote_events_path::String, score_events_path::String)

    if length(database_path) == 0
        error("Missing vote database filename argument")
    end

    if length(vote_events_path) == 0
        error("Missing vote events filename argument")
    end


    @info "Reading vote events from $vote_events_path"

    input_stream = if vote_events_path == "-"
        stdin
    else
        open(vote_events_path, "r")
    end

    open(score_events_path, "a") do output_stream
        process_vote_events_stream(get_score_db(database_path), input_stream, output_stream)
    end

    return 0
end

export Score
export VoteEvent
export global_brain_service
export julia_main
export get_score_db
export process_vote_events_stream

end
