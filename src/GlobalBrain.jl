module GlobalBrain

using JSON
using SQLite
using Dates
using Random
using Distributions

include("lib/models/probability-models.jl")
include("lib/models/evaluation.jl")
include("lib/models/tallies-data.jl")
include("lib/constants.jl")
include("lib/binary-entropy.jl")
include("lib/probabilities.jl")
include("lib/algorithm.jl")
include("lib/score.jl")
include("lib/note-effect.jl")
include("service/events.jl")
include("service/input-stream-api.jl")
include("service/vote-event-processing.jl")
include("service/main.jl")
include("db.jl")
include("simulations.jl")

# --- Service
export julia_main
export global_brain_service
export process_vote_events_stream

# --- Algorithm
export ConditionalTally
export TalliesData
export SQLTalliesData
export as_event
export Effect
export Score
export EffectEvent
export ScoreEvent
export VoteEvent
export score_tree
export score

# --- Database
export get_score_db
export init_score_db
export get_tallies
export insert_event
export insert_vote_event
export set_last_processed_vote_event_id
export get_last_processed_vote_event_id
export sql_row_to_detailed_tally
export sql_row_to_effect_event
export sql_row_to_score
export as_tallies_tree
export get_or_insert_tag_id

# --- Probability models
export Model
export BetaBernoulli
export GammaPoisson
export BernoulliTally
export PoissonTally
export Distribution
export BetaDistribution
export GammaDistribution
export alpha
export beta
export update
export bayesian_avg
export reset_weight
export sample
export unpack
export +
export -

# --- Binary entropy
export surprisal
export entropy
export cross_entropy
export relative_entropy
export information_gain

# --- Simulations
export get_sim_db
export SimulationPost
export SimulationVote
export create_simulation_post!
export run_simulation!

end
