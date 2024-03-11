module GlobalBrainService

using GlobalBrain
using JSON
using SQLite
using DataFrames
using Dates

include("ScoreDB/ScoreDB.jl")
using .ScoreDB

include("vote-events.jl")
include("simulations.jl")
include("main.jl")

export Score
export VoteEvent
export global_brain_service
export julia_main
export get_score_db
export process_vote_events_stream
export get_sim_db
export run_simulation!

end
