
# include("src/ScoreDB/ScoreDB.jl")
# include("src/GlobalBrainService.jl")

using GlobalBrainService

database_path = "data/sim.db"
db = ScoreDB.get_score_db(database_path)

t = 0
vote_event_id = 1

vote_event = GlobalBrainService.VoteEvent(id=vote_event_id, userid="100", tag_id=1, parent_id=nothing, post_id=1, note_id=nothing, vote=-1, created_at=t)

GlobalBrainService.process_vote_event(db, vote_event) do score
	println("Processed vote event: $score")
end


	
