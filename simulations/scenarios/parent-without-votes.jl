(sim::SimulationAPI) -> begin
    Random.seed!(3)
    # --------------------------------------------------------------------------
    # --- STEP 1 ---------------------------------------------------------------
    # --------------------------------------------------------------------------

    A = sim.post!(nothing, "Parent without vote")
    B = sim.post!(A.post_id, "Child")
    votes = [SimulationVote(B.post_id, 1, 1)]

    @testset "Marbles Step 1" begin
        scores, _ = sim.step!(
            1,
            votes;
            description = "One user votes on a post, whose parent has no votes.",
        )
        @test haskey(scores, A.post_id)
        @test haskey(scores, B.post_id)
    end
end
