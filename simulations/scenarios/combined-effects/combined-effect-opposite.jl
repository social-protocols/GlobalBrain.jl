(sim::SimulationAPI) -> begin
    @testset "Opposite Effects" begin
        test_combined_effects(
            sim;
            p_a = 0.5,
            p_a_given_b = 0.9,
            p_a_given_c = 0.1,
            p_a_given_b_and_c = 0.6,
            broken = true,
        )
    end
end
