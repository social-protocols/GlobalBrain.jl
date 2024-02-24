module ScoreDB

using GlobalBrain
using SQLite
using Tables

include("types.jl")
include("converters.jl")
include("db.jl")

export SQLTalliesTree
export Score

export to_detailed_tally
export to_score_data
export as_score
export as_tallies_tree
export with_score_event_id

export get_score_db
export get_tallies

export insert_score_event
export set_last_processed_vote_event_id
export get_last_processed_vote_event_id

end
