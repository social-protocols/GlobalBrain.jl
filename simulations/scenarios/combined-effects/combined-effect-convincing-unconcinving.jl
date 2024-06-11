(sim::SimulationAPI) -> begin
    # This test is broken, but shouldn't given scoring formula. The unconvincing post should have a very low relative
    # entropy, and so the score should be low even though it has lots of votes
    @testset "One convincing, one unconvincing: unconvincing has more votes" begin
        test_combined_effects(
            sim;
            p_a = 0.5,
            p_a_given_b = 0.9,
            p_a_given_c = 0.5,
            p_a_given_b_and_c = 0.9,
            broken = true,
        )
    end
end
