
"""
Argument Tree: 
	A: OJ Simpson Killed his wife 
		B: A bloody glove found at the crime scene matched a glove found at Simpson's home
			C: In a dramatic courtroom moment, Simpson tried on the bloody gloves, and they appeared too tight, leading to Johnnie Cochran's famous line, "If it doesn't fit, you must acquit."
				D: Prosecutors argued that the gloves had shrunk from being soaked in blood and later exposed to moisture during the investigation.


There are two groups:
	- Supporters: People that liked OJ a priori
	- Detractors: People that disliked him a priori

They come into the trail with prior beliefs based on what they heard on the news:
	
	All most people know is somebody killed OJ's wife and there was a big police chase.

	Supporters:
		 - The low-speed chase in the white Bronco is enough for them to suspect he might have done it, but they are sure there is some good explanation.
		- P(A|Supporters) = .2

	Detractors:
		- They don't like OJ, and they know that the husband is usually the killer, and he wouldn't have run from the police if he was innocent.
		- P(A|Detractors) = .8

The evidence B (the bloody gloves) effects them differently

	Supporters:
		- The bloody glove seems like hard evidence. It's starting to look like he really could have done it.
		- P(A|B,Supporters) = .4

	Detractors
		- Now they are pretty sure he's guilty.
		- P(A|B,Detractors) = .95

The counter-argument C effects them differently
	Supporters:
		This was the exculpatory evidence they were hoping for! Now it seems like he couldn't have done it.
		- P(A|B,C,Supporters) = .05

	Detractors
		Hmm, that is a good argument. Johnnie Cochran sure is convincing!  
		- P(A|B,C,Detractors) = .6


But the prosecutors still have an answer with D
	Supports:
		The glove shrunk? Nice try, I'm not buying it.
		- P(A|B,C,Supporters) = .06

	Detractors:
		Ahah! Yes that explains it. we knew he was guilty all along.
		- P(A|B,C,Supporters) = .8

Let's say there are 100 people in each group. Suppose they all vote after each piece of evidence.

"""

include("../src/simulations.jl")

run_simulation(tag_id=3) do process_votes

	post_id = 1
	n = 100

	supportersBeliefs = [.2,.4,.05,.06]
	detractorsBeliefs = [.8,.95,.6,.8]

	beliefs = [supportersBeliefs detractorsBeliefs]

	overallProb = beliefs * [n, n] / (2*n)

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
	process_votes(A, B, votes_C)

	# C = 3
	# draws_C = rand.(Bernoulli.(beliefs[C,:]), n) 
	# votes_C = hcat(draws_B...)[:]
    # process_votes(B, C, repeat([true], n)) # everyone upvotes C for now
	# process_votes(A, B, votes_C)




end


# draws_0_supporters = rand(Bernoulli(supportersBeliefs[1]), n)
# draws_0_detractors = rand(Bernoulli(detractorsBeliefs[1]), n)







