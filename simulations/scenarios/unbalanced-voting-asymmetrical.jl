(sim::SimulationAPI) -> begin
    Random.seed!(3)

    A = sim.post!(nothing, "A")

    n1 = 3
    n2 = 3
    group1 = 1:n1
    group2 = n1+1:(n1+n2)
    p_a = n1 / (n1 + n2)

    # Step 1
    begin

        votes1 = [SimulationVote(A.post_id, 1, i) for i in group1]

        votes2 = [SimulationVote(A.post_id, -1, i) for i in group2]

        scores, _ = sim.step!(
            1,
            [votes1; votes2],
            description = "$n1 users agree with A and $n2 users disagree.",
        )

        p = scores[A.post_id].p

        @testset "Step 1: Initial beliefs ($p ≈ $p_a)" begin
            @test p ≈ p_a atol = 0.01
        end
    end


    # Step 2
    begin
        B = sim.post!(A.post_id, "B")
        votes_b = [SimulationVote(B.post_id, 1, i) for i in group2]

        scores, _ =
            sim.step!(2, votes_b, description = "Only users in group 2 vote on B")

        p = scores[A.post_id].p

        @testset "Step 2: Con group votes on argument" begin
            @test p ≈ p_a atol = 0.1 broken = true
        end
    end


end
