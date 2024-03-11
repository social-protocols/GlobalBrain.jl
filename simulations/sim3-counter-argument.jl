function counter_argument(step_func::Function, db::SQLite.DB, tag_id::Int)
    A = 1
    B = 2
    C = 3
    n = 100

    supportersBeliefs = [.2, .4, .05]
    detractorsBeliefs = [.8, .95, .6]

    beliefs = [supportersBeliefs detractorsBeliefs]

    # upvote_probability = beliefs * [n, n] / (2*n)

    draws_A = rand.(Bernoulli.(beliefs[A,:]), n)
    votes_A = hcat(draws_A...)[:]
    step_func(db, nothing, A, votes_A, 1; tag_id = tag_id)

    draws_B = rand.(Bernoulli.(beliefs[B,:]), n)
    votes_B = hcat(draws_B...)[:]
    step_func(db, A, B, repeat([true], n), 2; tag_id = tag_id) # everyone upvotes B for now
    step_func(db, nothing, A, votes_B, 2; tag_id = tag_id)

    draws_C = rand.(Bernoulli.(beliefs[C,:]), n)
    votes_C = hcat(draws_C...)[:]
    step_func(db, B, C, repeat([true], n), 3; tag_id = tag_id) # everyone upvotes C for now
    step_func(db, nothing, A, votes_C, 3; tag_id = tag_id)
end
