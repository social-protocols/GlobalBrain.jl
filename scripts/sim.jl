include("../src/GlobalBrainService.jl")

# include("src/ScoreDB/ScoreDB.jl")
# include("src/GlobalBrainService.jl")

using Main.GlobalBrainService
using Random, Distributions

database_path = "data/sim.db"
if isfile(database_path)
    println("delete db? (y/n)")
    are_you_sure = readline()
    if are_you_sure == "y"
        rm(database_path)
    else
        error("okay")
    end
end
db = get_score_db(database_path)


# Scenario
# post: "Did you draw a blue marble?"
# users vote honestly.

tag_id = 1
post_id = 1


n = 1000
p = 0.37  # Set the probability parameter for the Bernoulli distribution
draws = rand(Bernoulli(p), n)

t = 0
vote_event_id = 1

for (i, draw) in enumerate(draws)
    vote = draw == 1 ? 1 : -1

    vote_event = GlobalBrainService.VoteEvent(id=vote_event_id, user_id=string(i), tag_id=tag_id, parent_id=nothing, post_id=post_id, note_id=nothing, vote=vote, created_at=t)
    GlobalBrainService.process_vote_event(db, vote_event) do score
        println("Processed vote event: $score")
    end
    global vote_event_id += 1
end

# print score
# total_error = relative_entropy


# common priors
p_a_given_b = .9
p_a_given_not_b = .01
p_b = .5

# Law of total probability
p_a = p_b * p_a_given_b + (1 - p_b) * p_a_given_not_b


posterior_b = 1
posterior_a = p_a_given_b

# Scenario
# Users have common priors wrt a/b
# post: is a true
# all users answer no because p_a is just under 50%
# user U given true value of b
# user U posts note saying b is true

# all users trust user U
# minority of users consider U's note and thus form same posterior belief in B
# these users also change vote on A accordingly
# algorithm should estimate posterior_a close to true posterior_a















	
