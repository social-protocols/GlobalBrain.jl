# Scenario
# post: "Did you draw a blue marble?"
# users vote honestly.
post_id = 1

n = 1000
p = 0.37  # Set the probability parameter for the Bernoulli distribution
draws = rand(Bernoulli(p), n)

process_votes(tag_id, nothing, post_id, draws)
















	
