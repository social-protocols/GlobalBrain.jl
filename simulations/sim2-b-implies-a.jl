# Scenario
# Users have common priors wrt a/b
# post: is a true
# all users answer no because p_a is just under 50%
# user U given true value of b
# user U posts note saying b is true

# all users trust user U
# minority of users consider U's note and thus form same posterior belief in B
# these users also change vote on A accordingly
# algorithm should estimate posterior_a close to true posterior_a

function b_implies_a(step_func::Function, db::SQLite.DB, tag_id::Int)
    # common priors
    p_a_given_b = .9
    p_a_given_not_b = .01
    p_b = .5

    # Law of total probability
    p_a = p_b * p_a_given_b + (1 - p_b) * p_a_given_not_b

    posterior_b = 1
    posterior_a = p_a_given_b

    n_users = 100

    root_post_id = 2
    note_id = 3

    draws_0 = [p_a > 0.5 ? true : false for i in 1:n_users]

    step_func(db, nothing, root_post_id, draws_0, 1; tag_id = tag_id)

    n_subset = 10
    draws_1 = [posterior_b > 0.5 ? true : false for i in 1:n_subset]
    draws_2 = [posterior_a > 0.5 ? true : false for i in 1:n_subset]

    step_func(db, root_post_id, note_id, draws_1, 2; tag_id = tag_id)
    step_func(db, nothing, root_post_id, draws_2, 3; tag_id = tag_id)

end


# run_simulation(db, tag_id=2) do process_votes

#     # common priors
#     p_a_given_b = .9
#     p_a_given_not_b = .01
#     p_b = .5

#     # Law of total probability
#     p_a = p_b * p_a_given_b + (1 - p_b) * p_a_given_not_b


#     posterior_b = 1
#     posterior_a = p_a_given_b

#     n_users = 100

#     root_post_id = 1
#     note_id = 2

#     draws_0 = [p_a > 0.5 ? true : false for i in 1:n_users]

#     process_votes(nothing, root_post_id, draws_0)

#     n_subset = 10
#     draws_1 = [posterior_b > 0.5 ? true : false for i in 1:n_subset]
#     draws_2 = [posterior_a > 0.5 ? true : false for i in 1:n_subset]

#     process_votes(root_post_id, note_id, draws_1)
#     process_votes(nothing, root_post_id, draws_2)

# end
