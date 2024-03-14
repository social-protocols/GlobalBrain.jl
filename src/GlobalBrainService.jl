module GlobalBrainService

using JSON
using SQLite
using DataFrames
using Dates

# include("GlobalBrain/GlobalBrain.jl")
# using .GlobalBrain

include("lib/types.jl")
include("lib/constants.jl")
include("lib/binary-entropy.jl")
include("lib/probabilities.jl")
include("lib/algorithm.jl")
include("lib/score.jl")
include("lib/note-effect.jl")

# Database
include("types.jl")
include("converters.jl")
include("db.jl")

# Service
include("vote-events.jl")
include("main.jl")

export Score
export VoteEvent
export julia_main
export global_brain_service
export get_score_db
export process_vote_events_stream


# Simulations
include("simulations.jl")
export get_sim_db
export SimulationPost
export SimulationVote
export create_simulation_post!
export run_simulation!

# Database
export SQLTalliesTree
export Score
export create_event
export VoteEvent

export to_detailed_tally
export as_tallies_tree

export get_score_db
export init_score_db
export get_tallies

export insert_event
export insert_event
export set_last_processed_vote_event_id
export get_last_processed_vote_event_id

export insert_vote_event



end
