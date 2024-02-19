module ScheduledScoring

using GlobalBrain
using CSV
using SQLite
using DataFrames
using Dates
using FileWatching
using Base: run

# include("src/types.jl")
include("src/scoredb.jl")
include("src/voteevents.jl")

function julia_main()::Cint
    @info "Starting scheduled scorer..."

    vote_database_filename = ARGS[1]
    vote_events_filename = ARGS[2]

    if length(vote_database_filename) == 0
        error("Missing vote database filename argument")
    end

    if length(vote_events_filename) == 0
        error("Missing vote events filename")
    end

    if !isfile(vote_database_filename)
        run(pipeline(`cat sql/tables.sql`, `sqlite3 $vote_database_filename`))
        run(pipeline(`cat sql/views.sql`, `sqlite3 $vote_database_filename`))
        run(pipeline(`cat sql/triggers.sql`, `sqlite3 $vote_database_filename`))
    end

    input_stream = open(vote_events_filename)
    process_vote_events_stream(get_score_db(vote_database_filename), input_stream)

    return 0
end


end