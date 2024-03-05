include("../src/simulations.jl")
# process_votes = init_simulation(1)

# Scenario
# post: "Did you draw a blue marble?"
# users vote honestly.

df = run_simulation(tag_id=1) do process_votes

    # tag_id = 1
    post_id = 1

    n = 100
    p = 0.37  # Set the probability parameter for the Bernoulli distribution
    draws = rand(Bernoulli(p), n)

    # println("Running simulation 1", draws)
    process_votes(nothing, post_id, draws)

end


@testset "Expected results" begin
    # @test_throws AssertionError surprisal(0.0)
    # @test surprisal(0.25) == 2.0
    # @test surprisal(0.5) == 1.0
    # @test surprisal(0.75) ≈ 0.41 atol = 0.01
    # @test surprisal(1.0) == 0.0
    # @test_throws AssertionError surprisal(2.0)
    # @test_throws AssertionError surprisal(0.0, 3)
    @test  nrow(df) == 1
end













	
