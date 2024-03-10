include("../src/simulations.jl")

run_simulation(tag_id=3) do process_votes

	post_id = 1
	n = 100

	supportersBeliefs = [.2,.4,.05]
	detractorsBeliefs = [.8,.95,.6]

	beliefs = [supportersBeliefs detractorsBeliefs]

	upvote_probability = beliefs * [n, n] / (2*n)
#	println("Overall prob: $upvote_probability")

	A = 1
	draws_A = rand.(Bernoulli.(beliefs[A,:]), n) 
	votes_A = hcat(draws_A...)[:]
	process_votes(nothing, A, votes_A)

	B = 2
	draws_B = rand.(Bernoulli.(beliefs[B,:]), n) 
	votes_B = hcat(draws_B...)[:]
    process_votes(A, B, repeat([true], n)) # everyone upvotes B for now
	process_votes(nothing, A, votes_B)

	C = 3
	draws_C = rand.(Bernoulli.(beliefs[C,:]), n) 
	votes_C = hcat(draws_C...)[:]
    process_votes(B, C, repeat([true], n)) # everyone upvotes C for now
	process_votes(nothing, A, votes_C)

end
