if isinteractive()
    include("src/GlobalBrainService.jl")
else
    include("../src/GlobalBrainService.jl")
end

# include("src/ScoreDB/ScoreDB.jl")

using Main.GlobalBrainService
using Random, Distributions, SQLite

database_path = "data/sim.db"

function reset_db(path::String = database_path)::SQLite.DB
    if isfile(path)
        rm(path)
    end
    return get_score_db(path)
end

# database_path = "data/sim.db"
# if isfile(database_path)
#     println("delete db? (y/n)")
#     are_you_sure = readline()
#     if are_you_sure == "y"
#         rm(database_path)
#     else
#         error("okay")
#     end
# end
# db = get_score_db(database_path)


# Scenario
# post: "Did you draw a blue marble?"
# users vote honestly.

tag_id = 1
# post_id = 1


# n = 1000
# p = 0.37  # Set the probability parameter for the Bernoulli distribution
# draws = rand(Bernoulli(p), n)


function process_votes(db, draws::Vector{Bool}, post_id, parent_id, vote_event_id::Int = 1)
    t = 0

    scores = []

    for (i, draw) in enumerate(draws)
        vote = draw == 1 ? 1 : -1

        vote_event = GlobalBrainService.VoteEvent(
            id=vote_event_id,
            user_id=string(i),
            tag_id=tag_id,
            parent_id=parent_id,
            post_id=post_id,
            note_id=nothing,
            vote=vote,
            created_at=t
        )
        GlobalBrainService.process_vote_event(db, vote_event) do score
            push!(scores, score)
        end
        vote_event_id += 1
    end
    return scores
end

# post_id = 1
# scores = process_votes(draws, post_id, nothing, 1)

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

n_users = 100

root_post_id = 1
note_id = 2

db = reset_db(database_path)
draws_0 = [p_a > 0.5 ? true : false for i in 1:n_users]

scores_0 = process_votes(db, draws_0, root_post_id, nothing)

n_subset = 10
draws_1 = [posterior_b > 0.5 ? true : false for i in 1:n_subset]
draws_2 = [posterior_a > 0.5 ? true : false for i in 1:n_subset]

scores_1 = process_votes(db, draws_1, note_id, root_post_id, scores_0[end].vote_event_id + 1)
scores_2 = process_votes(db, draws_2, root_post_id, nothing, scores_1[end].vote_event_id + 1)

close(db)




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

















	
