function counter_argument(step_func::Function)
    n_users = 100

    A = SimulationPost(nothing, 4, "A")
    B = SimulationPost(A.post_id, 5, "B")
    C = SimulationPost(B.post_id, 6, "C")

    beliefs = Dict(
        "supporters" => Dict(
            "A" => Bernoulli(0.2),
            "A|B" => Bernoulli(0.4),
            "A|B,C" => Bernoulli(0.05),
        ),
        "detractors" => Dict(
            "A" => Bernoulli(0.8),
            "A|B" => Bernoulli(0.95),
            "A|B,C" => Bernoulli(0.6),
        ),
    )

    # --------------------------------------------------------------------------
    # --- STEP 1 ---------------------------------------------------------------
    # --------------------------------------------------------------------------

    supporters_draws_A_step_1 = rand(
        beliefs["supporters"]["A"],
        trunc(Int, n_users / 2)
    )
    detractors_draws_A_step_1 = rand(
        beliefs["detractors"]["A"],
        trunc(Int, n_users / 2)
    )
    votes_A_step_1 = [
        v == 1 ?
            SimulationVote(nothing, A.post_id, 1, i) :
            SimulationVote(nothing, A.post_id, -1, i)
        for (i, v) in enumerate(
            [supporters_draws_A_step_1; detractors_draws_A_step_1]
        )
    ]
    step_func(db, 1, [A], votes_A_step_1; tag_id = tag_id)

    # --------------------------------------------------------------------------
    # --- STEP 2 ---------------------------------------------------------------
    # --------------------------------------------------------------------------

    votes_B_step_2 = [SimulationVote(A.post_id, B.post_id, 1, i) for i in 1:n_users]
    # everyone upvotes B for now
    step_func(db, 2, [B], votes_B_step_2; tag_id = tag_id)

    supporters_draws_A_step_2 = rand(
        beliefs["supporters"]["A|B"],
        trunc(Int, n_users / 2)
    )
    detractors_draws_A_step_2 = rand(
        beliefs["detractors"]["A|B"],
        trunc(Int, n_users / 2)
    )
    votes_A_step_2 = [
        v == 1 ?
            SimulationVote(nothing, A.post_id, 1, i) :
            SimulationVote(nothing, A.post_id, -1, i)
        for (i, v) in enumerate(
            [supporters_draws_A_step_2; detractors_draws_A_step_2]
        )
    ]
    step_func(db, 2, SimulationPost[], votes_A_step_2; tag_id = tag_id)

    # --------------------------------------------------------------------------
    # --- STEP 3 ---------------------------------------------------------------
    # --------------------------------------------------------------------------

    votes_C_step_3 = [
        SimulationVote(B.post_id, C.post_id, 1, i)
        for i in 1:n_users
    ]
    # everyone upvotes C for now
    step_func(db, 3, [C], votes_C_step_3,; tag_id = tag_id)

    supporters_draws_A_step_3 = rand(
        beliefs["supporters"]["A|B,C"],
        trunc(Int, n_users / 2)
    )
    detractors_draws_A_step_3 = rand(
        beliefs["detractors"]["A|B,C"],
        trunc(Int, n_users / 2)
    )
    votes_A_step_3 = [
        v == 1 ?
            SimulationVote(nothing, A.post_id, 1, i) :
            SimulationVote(nothing, A.post_id, -1, i)
        for (i, v) in enumerate([supporters_draws_A_step_3; detractors_draws_A_step_3])
    ]
    step_func(db, 3, SimulationPost[], votes_A_step_3,; tag_id = tag_id)
end
