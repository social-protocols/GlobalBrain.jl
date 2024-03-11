module ScoreDB

using GlobalBrain
using SQLite

include("types.jl")
include("converters.jl")
include("db.jl")

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
