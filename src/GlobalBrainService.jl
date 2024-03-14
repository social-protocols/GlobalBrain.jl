module GlobalBrainService

using JSON
using SQLite
using DataFrames
using Dates

include("lib/models/probability-models.jl")
include("lib/models/evaluation.jl")
include("lib/models/discussion-trees.jl")

include("lib/constants.jl")
include("lib/binary-entropy.jl")
include("lib/probabilities.jl")
include("lib/algorithm.jl")
include("lib/score.jl")
include("lib/note-effect.jl")

include("service/events.jl")
include("service/vote-event-processing.jl")
include("service/main.jl")

include("db.jl")

include("simulations.jl")



export Score
export VoteEvent
export julia_main
export global_brain_service
export get_score_db
export process_vote_events_stream

export EffectEvent
export ScoreEvent

# Simulations
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

# GlobalBrain

export Model
export BetaBernoulli
export GammaPoisson
export DetailedTally
export BernoulliTally
export PoissonTally
export Distribution
export BetaDistribution
export GammaDistribution
export alpha
export beta

export Effect
export Score

export TalliesTree
export InMemoryTree

export update
export bayesian_avg
export reset_weight
export sample
export unpack
export +
export -

export surprisal
export entropy
export cross_entropy
export relative_entropy
export information_gain

export score_tree

export score

end
