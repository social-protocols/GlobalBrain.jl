
include("src/ScoreDB/ScoreDB.jl")
include("src/GlobalBrainService.jl")

using Main.GlobalBrainService

database_path = "data/sim.db"
db = ScoreDB.get_score_db(database_path)


# Scenario
# post: "Did you draw a blue marble?"
# users vote honestly.

tag_id = 1
post_id = 1

using Random, Distributions

n = 10
p = 0.3  # Set the probability parameter for the Bernoulli distribution
draws = rand(Bernoulli(p), n)

t = 0
vote_event_id = 1

for (i, draw) in enumerate(draws)

	vote = draw == 1 ? 1 : -1

	vote_event = GlobalBrainService.VoteEvent(id=vote_event_id, user_id=string(i), tag_id=tag_id, parent_id=nothing, post_id=post_id, note_id=nothing, vote=vote, created_at=t)
	GlobalBrainService.process_vote_event(db, vote_event) do score
		println("Processed vote event: $score")
	end
end

# print score
# total_error = relative_entropy









	
