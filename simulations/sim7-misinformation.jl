function misinformation(sim::SimulationAPI)
    A = sim.post!(nothing, "[VIDEO] Shocking devastation from an airstrike in [war-torn country]")
    root_post_id = A.post_id

    n_users = 100

    # --------------------------------------------------------------------------
    # --- STEP 1 ---------------------------------------------------------------
    # --------------------------------------------------------------------------

    initial_upvote_probability = .95
    upvote_probability_given_b = .05
    begin
        
        votes = [
            SimulationVote(A.post_id, rand(Bernoulli(initial_upvote_probability)) == 1 ? 1 : -1, i)
            for i in 1:n_users
        ]

        scores = sim.step!(1, votes; description="Initially, the upvoteProbability on the video is $(initial_upvote_probability*100)%.")
        @testset "Misinformation: Step 1" begin
            @test scores[A.post_id].p ≈ .95 atol = 0.1
        end
    end

    # --------------------------------------------------------------------------
    # --- STEP 2 ---------------------------------------------------------------
    # --------------------------------------------------------------------------

    begin
        n_subset = 30
        B = sim.post!(root_post_id, "actual this is video from 10 years ago in another country. Here's the original source [link]")
        votes_B = [
            SimulationVote(B.post_id, 1, i)
            for i in 1:n_subset
        ]

        votes_A = [
            SimulationVote(A.post_id, rand(Bernoulli(upvote_probability_given_b)) == 1 ? 1 : -1, i)
            for i in 1:n_subset
        ]
        scores = sim.step!(2, [votes_A; votes_B]; description="But among users who saw the comment proving the video isn't what it claims to be, the upvoteProbability falls to $upvote_probability_given_b.")

        @testset "Misinformation: Step 2" begin
            @test scores[B.post_id].p ≈ .9 atol = 0.1
            @test scores[A.post_id].p ≈ .1 atol = 0.1
        end
    end
end
