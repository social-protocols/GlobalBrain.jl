module GlobalBrainService

using GlobalBrain
using CSV
using JSON
using SQLite
using DataFrames
using Dates
using FileWatching
using Base: run

# include("src/types.jl")
include("scoredb.jl")
include("voteevents.jl")

function julia_main()::Cint
    @info "Starting scheduled scorer..."

    database_path = ARGS[1]
    vote_events_path = ARGS[2]

    scheduled_scorer(database_path, vote_events_path)
end


function scheduled_scorer(database_path::String, vote_events_path::String, score_events_path::String)


    if length(database_path) == 0
        error("Missing vote database filename argument")
    end

    if length(vote_events_path) == 0
        error("Missing vote events filename")
    end

    if !isfile(database_path)
        @info "Initializing database at $database_path"
        run(pipeline(`cat sql/tables.sql`, `sqlite3 $database_path`))
        run(pipeline(`cat sql/views.sql`, `sqlite3 $database_path`))
        run(pipeline(`cat sql/triggers.sql`, `sqlite3 $database_path`))
    end

    @info "Reading vote events from $vote_events_path"

    open(vote_events_path) do input_stream
        open(score_events_path, "a") do output_stream
            process_vote_events_stream(get_score_db(database_path), input_stream, output_stream)

        end
    end

    return 0
end

export ScoreDataRecord
export scheduled_scorer

end
