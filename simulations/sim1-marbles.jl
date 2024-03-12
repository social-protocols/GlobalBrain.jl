# Scenario:
# -- post: "Did you draw a blue marble?"
# -- assumption: users vote honestly
# -- expectation: upvote probability converges on P(blue marble)

function marbles(step_func::Function, db::SQLite.DB, tag_id::Int)
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
    step_func(db, 1, posts, votes; tag_id = tag_id)
end
