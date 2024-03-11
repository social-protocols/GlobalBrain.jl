module GlobalBrainService

using GlobalBrain
using JSON
using SQLite
using DataFrames
using Dates

include("ScoreDB/ScoreDB.jl")
using .ScoreDB

include("vote-events.jl")
include("main.jl")

export Score
export VoteEvent
export julia_main
export global_brain_service
export get_score_db
export process_vote_events_stream

include("simulations.jl")

export get_sim_db
export SimulationPost
export SimulationVote
export create_simulation_post!
export run_simulation!

end
