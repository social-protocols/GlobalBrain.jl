(sim::SimulationAPI) -> begin
    # This test is broken, but not the previous, because C has more votes, and current scoring formula
    # gives more weight to posts with more votes. So it gives more weight to C, resulting in
    # an estimated informed probability close to p_a_given_c which is not close to p_a_given_b_and_c
    @testset "Duplicate: post with smaller effect has more votes" begin
        test_combined_effects(
            sim;
            p_a = 0.5,
            p_a_given_b = 0.9,
            p_a_given_c = 0.6,
            p_a_given_b_and_c = 0.9,
            broken = true,
        )
    end
end
