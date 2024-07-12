# The global prior upvote probability is Beta(.25, .25), or a beta distribution with mean 0.5 and weight 0.5. 
# See reasoning in: https://github.com/social-protocols/internal-wiki/blob/main/pages/research-notes/2024-06-03-choosing-priors.md#user-content-fnref-1-35b0437c85b2f65e7c3d7139bba82f66
const GLOBAL_PRIOR_UPVOTE_PROBABILITY_SAMPLE_SIZE = C1 = 0.50
const GLOBAL_PRIOR_UPVOTE_PROBABILITY_MEAN = 0.5
const GLOBAL_PRIOR_UPVOTE_PROBABILITY = BetaDistribution(
    GLOBAL_PRIOR_UPVOTE_PROBABILITY_MEAN,
    GLOBAL_PRIOR_UPVOTE_PROBABILITY_SAMPLE_SIZE,
)

# The global prior weight for the *informed* upvote probability is just a guess, based on
# the belief that the prior weight for the informed upvote probability should be higher than
# that for the uninformed upvote probability. A priori, arguments do not change minds.
const GLOBAL_PRIOR_INFORMED_UPVOTE_PROBABILITY_SAMPLE_SIZE = C2 = 5.0


function calc_uninformed_probability(
    prior::BetaDistribution,
    tally::ConditionalTally,
)::Number
    return prior |>
        (x -> reset_weight(x, GLOBAL_PRIOR_INFORMED_UPVOTE_PROBABILITY_SAMPLE_SIZE)) |>
        (x -> update(x, tally.uninformed)) |>
        (x -> x.mean)
end

function partially_informed_probability_dist(
    prior::BetaDistribution,
    tally::ConditionalTally,
)::BetaDistribution
    return prior |>
        (x -> reset_weight(x, GLOBAL_PRIOR_INFORMED_UPVOTE_PROBABILITY_SAMPLE_SIZE)) |>
        (x -> update(x, tally.informed))
end


function effect_score(effect::Effect)::Float64
    return information_gain(effect.p, effect.q, effect.r)
end

function direct_score(p)::Float64
    p * (1 + log2(p))
end

# The total ranking score for a post includes the direct score for
# the post itself, plus the value of its effects on other posts.
function ranking_score(effects::Vector{Effect}, p::Float64)::Float64
    return direct_score(p) + sum([effect_score(e) for e in effects])
end
