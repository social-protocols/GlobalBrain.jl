module ScoreDB

using GlobalBrain
using SQLite

include("types.jl")
include("converters.jl")
include("db.jl")

export SQLTalliesTree
export Score
export VoteEvent

export to_detailed_tally
export to_score_data
export as_score_event
export as_tallies_tree
export with_score_event_id

export get_score_db
export get_tallies

export insert_score_event
export set_last_processed_vote_event_id
export get_last_processed_vote_event_id


export insert_vote_event

end
