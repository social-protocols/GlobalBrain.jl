"""
    magnitude(effect::Union{Effect, Nothing})::Float64

Calculate the magnitude of a `Effect`: the absolute difference between the
upvote probabilities given the note was shown and not shown respectively. The
effect of `Nothing` is 0.0 by definition.

# Parameters

    * `effect::Union{Effect, Nothing}`: The effect to calculate the
    magnitude of.
"""
function magnitude(effect::Union{Effect,Nothing})::Float64
    return abs(effect.q - effect.p)
end

"""
    calc_note_support(
        informed_probability::Float64,
        uninformed_probability::Float64
    )::Float64

Calculate the support for a note given the upvote probabilities given the note
was shown and not shown respectively.

# Parameters

    * `informed_probability::Float64`: The probability of an upvote given the
    note was shown.
    * `uninformed_probability::Float64`: The probability of an upvote given the
    note was not shown.
"""
function calc_note_support(e::Effect)::Float64
    if e.p == e.q == 0.0
        return 0.0
    end
    return e.p / (e.p + e.q)
end


function upvote_probabilities(prior::BetaDistribution, tally::ConditionalTally)
    return upvote_probabilities_bayesian_average(prior, tally)
end

# Global prior constants. These should be estimated periodically using a Monte-Carlo chain on the full data set. 
# But once estimated, then cay be treated as constants.
const GLOBAL_PRIOR_UPVOTE_PROBABILITY_SAMPLE_SIZE = C1 = 2.3
const GLOBAL_PRIOR_INFORMED_UPVOTE_PROBABILITY_SAMPLE_SIZE = C2 = 2.3
const GLOBAL_PRIOR_UPVOTE_PROBABILITY =
    BetaDistribution(0.875, GLOBAL_PRIOR_UPVOTE_PROBABILITY_SAMPLE_SIZE)

function upvote_probabilities_bayesian_average(
    prior::BetaDistribution,
    tally::ConditionalTally,
)
    q =
        prior |>
        (x -> reset_weight(x, GLOBAL_PRIOR_INFORMED_UPVOTE_PROBABILITY_SAMPLE_SIZE)) |>
        (x -> update(x, tally.uninformed)) |>
        (x -> x.mean)

    @debug "Uninformed probability for $post_id=>$note_id is $q $(prior.mean):($(tally.uninformed.count), $(tally.uninformed.size))"

    r =
        prior |>
        (x -> reset_weight(x, GLOBAL_PRIOR_INFORMED_UPVOTE_PROBABILITY_SAMPLE_SIZE)) |>
        (x -> update(x, tally.informed))

    @debug "Partially Informed probability for $post_id=>$note_id is $(r.mean) $(prior.mean):($(tally.informed.count), $(tally.informed.size))"

    return (q, r)
end

# # Use HMC simulation (NUTS sampling) to calculate the note effect using the given hierarchical model
# function calc_note_effect_hmc(model_function) 

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
#             note_id = tally.post_id,
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
