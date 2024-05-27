(sim::SimulationAPI) -> begin

    A = sim.post!(nothing, "A")
    B = sim.post!(A.post_id, "B")

    n = 100

    # --------------------------------------------------------------------------
    # --- STEP 1 ---------------------------------------------------------------
    # --------------------------------------------------------------------------

    @testset "Within subject Step 1" begin
        votes = [
            SimulationVote(A.post_id, 1, i)
            for i in 1:n
        ]
        scores, effects = sim.step!(1, votes; description="Everyone upvotes A.")
        @test scores[A.post_id].p ≈ 1.0 atol = 0.1
    end

    # --------------------------------------------------------------------------
    # --- STEP 2 ---------------------------------------------------------------
    # --------------------------------------------------------------------------

    @testset "Within subject Step 2" begin
        votes = [
                SimulationVote(B.post_id, 1, i)
                for i in 1:n
            ]

        scores, effects = sim.step!(2, votes; description="Everyone upvotes B.")

        @test scores[A.post_id].p ≈ 1.0 atol = 0.1
        @test scores[B.post_id].p ≈ 1.0 atol = 0.1
    end

    # --------------------------------------------------------------------------
    # --- STEP 3 ---------------------------------------------------------------
    # --------------------------------------------------------------------------
    
    @testset "Within subject Step 3" begin
        votes = [
                SimulationVote(A.post_id, -1, i)
                for i in 1:100
            ]

        scores, effects = sim.step!(3, votes; description="After voting on B, everyone downvotes A.")
    
        @test effects[(A.post_id, B.post_id)].q ≈ 1.0 atol = 0.1
        @test scores[A.post_id].p ≈ 0.0 atol = 0.1
    end
end
