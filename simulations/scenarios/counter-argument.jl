(sim::SimulationAPI) -> begin
    Random.seed!(3)

    n_users = 200
    n_supporters = trunc(Int, n_users / 2)
    n_detractors = trunc(Int, n_users / 2)

    A = sim.post!(nothing, "A")

    beliefs = Dict(
        "A" => Dict("supporters" => Bernoulli(0.2), "detractors" => Bernoulli(0.8)),
        "A|B" => Dict("supporters" => Bernoulli(0.4), "detractors" => Bernoulli(0.95)),
        "A|B,C" =>
            Dict("supporters" => Bernoulli(0.05), "detractors" => Bernoulli(0.5)),
    )

    means = Dict(
        key =>
            (mean(beliefs[key]["supporters"]) + mean(beliefs[key]["detractors"])) / 2 for key in keys(beliefs)
    )

    # @info "Means: $means"
    # Means: Dict("A|B,C" => 0.275, "A" => 0.5, "A|B" => 0.675)

    # --------------------------------------------------------------------------
    # --- STEP 1 ---------------------------------------------------------------
    # --------------------------------------------------------------------------

    supporters_draws_A_step_1 = rand(beliefs["A"]["supporters"], n_supporters)
    detractors_draws_A_step_1 = rand(beliefs["A"]["detractors"], n_detractors)
    votes_A_step_1 = [
        SimulationVote(A.post_id, draw == 1 ? 1 : -1, i) for (i, draw) in
        enumerate([supporters_draws_A_step_1; detractors_draws_A_step_1])
    ]
    scores_step_1, _ = sim.step!(
        1,
        votes_A_step_1;
        description = "There are $n_users users. Initially $(means["A"]*100)% agree with A",
    )

    @testset "Step 1: Initial beliefs" begin
        @test scores_step_1[A.post_id].p ≈ means["A"] atol = 0.2
    end

    # --------------------------------------------------------------------------
    # --- STEP 2 ---------------------------------------------------------------
    # --------------------------------------------------------------------------

    begin
        B = sim.post!(A.post_id, "B")
        # m users from each group consider B
        m = 40

        supporters_who_considered_b = collect(1:m)
        dectractors_who_considered_b = collect(n_supporters+1:n_supporters+m)

        draws_B_step_2 = zip(
            [supporters_who_considered_b; dectractors_who_considered_b],
            [repeat([1], m); repeat([1], m)],
        )

        votes_B_step_2 = [
            SimulationVote(B.post_id, draw == 1 ? 1 : -1, i) for (i, draw) in draws_B_step_2
        ]

        supporters_draws_A_step_2 = rand(beliefs["A|B"]["supporters"], m)
        detractors_draws_A_step_2 = rand(beliefs["A|B"]["detractors"], m)

        draws_step_3 = zip(
            [supporters_who_considered_b; dectractors_who_considered_b],
            [supporters_draws_A_step_2; detractors_draws_A_step_2],
        )

        votes_A_step_2 = [
            SimulationVote(A.post_id, draw == 1 ? 1 : -1, i) for (i, draw) in draws_step_3
        ]

        scores_step_2, _ = sim.step!(
            2,
            [votes_A_step_2; votes_B_step_2];
            description = "Among the $m users that consider B, $(means["A|B"]*100)% agree with A.",
        )
        @testset "Step 2: After first argument (p=$(scores_step_2[A.post_id].p) ≈ $(means["A|B"]))" begin
            @test scores_step_2[A.post_id].p ≈ means["A|B"] atol = 0.1
            @test scores_step_2[A.post_id].score > scores_step_1[A.post_id].score # Score increased because probability increased
            @test scores_step_2[B.post_id].score > 1 # High score because it changed minds about A 
        end
    end

    # --------------------------------------------------------------------------
    # --- STEP 3 ---------------------------------------------------------------
    # --------------------------------------------------------------------------

    begin
        C = sim.post!(B.post_id, "C")
        # m users from each group consider C
        m = 20
        supporters_who_considered_c = collect(1:m)
        dectractors_who_considered_c = collect(n_supporters+1:n_supporters+m)

        draws_step_3 = zip(
            [supporters_who_considered_c; dectractors_who_considered_c],
            [repeat([1], m); repeat([1], m)],
        )

        votes_C_step_3 = [
            SimulationVote(C.post_id, draw == 1 ? 1 : -1, i) for (i, draw) in draws_step_3
        ]

        # sim.step!(3, votes_C_step_3,)


        supporters_draws_A_step_3 = rand(beliefs["A|B,C"]["supporters"], m)
        detractors_draws_A_step_3 = rand(beliefs["A|B,C"]["detractors"], m)

        draws_step_3 = zip(
            [supporters_who_considered_c; dectractors_who_considered_c],
            [supporters_draws_A_step_3; detractors_draws_A_step_3],
        )

        votes_A_step_3 = [
            SimulationVote(A.post_id, draw == 1 ? 1 : -1, i) for (i, draw) in draws_step_3
        ]

        scores_step_3, _ = sim.step!(
            3,
            [votes_A_step_3; votes_C_step_3];
            description = "Among the $m users that also consider counter-argument C, agreement with A falls to $(round(means["A|B,C"]*100,digits=2))%.",
        )
        @testset "Step 3: After counter argument" begin
            @test scores_step_3[A.post_id].p ≈ means["A|B,C"] atol = 0.2
            @test scores_step_3[A.post_id].score < scores_step_2[A.post_id].score
            @test scores_step_3[B.post_id].score < 1
            # direct score = 1
            # indirect score < 1 (because B moves users in the wrong direction )
            @test scores_step_3[C.post_id].score > 1 # High score because it changed minds about A given B
        end
    end
end
