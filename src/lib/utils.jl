# TODO: Everything in here does not seem to be needed anymore -> determine whether we can delete this

"""
    magnitude(effect::Union{Effect, Nothing})::Float64

Calculate the magnitude of a `Effect`: the absolute difference between the
upvote probabilities given the comment was shown and not shown respectively. The
effect of `Nothing` is 0.0 by definition.

# Parameters

    * `effect::Union{Effect, Nothing}`: The effect to calculate the
    magnitude of.
"""
function magnitude(effect::Union{Effect,Nothing})::Float64
    return abs(effect.q - effect.p)
end

"""
    calc_comment_support(
        informed_probability::Float64,
        uninformed_probability::Float64
    )::Float64

Calculate the support for a comment given the upvote probabilities given the comment
was shown and not shown respectively.

# Parameters

    * `informed_probability::Float64`: The probability of an upvote given the
    comment was shown.
    * `uninformed_probability::Float64`: The probability of an upvote given the
    comment was not shown.
"""
function calc_comment_support(e::Effect)::Float64
    if e.p == e.q == 0.0
        return 0.0
    end
    return e.p / (e.p + e.q)
end



# TODO: not needed anymore?
function unpack(t::Tally)
    return (t.count, t.size)
end


# - The following commented code used to be in the effects.jl script which was now
# - merged with the score.jl script. We might not need this code anymore.
# --------------------------------------------------------------------------------

# # Use HMC simulation (NUTS sampling) to calculate the comment effect using the given hierarchical model
# function calc_comment_effect_hmc(model_function) 

#     stream = IOBuffer(UInt8[])
#     logger = Logging.SimpleLogger(Logging.Error)

#     println("Doing MCMC Sampling")
#     return (tally::DetailedTally) -> begin
#         model = model_function(tally.uninformed, tally.informed)

#         # Sample without any output
#         chain = Logging.with_logger(logger) do
#            MCMCChains.sample(model, NUTS(), 1000; progress=false)
#         end

#         uninformed_p = mean(chain[:q])
#         informed_p = mean(chain[:p])

#         return Effect(
#             post_id = tally.parent_id,
#             comment_id = tally.post_id,
#             uninformed_probability = uninformed_p,
#             informed_probability = informed_p,
#         )
#     end
# end



# # This model uses the mean of q as the mean of the prior for q. It does not incorporate the reversion parameter.
# @model function hierarchical_model1(uninformed_t::Tally, informed_t::Tally)
#     successes1, trials1 = unpack(uninformed_t)
#     successes2, trials2 = unpack(informed_t)

#     q ~ Beta(1, 1)
#     m = mean(q)
#     epsilon = 1e-4
#     p ~ Beta(max(m * C2, epsilon), max((1 - m) * C2, epsilon))

#     for i in 1:successes1
#         1 ~ Bernoulli(q)
#     end
#     for i in 1:(trials1 - successes1)
#         0 ~ Bernoulli(q)
#     end

#     for i in 1:successes2
#         1 ~ Bernoulli(p)
#     end
#     for i in 1:(trials2 - successes2)
#         0 ~ Bernoulli(p)
#     end
# end


# # This model adds the reversion parameter, which assumes an a priori regression to the mean. 
# @model function hierarchical_model2(uninformed_t::Tally, informed_t::Tally)
#     successes1, trials1 = unpack(uninformed_t)
#     successes2, trials2 = unpack(informed_t)

#     q ~ Beta(1, 1)
#     m = mean(q)
#     r ~ Beta(1,1)
#     informedPrior = mean(q) - r*(mean(q) - mean(m)) 
#     p ~ Beta(informedPrior * C, (1 - informedPrior) * C)

#     for i in 1:successes1
#         1 ~ Bernoulli(q)
#     end
#     for i in 1:(trials1 - successes1)
#         0 ~ Bernoulli(q)
#     end

#     for i in 1:successes2
#         1 ~ Bernoulli(p)
#     end
#     for i in 1:(trials2 - successes2)
#         0 ~ Bernoulli(p)
#     end
# end



# -- Following is a research note that was in the score.jl script. It should probably
# -- go into the wiki.
# -----------------------------------------------------------------------------------

# weight returns a score for determining the top comment for purposes of
# calculating the informed probability of the post. It is a measure of how
# much the *critical thread that starts with that comment* changes the probability of
# upvoting the post.
#
# ranking_score returns a score for determining how much attention a post
# should receive -- the value of a user considering that particular post.
#
# These are different values. To understand the difference, suppose we have
# posts A->B->C, P(A|not B, not C) = 10%, P(A|B, not C)=90%, and P(A|B,C) =
# 15%. So C mostly erases the effect of B on A. The effect of B is p=15%
# (fully informed), q=10%(uninformed), and r=90% (partially informed).
# 
# So B, without C, makes users *less* informed! If users only consider B and
# not C, their upvote probability is r=90%, which is further from the
# informed probability p=15% then where we started at q=10%. This means
# considering B and not C only increases cognitive dissonance.
#
# Cognitive dissonance before considering B: 
#
#    relative_entropy(p, q) = relative_entropy(.15, .10) = .0176
#
# Cognitive dissonance after considering B: 
#
#    relative_entropy(p, r) = relative_entropy(.15, .9) = 2.2366
#
# So for purposes of ranking, B has *negative* information value, because
# considering B without considering C actually makes users more uninformed!
# The information value of B (without C) is 
#
#   information_gain(p,r,q) 
#     = relative_entropy(p, q) - relative_entropy(p, r) 
#     = .0176 - 2.2366 
#     = -2.2189. 
#
# On the other hand, for purposes of calculating the informed probability of
# A, the most informed thread may be: A->B->C. The relative entropy for the
# thread is:
#
#    relative_entropy(p, q) = relative_entropy(.15, .1) = .0176
#
# So unless there are threads with higher scores, B might be the start of the
# most informative thread, even though B as a post has negative information
# value.
#
# We multiple weight by p_size as a heuristic to deal with duplicates.
# Suppose we have the same posts A->B->C. Before C is submitted, the informed
# probability of A will be close to 90%. However, C will reduce the this
# significantly to 15%.
# 
# At this point, a user could submit a near duplicate of B, B', and before
# somebody submitted a duplicate of comment C, C', B' would become the top comment
# and the informed probability of A will bounce back up to 90%. 
#
# Multiplying weight by p_size is a heuristic that kinds of deals with
# this. We give more weight to comments that have had more attention, and
# therefore have been exposed to more scrutiny and there is therefore a
# greater chance of users responding with a counter argument. So at first,
# even though B' has a high relative_entropy, it has a low score because its
# p_size is low. As its p_size increases, the probability that somebody
# responds with C' increases. 
#
# If people keep on submitting duplicates, users should start to notice and
# start downvoting the duplicates, so that they never receive enough
# attention to become the top comment and people don't have to respond to them.

# Code for generating above calculations:
# p = .15
# q = .1
# r = .9
# GlobalBrain.relative_entropy(p, q)
# GlobalBrain.relative_entropy(p, r)
# GlobalBrain.information_gain(p, q, r) 
# GlobalBrain.relative_entropy(p, q) - GlobalBrain.relative_entropy(p, r)


