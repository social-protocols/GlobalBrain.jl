function test_two_children(
    sim::SimulationAPI;
    p_a,
    p_a_given_b,
    p_a_given_c,
    p_a_given_b_and_c,
    broken = false,
)


    A = sim.post!(nothing, "A")


    group0 = 1:100
    # Group of users that vote only on B
    group1 = 101:150
    # Group of users that vote on both B and C
    group_overlap = 141:160
    # Group of users that vote only on C
    group2 = 151:300

    # Step 1: Group 0 only votes on A
    begin
        votes = [
            SimulationVote(A.post_id, rand(Bernoulli(p_a)) == 1 ? 1 : -1, i) for i in group0
        ]

        scores, _ = sim.step!(
            1,
            votes;
            description = "Among users that only consider A, $(p_a*100)% agree with A.",
        )

        p = scores[A.post_id].p

        @testset "Step 1: Initial beliefs ($p ≈ $p_a)" begin
            @test p ≈ p_a atol = 0.1
        end
    end

    # Step 2: Group 1 votes on A and B.
    begin
        B = sim.post!(A.post_id, "B")
        # votes_b = votesGivenBeliefs(B.post_id, repeat([posterior_b], n_group1))
        votes_b = [SimulationVote(B.post_id, 1, i) for i in group2]

        votes_a = [
            # SimulationVote(B.post_id, 1, i)
            SimulationVote(A.post_id, rand(Bernoulli(p_a_given_b)) == 1 ? 1 : -1, i) for
            i in group2
        ]

        all_votes = [votes_a; votes_b]

        scores, _ = sim.step!(
            2,
            all_votes;
            description = "Among users that consider B, $(p_a_given_b*100)% agree with A.",
        )

        p = scores[A.post_id].p

        @testset "Step 2: B changes minds ($p ≈ $p_a_given_b)" begin
            @test p ≈ p_a_given_b atol = 0.1
        end
    end


    # Step 3: Group 2 and the overlap group vote in A and C 
    begin
        C = sim.post!(A.post_id, "C")
        votes_c1 = [SimulationVote(C.post_id, 1, i) for i in group2]
        votes_c2 = [SimulationVote(C.post_id, 1, i) for i in group_overlap]

        votes_a_given_c = [
            SimulationVote(A.post_id, rand(Bernoulli(p_a_given_c)) == 1 ? 1 : -1, i) for
            i in group2
        ]

        votes_a_given_b_and_c = [
            SimulationVote(A.post_id, rand(Bernoulli(p_a_given_b_and_c)) == 1 ? 1 : -1, i) for i in group_overlap
        ]

        all_votes = [votes_c1; votes_c2; votes_a_given_c; votes_a_given_b_and_c]

        scores, _ = sim.step!(
            3,
            all_votes;
            description = "Among users who only consider C, $(round(p_a_given_c*100, digits=2))% agree with A. Among users who consider B and C, $(round(p_a_given_b_and_c*100, digits=2))% agree with A.",
        )

        p1 = scores[A.post_id].p

        @testset "Step 3: C changes minds. Some users voted on both ($p ≈ $p_a_given_b_and_c)" begin
            @test p1 ≈ p_a_given_b_and_c atol = 0.1 broken = broken
        end
    end
end


(sim::SimulationAPI) -> begin

    Random.seed!(3)

    @testset "Opposite Effects" begin
        test_two_children(
            sim;
            p_a = 0.5,
            p_a_given_b = 0.9,
            p_a_given_c = 0.1,
            p_a_given_b_and_c = 0.6,
            broken = true,
        )
    end

    @testset "Once post counteracts effect of another: counteracting post has more votes" begin
        test_two_children(
            sim;
            p_a = 0.5,
            p_a_given_b = 0.9,
            p_a_given_c = 0.5,
            p_a_given_b_and_c = 0.5,
            broken = false,
        )
    end

    # This test is broken, but not the previous, because C has more votes, and current scoring formula
    # gives more weight to posts with more votes. So it gives more weight to counteracted, resulting in 
    # an estimated informed probability close to p_a_given_c which is not close to p_a_given_b_and_c
    @testset "One post counteracts effect of another: counteracted post has more votes" begin
        test_two_children(
            sim;
            p_a = 0.5,
            p_a_given_b = 0.5,
            p_a_given_c = 0.9,
            p_a_given_b_and_c = 0.5,
            broken = true,
        )
    end

    @testset "Duplicate: post with larger effect has more votes" begin
        test_two_children(
            sim;
            p_a = 0.5,
            p_a_given_b = 0.6,
            p_a_given_c = 0.9,
            p_a_given_b_and_c = 0.9,
            broken = false,
        )
    end

    # This test is broken, but not the previous, because C has more votes, and current scoring formula
    # gives more weight to posts with more votes. So it gives more weight to C, resulting in
    # an estimated informed probability close to p_a_given_c which is not close to p_a_given_b_and_c
    @testset "Duplicate: post with smaller effect has more votes" begin
        test_two_children(
            sim;
            p_a = 0.5,
            p_a_given_b = 0.9,
            p_a_given_c = 0.6,
            p_a_given_b_and_c = 0.9,
            broken = true,
        )
    end

    # This test is broken, but shouldn't given scoring formula. The unconvincing post should have a very low relative
    # entropy, and so the score should be low even though it has lots of votes
    @testset "One convincing, one unconvincing: unconvincing has more votes" begin
        test_two_children(
            sim;
            p_a = 0.5,
            p_a_given_b = 0.9,
            p_a_given_c = 0.5,
            p_a_given_b_and_c = 0.9,
            broken = true,
        )
    end

    @testset "One convincing, one unconvincing: convincing has more votes" begin
        test_two_children(
            sim;
            p_a = 0.5,
            p_a_given_b = 0.5,
            p_a_given_c = 0.9,
            p_a_given_b_and_c = 0.9,
            broken = false,
        )
    end

end
