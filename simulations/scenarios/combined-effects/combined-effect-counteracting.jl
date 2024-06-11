(sim::SimulationAPI) -> begin
    @testset "Once post counteracts effect of another: counteracting post has more votes" begin
        test_combined_effects(
            sim;
            p_a = 0.5,
            p_a_given_b = 0.9,
            p_a_given_c = 0.5,
            p_a_given_b_and_c = 0.5,
            broken = false,
        )
    end
end
