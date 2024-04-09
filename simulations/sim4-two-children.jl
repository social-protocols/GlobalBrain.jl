function votesGivenBeliefs(post_id, beliefs; skip_users=0)

    n = length(beliefs)
    users = collect(skip_users+1:skip_users+n)

    draws = [belief > 0.5 for belief in beliefs]

    return [
        SimulationVote(post_id, draw == 1 ? 1 : -1, i)
        for (i, draw) in zip(users, draws)
    ]

end


function two_children(sim::SimulationAPI)

    A = sim.post!(nothing, "A")

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
        votes = votesGivenBeliefs(A.post_id, repeat([p_a], n_users))
        scores = sim.step!(1, votes)

        p = scores[A.post_id].p

        @testset "Step 1: Initial beliefs ($p ≈ 0)" begin
            @test p ≈ 0 atol = 0.1
        end
    end


    # Step 2
    # First n_subset1 users vote on B
    n_subset1 = 30
    begin
        B = sim.post!(A.post_id, "B")
        votes_b = votesGivenBeliefs(B.post_id, repeat([posterior_b], n_subset1))
        # Then Change vote on A
        votes_a = votesGivenBeliefs(A.post_id, repeat([posterior_a], n_subset1))

        scores = sim.step!(2, [votes_a; votes_b])

        p = scores[A.post_id].p

        @testset "Step 2: B changes mind  ($p ≈ high)" begin
            # should approach 1 but given small sample size still be a bit below 
            @test p ≈ .95 atol = 0.1
        end
    end


    # Step 3
    # Second 50 users vote on C
    n_subset2 = 50
    begin
        p_C = 1
        C = sim.post!(A.post_id, "C")
        votes_c = votesGivenBeliefs(C.post_id, repeat([p_C], n_subset2); skip_users=n_subset1)

        # And change vote on A. But C didn't change minds
        votes_a = votesGivenBeliefs(A.post_id, repeat([p_a], n_subset2); skip_users=n_subset1)

        scores = sim.step!(3, [votes_a; votes_c])

        p = scores[A.post_id].p

        @testset "Step 2: C doesn't change minds ($p ≈ high)" begin
            # should approach 1 but given small sample size still be a bit below 
            @test p ≈ .95 atol = 0.1
        end
    end

end
