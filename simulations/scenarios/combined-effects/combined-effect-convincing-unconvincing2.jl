(sim::SimulationAPI) -> begin
    @testset "One convincing, one unconvincing: convincing has more votes" begin
        test_combined_effects(
            sim;
            p_a = 0.5,
            p_a_given_b = 0.5,
            p_a_given_c = 0.9,
            p_a_given_b_and_c = 0.9,
            broken = false,
        )
    end
end
