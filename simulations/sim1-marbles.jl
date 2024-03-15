# Scenario:
# -- post: "Did you draw a blue marble?"
# -- assumption: users vote honestly
# -- expectation: upvote probability converges on P(blue marble)

function marbles(step_func::Function)
    # --------------------------------------------------------------------------
    # --- STEP 1 ---------------------------------------------------------------
    # --------------------------------------------------------------------------

    A = SimulationPost(nothing, 1, "Did you draw a blue marble?")
    n_users = 100
    p = 0.37
    draws = rand(Bernoulli(p), n_users)
    posts = [A]
    votes = [
        SimulationVote(nothing, A.post_id, d ? 1 : -1, i)
        for (i, d) in enumerate(draws)
    ]
    scores = step_func(1, posts, votes)
    @testset "Marbles Step 1" begin
        @test scores[A.post_id].p ≈ 0.37 atol = 0.1
    end
end
