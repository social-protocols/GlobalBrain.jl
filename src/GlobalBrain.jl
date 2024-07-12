module GlobalBrain

using JSON
using SQLite
using Dates
using Random

include("lib/models/information.jl")
include("lib/models/probability.jl")
include("lib/models/data-model.jl")

include("lib/algorithm.jl")
include("lib/score.jl")
include("lib/effect.jl")

include("service/events.jl")
include("service/vote-event-processing.jl")
include("service/json-events.jl")

include("db/utils.jl")
include("db/schema.jl")
include("db/db.jl")

# --- Service
export process_vote_events_stream
export process_vote_event
export process_vote_event_json

# --- Algorithm
export ConditionalTally
export TalliesTree
export SQLTalliesData
export as_event
export Effect
export Score
export EffectEvent
export ScoreEvent
export VoteEvent
export score_posts
export score_post

# --- Database
export get_score_db
export init_score_db
export insert_event
export insert_vote_event
export set_last_processed_vote_event_id
export get_last_vote_event_id
export sql_row_to_detailed_tally
export sql_row_to_effect
export sql_row_to_score
export as_tallies_tree
export collect_results

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
export unpack
export +
export -

# --- Binary entropy
export surprisal
export entropy
export cross_entropy
export relative_entropy
export information_gain

end
