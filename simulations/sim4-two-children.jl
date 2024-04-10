


function two_children(sim::SimulationAPI)

    A = sim.post!(nothing, "A")

    # common priors
    p_a_given_b = .9
    p_a_given_not_b = .01
    p_b = .5

    # Law of total probability
    p_a = p_b * p_a_given_b + (1 - p_b) * p_a_given_not_b

    p_a_given_c = p_a + (p_a_given_b-p_a)*.4

    posterior_b = 1
    posterior_a = p_a_given_b

    n_users = 160 

    # Step 1: All users vote on A
    begin

        votes = [
            SimulationVote(A.post_id, rand(Bernoulli(p_a)) == 1 ? 1 : -1, i)
            for i in 1:n_users
        ]

        # votes = votesGivenBeliefs(A.post_id, repeat([p_a], n_users))
        scores = sim.step!(1, votes, description="There are $n_users users. $(p_a*100)% agree with A.")

        p = scores[A.post_id].p

        @testset "Step 1: Initial beliefs ($p ≈ $p_a)" begin
            @test p ≈ p_a atol = 0.1
        end
    end


    # Step 2
    # First n_subset1 users vote on B
    n_subset1 = 40
    begin
        B = sim.post!(A.post_id, "B")
        # votes_b = votesGivenBeliefs(B.post_id, repeat([posterior_b], n_subset1))
        votes_b = [
            SimulationVote(B.post_id, rand(Bernoulli(posterior_b)) == 1 ? 1 : -1, i)
            for i in 1:n_subset1
        ]

        votes_a = [
            SimulationVote(A.post_id, rand(Bernoulli(posterior_a)) == 1 ? 1 : -1, i)
            for i in 1:n_subset1
        ]

        scores = sim.step!(2, [votes_a; votes_b], description="Of the $n_subset1 users that consider B, $(p_a_given_b*100)% agree with A.")

        p = scores[A.post_id].p

        @testset "Step 2: B changes mind  ($p ≈ $posterior_a)" begin
            # should approach 1 but given small sample size still be a bit below 
            @test p ≈ posterior_a atol = 0.1
        end
    end


    # Step 3
    # Second 50 users vote on C
    n_subset2 = 30
    begin
        p_C = 1
        C = sim.post!(A.post_id, "C")
        # votes_c = votesGivenBeliefs(C.post_id, repeat([p_C], n_subset2); skip_users=n_subset1)
        votes_c = [
            SimulationVote(C.post_id, rand(Bernoulli(p_C)) == 1 ? 1 : -1, i)
            for i in n_subset1+1:(n_subset1+n_subset2)
        ]

        # And change vote on A. But C didn't change minds
        # votes_a = votesGivenBeliefs(A.post_id, repeat([p_a_given_c], n_subset2); skip_users=n_subset1)
        votes_a = [
            SimulationVote(A.post_id, rand(Bernoulli(p_a_given_c)) == 1 ? 1 : -1, i)
            for i in n_subset1+1:(n_subset1+n_subset2)
        ]

        scores = sim.step!(3, [votes_a; votes_c]; description="Among a separate group of $n_subset2 users that consider C, $(round(p_a_given_c*100, digits=2))% agree with A. Since C has a smaller effect on A than does B, it does not become the critical response and does not effect the informed upvote probability estimate for A.")

        p1 = scores[A.post_id].p

        @testset "Step 2: C doesn't change minds ($p ≈ $p_a_given_c)" begin
            # should approach 1 but given small sample size still be a bit below 
            @test p1 ≈ p atol = 0.1
        end
    end

end
