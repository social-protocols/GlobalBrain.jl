(sim::SimulationAPI) -> begin

    A = sim.post!(nothing, "A")
    B = sim.post!(A.post_id, "B")
    C = sim.post!(B.post_id, "C")

    user1 = 0
    user2 = 1

    @testset "Step 1: First user upvotes A" begin
        votes = [
            SimulationVote(A.post_id, 1, user1)
        ]
        scores, _ = sim.step!(1, votes; description="First user posts A with an upvote. Posterior ≈ .85. This is consistent with historical upvote ratios on Reddit.")
        @test scores[A.post_id].p ≈ .85 atol = 0.1
    end

    @testset "Step 2: Second user downvotes A" begin
        votes = [
            SimulationVote(A.post_id, -1, user2)
        ]
        scores, _ = sim.step!(2, votes; description="Second user downvotes A. There is now one 1 upvote and 1 downvote. These votes have equal weight so p = .5")
        @test scores[A.post_id].p ≈ 0.50 atol = 0.01

    end

    description = "Second user posts reason."
    @testset "Step 3: Second user posts reason." begin
        votes = [
            SimulationVote(B.post_id, 1, user2)
        ]

        scores, effects = sim.step!(3, votes; description="Second user posts reason. Now their upvote has more weight, so p is slightly less than 0.5")

        @test scores[A.post_id].p ≈ .42 atol = 0.05
    end

    @testset "Step 4: First user posts counter-argument" begin
        votes = [
            SimulationVote(C.post_id, 1, user1)
        ]

        scores, effects = sim.step!(4, votes; description="First user posts counter-argument. Now their upvote has more weight. They didn't have to vote on B. So p is slightly more than 0.5")

        @test scores[A.post_id].p ≈ .58 atol = 0.05
    end

    @testset "Step 5: Second user downvotes C" begin
        votes = [
            SimulationVote(C.post_id, -1, user2)
        ]

        scores, effects = sim.step!(5, votes; description="Second user downvotes C. Both votes once again have equal weight. So p is = 0.5")

        @test scores[A.post_id].p ≈ .50 atol = 0.001
    end

end
