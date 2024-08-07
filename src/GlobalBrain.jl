module GlobalBrain

using JSON
using SQLite
using Dates
using Random

include("lib/models/information.jl")
include("lib/models/probability.jl")
include("lib/models/data-model.jl")

include("lib/algorithm.jl")

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
export replay_vote_event

export VoteEvent
export EffectEvent
export ScoreEvent
export as_event
export parse_vote_event

# --- Algorithm

export score_tree_and_emit_events

# --- Lib

export SQLTalliesData
export TalliesTree
export ConditionalTally
export Effect
export Score

export surprisal
export entropy
export cross_entropy
export relative_entropy
export information_gain

export Model
export BetaBernoulli
export GammaPoisson
export Tally
export Distribution
export BernoulliTally
export BetaDistribution
export alpha
export beta
export PoissonTally
export GammaDistribution
export update
export bayesian_avg
export reset_weight
export +
export -

# --- Database

export init_score_db
export get_score_db
export create_schema

export get_root_tallies_tree
export get_child_tallies_trees
export get_conditional_tally
export get_effect
export insert_score_event
export insert_effect_event
export insert_event
export get_last_vote_event_id
export insert_vote_event
export get_effects_for_vote_event
export get_scores_for_vote_event
export get_vote_event

export collect_results
export sql_row_to_effect
export sql_row_to_score
export sql_row_to_vote_event

end
