(sim::SimulationAPI) -> begin

    A = sim.post!(nothing, "A")

    n1 = 3
    n2 = 3
    n_overlap = 2
    pro = 1:n1
    con = n1+1:(n1+n2)
    overlap = n1-n_overlap:(n1+n_overlap)
    p_a = n1 / (n1 + n2)

    # Step 1
    begin

        votes1 = [SimulationVote(A.post_id, 1, i) for i in pro]
        votes2 = [SimulationVote(A.post_id, -1, i) for i in con]

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


    B1 = sim.post!(A.post_id, "B1")
    B2 = sim.post!(A.post_id, "B2")


    # Step 2
    begin
        votes1 = [SimulationVote(B1.post_id, 1, i) for i in pro]
        votes2 = [SimulationVote(B2.post_id, 1, i) for i in con]

        scores, _ = sim.step!(
            2,
            [votes1; votes2],
            description = "Users on each side post an argument for their side, which they all upvote.",
        )

        p = scores[A.post_id].p

        @testset "Step 2: Arguments on each side" begin
            @test p ≈ p_a atol = 0.1
        end
    end

    # Step 3
    begin
        votes = [SimulationVote(B2.post_id, 1, i) for i in overlap]

        scores, _ = sim.step!(
            3,
            votes,
            description = "$n_overlap users from pro side also vote on the argument from con side, but don't change their vote on A",
        )

        p = scores[A.post_id].p

        @testset "Step 3: Overlap group votes on argument from other side ($p between 0.5 but less than 1)" begin
            @test (p > 0.5)
            @test (p < 1.0)
        end
    end

end
