function counter_argument(step_func::Function)
    n_users = 100
    n_supporters = trunc(Int, n_users/2)
    n_detractors = trunc(Int, n_users/2)

    A = SimulationPost(nothing, 4, "A")
    B = SimulationPost(A.post_id, 5, "B")
    C = SimulationPost(B.post_id, 6, "C")

    beliefs = Dict(
        "A" => Dict(
            "supporters" => Bernoulli(0.2),
            "detractors" => Bernoulli(0.8)
        ),
        "A|B" => Dict(
            "supporters" => Bernoulli(0.4),
            "detractors" => Bernoulli(0.95)
        ),
        "A|B,C" => Dict(
            "supporters" => Bernoulli(0.05),
            "detractors" => Bernoulli(0.5)
        )
    )

    means = Dict(
        key => ( mean(beliefs[key]["supporters"]) + mean(beliefs[key]["detractors"]) ) / 2
        for key in keys(beliefs)
    )


    # --------------------------------------------------------------------------
    # --- STEP 1 ---------------------------------------------------------------
    # --------------------------------------------------------------------------

    supporters_draws_A_step_1 = rand(
        beliefs["A"]["supporters"],
        n_supporters
    )
    detractors_draws_A_step_1 = rand(
        beliefs["A"]["detractors"],
        n_detractors
    )
    votes_A_step_1 = [
        SimulationVote(nothing, A.post_id, draw == 1 ? 1 : -1, i)
        for (i, draw) in enumerate(
            [supporters_draws_A_step_1; detractors_draws_A_step_1]
        )
    ]
    scores = step_func(1, [A], votes_A_step_1)

    @testset "Step 1: Initial beliefs" begin
        @test scores[A.post_id].p ≈ means["A"] atol = 0.2
    end

    # --------------------------------------------------------------------------
    # --- STEP 2 ---------------------------------------------------------------
    # --------------------------------------------------------------------------

    votes_B_step_2 = [SimulationVote(A.post_id, B.post_id, 1, i) for i in 1:n_users]
    # everyone upvotes B for now
    step_func(2, [B], votes_B_step_2)

    supporters_draws_A_step_2 = rand(
        beliefs["A|B"]["supporters"],
        n_supporters
    )
    detractors_draws_A_step_2 = rand(
        beliefs["A|B"]["detractors"],
        n_detractors
    )
    votes_A_step_2 = [
        SimulationVote(nothing, A.post_id, draw == 1 ? 1 : -1, i)
        for (i, draw) in enumerate(
            [supporters_draws_A_step_2; detractors_draws_A_step_2]
        )
    ]

    scores = step_func(2, SimulationPost[], votes_A_step_2)
    @testset "Step 2: After first argument" begin
        @test scores[A.post_id].p ≈ means["A|B"] atol = 0.1
    end

    # --------------------------------------------------------------------------
    # --- STEP 3 ---------------------------------------------------------------
    # --------------------------------------------------------------------------

    # m users from each group consider C
    m = 10
    supporters_who_considered_c = collect(1:m)
    dectractors_who_considered_c = collect(n_supporters+1:n_supporters+m)

    draws_step_3 = zip(
        [supporters_who_considered_c; dectractors_who_considered_c],
        [repeat([1], m); repeat([1], m)]
    )

    votes_C_step_3 = [
        SimulationVote(B.post_id, C.post_id, draw == 1 ? 1 : -1, i) 
        for (i, draw) in draws_step_3
    ]

    step_func(3, [C], votes_C_step_3,)


    supporters_draws_A_step_3 = rand(
        beliefs["A|B,C"]["supporters"],
        m
    )
    detractors_draws_A_step_3 = rand(
        beliefs["A|B,C"]["detractors"],
        m
    )

    draws_step_3 = zip(
        [supporters_who_considered_c; dectractors_who_considered_c],
        [supporters_draws_A_step_3; detractors_draws_A_step_3]
    )

    votes_A_step_3 = [
        SimulationVote(nothing, A.post_id, draw == 1 ? 1 : -1, i)
        for (i, draw) in draws_step_3
    ]


    scores = step_func(3, SimulationPost[], votes_A_step_3,)
    @testset "Step 3: After counter argument" begin
        @test scores[A.post_id].p ≈ means["A|B,C"] atol = 0.1
    end


end
