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


