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

include("../src/simulations.jl")
# include("src/simulations.jl")




run_simulation(tag_id=4) do process_votes

    function voteGivenBeliefs(post, beliefs; start_user=0)
        votes = [belief > 0.5 for belief in beliefs]

        process_votes(parents[post], post, votes; start_user=start_user)

    end


    # common priors
    p_a_given_b = .9
    p_a_given_not_b = .01
    p_b = .5

    # Law of total probability
    p_a = p_b * p_a_given_b + (1 - p_b) * p_a_given_not_b

    posterior_b = 1
    posterior_a = p_a_given_b

    n_users = 100

    parents = Dict()
    A = 1
    parents[A] = nothing
    B = 2
    parents[B] = A
    C = 3
    parents[C] = A


    voteGivenBeliefs(A, repeat([p_a], n_users))
    # Initial vote on A


    # First 10 users vote on B
    n_subset = 10
    voteGivenBeliefs(B, repeat([posterior_b], n_subset))
    # Change vote on A
    voteGivenBeliefs(A, repeat([posterior_a], n_subset))

    # Second 10 users vote on C
    p_C = 1
    voteGivenBeliefs(C, repeat([p_C], n_subset); start_user=n_subset)
    # And change vote on A. But C didn't change minds
    voteGivenBeliefs(A, repeat([p_a], n_subset); start_user=n_subset)



end
