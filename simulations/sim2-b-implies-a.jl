# Scenario:
# ------------------------------------------------------------------------------
# assumption 1: Users have common priors wrt A/B
# assumption 2: Users vote honestly and trust that everyone votes honestly
# ------------------------------------------------------------------------------
# Post A: Is A true?
# Post B: A is true
# ------------------------------------------------------------------------------
# Step 1: - All users downvote A because p_a is just under 50%
# Step 2: - User U given true value of B
#         - User U posts note saying B is true
#         - Minority of users consider U's note and thus form same posterior
#           belief in B
# Step 3: - These users also change vote on A accordingly
# ------------------------------------------------------------------------------
# Expectation: Algorithm should estimate posterior_a close to true posterior_a

function b_implies_a(step_func::Function, db::SQLite.DB, tag_id::Int)
    root_post_id = 2
    note_id = 3
    A = SimulationPost(nothing, root_post_id, "Is A true?")
    B = SimulationPost(root_post_id, note_id, "A is true")

    # common priors
    p_a_given_b = 0.9
    p_a_given_not_b = 0.01
    p_b = 0.5

    # Law of total probability
    p_a = p_b * p_a_given_b + (1 - p_b) * p_a_given_not_b

    posterior_b = 1
    posterior_a = p_a_given_b

    n_users = 100

    # --------------------------------------------------------------------------
    # --- STEP 1 ---------------------------------------------------------------
    # --------------------------------------------------------------------------

    posts_0 = [A]
    votes_0 = [
        p_a > 0.5 ?
            SimulationVote(nothing, A.post_id, 1, i) :
            SimulationVote(nothing, A.post_id, -1, i)
        for i in 1:n_users
    ]
    scores = step_func(db, 1, posts_0, votes_0; tag_id = tag_id)
    @testset "B implies A: Step 1" begin
        @test scores[A.post_id].p ≈ 0.0 atol = 0.1
    end

    # --------------------------------------------------------------------------
    # --- STEP 2 ---------------------------------------------------------------
    # --------------------------------------------------------------------------

    n_subset = 10
    posts_1 = [B]
    votes_1 = [
        posterior_b > 0.5 ?
            SimulationVote(root_post_id, note_id, 1, i) :
            SimulationVote(root_post_id, note_id, -1, i)
        for i in 1:n_subset
    ]
    scores = step_func(db, 2, posts_1, votes_1; tag_id = tag_id)
    @testset "B implies A: Step 2" begin
        @test scores[B.post_id].p ≈ 1.0 atol = 0.1
    end

    # --------------------------------------------------------------------------
    # --- STEP 3 ---------------------------------------------------------------
    # --------------------------------------------------------------------------

    votes_2 = [
        posterior_a > 0.5 ?
            SimulationVote(nothing, root_post_id, 1, i) :
            SimulationVote(nothing, root_post_id, -1, i)
        for i in 1:n_subset
    ]
    scores = step_func(db, 3, SimulationPost[], votes_2; tag_id = tag_id)
    @testset "B implies A: Step 3" begin
        @test scores[A.post_id].p ≈ 0.9 atol = 0.1
    end
end
