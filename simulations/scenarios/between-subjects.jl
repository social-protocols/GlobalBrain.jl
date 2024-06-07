(sim::SimulationAPI) -> begin

    A = sim.post!(nothing, "A")
    B = sim.post!(A.post_id, "B")

    n = 200
    uninformed_users = 1:(n/2)
    informed_users = (n/2+1):n

    # --------------------------------------------------------------------------
    # --- STEP 1 ---------------------------------------------------------------
    # --------------------------------------------------------------------------

    @testset "Within subject Step 1" begin
        votes = [SimulationVote(A.post_id, 1, i) for i in uninformed_users]
        scores, _ = sim.step!(1, votes; description = "100 users upvote A.")
        @test scores[A.post_id].p ≈ 1.0 atol = 0.1
    end

    # --------------------------------------------------------------------------
    # --- STEP 2 ---------------------------------------------------------------
    # --------------------------------------------------------------------------

    @testset "Within subject Step 2" begin
        votes = [SimulationVote(B.post_id, 1, i) for i in informed_users]

        scores, _ = sim.step!(2, votes; description = "100 new users upvote B.")

        @test scores[A.post_id].p ≈ 1.0 atol = 0.1
        @test scores[B.post_id].p ≈ 1.0 atol = 0.1
    end

    # --------------------------------------------------------------------------
    # --- STEP 3 ---------------------------------------------------------------
    # --------------------------------------------------------------------------

    @testset "Within subject Step 3" begin
        votes = [SimulationVote(A.post_id, -1, i) for i in informed_users]

        scores, effects =
            sim.step!(3, votes; description = "Users who upvoted B all downvote A.")

        @test effects[(A.post_id, B.post_id)].q ≈ 1.0 atol = 0.1
        @test scores[A.post_id].p ≈ 0.0 atol = 0.1
    end
end
