include("../src/simulations.jl")
# process_votes = init_simulation(1)

# Scenario
# post: "Did you draw a blue marble?"
# users vote honestly.

run_simulation(tag_id=1) do process_votes

    # tag_id = 1
    post_id = 1

    n = 10
    p = 0.37  # Set the probability parameter for the Bernoulli distribution
    draws = rand(Bernoulli(p), n)

    # println("Running simulation 1", draws)
    process_votes(nothing, post_id, draws)
    # println("Done")

end














	
