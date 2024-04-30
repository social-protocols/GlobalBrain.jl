# Scenario:
# -- post: "Did you draw a blue marble?"
# -- assumption: users vote honestly
# -- expectation: upvote probability converges on P(blue marble)

function marbles(sim::SimulationAPI)
    Random.seed!(3);
    # --------------------------------------------------------------------------
    # --- STEP 1 ---------------------------------------------------------------
    # --------------------------------------------------------------------------

    A = sim.post!(nothing, "Did you draw a blue marble?")
    n_users = 200
    p = 0.37
    draws = rand(Bernoulli(p), n_users)
    votes = [
        SimulationVote(A.post_id, d ? 1 : -1, i)
        for (i, d) in enumerate(draws)
    ]
    scores = sim.step!(1, votes; description="True probability of a blue marble is $p. All users answer honestly.")
    @testset "Marbles Step 1" begin
        @test scores[A.post_id].p ≈ 0.42 atol = 0.1
    end
end
