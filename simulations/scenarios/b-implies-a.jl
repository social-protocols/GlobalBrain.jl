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

(sim::SimulationAPI) -> begin

    A = sim.post!(nothing, "Is A true?")
    root_post_id = A.post_id

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

    begin
        posts_0 = [A]
        votes_0 = [
            p_a > 0.5 ? SimulationVote(root_post_id, 1, i) :
            SimulationVote(root_post_id, -1, i) for i = 1:n_users
        ]
        scores, _ = sim.step!(
            1,
            votes_0;
            description = "All users have common prior belief P(A)=$p_a. So everyone downvotes A. The estimated upvoteProbability quickly approaches zero.",
        )
        @testset "B implies A: Step 1" begin
            @test scores[root_post_id].p ≈ 0.0 atol = 0.1
        end
    end

    # --------------------------------------------------------------------------
    # --- STEP 2 ---------------------------------------------------------------
    # --------------------------------------------------------------------------

    n_subset = 20
    begin
        B = sim.post!(root_post_id, "A is true")
        comment_id = B.post_id
        posts_1 = [B]
        votes_1 = [
            posterior_b > 0.5 ? SimulationVote(comment_id, 1, i) :
            SimulationVote(comment_id, -1, i) for i = 1:n_subset
        ]

        votes_2 = [
            posterior_a > 0.5 ? SimulationVote(root_post_id, 1, i) :
            SimulationVote(root_post_id, -1, i) for i = 1:n_subset
        ]
        scores, _ = sim.step!(
            2,
            [votes_1; votes_2];
            description = "Someone posts B, and everyone who sees B agrees. Further, everyone has a common prior P(A|B)=$p_a_given_b, so users change their vote and upvote A. The estimated informed upvoteProbability quickly approaches 1.",
        )

        @testset "B implies A: Step 2" begin
            @test scores[comment_id].p ≈ 1.0 atol = 0.1

            p = scores[root_post_id].p
            @test scores[root_post_id].p ≈ 0.9 atol = 0.1

            @test scores[comment_id].score > 2.5 # very high score because it changed lots of minds
            @test (scores[root_post_id].score ≈ p * (1 + log2(p))) atol = 0.01
        end
    end
end
