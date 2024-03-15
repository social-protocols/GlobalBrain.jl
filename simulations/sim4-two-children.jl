function voteGivenBeliefs(step_func, step, post, beliefs; skip_users=0)

    n = length(beliefs)
    users = collect(skip_users+1:skip_users+n)

    draws = [belief > 0.5 for belief in beliefs]

    votes = [
        SimulationVote(post.parent_id, post.post_id, draw == 1 ? 1 : -1, i)
        for (i, draw) in zip(users, draws)
    ]

    step_func(step, [post], votes)
end


function two_children(step_func::Function)

    A = SimulationPost(nothing, 7, "A")
    B = SimulationPost(A.post_id, 8, "B")
    C = SimulationPost(A.post_id, 9, "C")

    # common priors
    p_a_given_b = .9
    p_a_given_not_b = .01
    p_b = .5

    # Law of total probability
    p_a = p_b * p_a_given_b + (1 - p_b) * p_a_given_not_b

    posterior_b = 1
    posterior_a = p_a_given_b

    n_users = 100

    # Step 1: All users vote on A
    begin
        scores = voteGivenBeliefs(step_func, 1, A, repeat([p_a], n_users))

        p = scores[A.post_id].p

        @testset "Step 1: Initial beliefs ($p ≈ 0)" begin
            @test p ≈ 0 atol = 0.1
        end
    end


    # Step 2
    # First 10 users vote on B
    n_subset1 = 10
    begin
        voteGivenBeliefs(step_func, 2, B, repeat([posterior_b], n_subset1))
        # Then Change vote on A
        scores = voteGivenBeliefs(step_func, 2, A, repeat([posterior_a], n_subset1))

        p = scores[A.post_id].p

        @testset "Step 2: B changes mind  ($p ≈ high)" begin
            # should approach 1 but given small sample size still be a bit below 
            @test p ≈ .83 atol = 0.1
        end
    end


    # Step 3
    # Second 50 users vote on C
    n_subset2 = 50
    begin
        p_C = 1
        voteGivenBeliefs(step_func, 3, C, repeat([p_C], n_subset2); skip_users=n_subset1)

        # And change vote on A. But C didn't change minds
        scores = voteGivenBeliefs(step_func, 3, A, repeat([p_a], n_subset2); skip_users=n_subset1)

        p = scores[A.post_id].p

        @testset "Step 2: C doesn't change minds ($p ≈ high)" begin
            # should approach 1 but given small sample size still be a bit below 
            @test p ≈ .83 atol = 0.1
        end
    end

end
