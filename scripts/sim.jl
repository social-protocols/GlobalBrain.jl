if isinteractive()
    include("src/GlobalBrainService.jl")
else
    include("../src/GlobalBrainService.jl")
end


using Main.GlobalBrainService
using Random, Distributions, SQLite

database_path = ENV["SIM_DATABASE_PATH"]

function reset_db(path::String = database_path)::SQLite.DB
    if isfile(path)
        rm(path)
    end
    return get_score_db(path)
end


reset_db(database_path)
db = get_score_db(database_path)


function process_votes(db, tag_id, parent_id, post_id, draws::Vector{Bool}, vote_event_id::Int = 1)
    t = 0

    # scores = []

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
            vote_event_id += 1
            # push!(scores, score)
        end
    end
    return vote_event_id
end


voteEventId = 0

begin
    tag_id = 1
    # Scenario
    # post: "Did you draw a blue marble?"
    # users vote honestly.

    post_id = 1


    n = 1000
    p = 0.37  # Set the probability parameter for the Bernoulli distribution
    draws = rand(Bernoulli(p), n)
    
    voteEventId = process_votes(db, tag_id, nothing, post_id, draws, voteEventId+1)
end

begin
    tag_id = 2
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

    draws_0 = [p_a > 0.5 ? true : false for i in 1:n_users]

    voteEventId = process_votes(db, tag_id, nothing, root_post_id, draws_0, voteEventId + 1)

    n_subset = 10
    draws_1 = [posterior_b > 0.5 ? true : false for i in 1:n_subset]
    draws_2 = [posterior_a > 0.5 ? true : false for i in 1:n_subset]

    voteEventId = process_votes(db, tag_id, root_post_id, note_id, draws_1, voteEventId + 1)
    voteEventId = process_votes(db, tag_id, nothing, root_post_id, draws_2, voteEventId + 1)

    # look at scores in score table
end


close(db)

















	
