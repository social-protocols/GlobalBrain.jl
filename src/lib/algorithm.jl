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


function score_posts(output_event::Function, posts::Vector{TalliesTree})
    effects = Dict{Int,Vector{Effect}}()
    for post in posts
        score_post(output_event, post, effects)
    end
end


function score_post(output_event::Function, post::TalliesTree, effects::Dict{Int,Vector{Effect}})
    post_id = post.post_id
    @debug "In score post $post_id"

    if !post.needs_recalculation
        @debug "No recalculation needed for $(post_id). Using existing score"
        return Vector{Score}()
    end

    o = GLOBAL_PRIOR_UPVOTE_PROBABILITY |> (x -> update(x, post.tally))
    @debug "Overall probability in score_post for $post_id is $(o.mean)"

    p = calc_informed_probability(post_id, post, o, effects)

    my_effects::Vector{Effect} = get(effects, post_id, [])
    for e in my_effects
        output_event(e)
    end

    for child in post.children()
        score_post(output_event, child, effects)
    end

    score = Score(
        post_id = post_id,
        o = o.mean,
        o_count = post.tally.count,
        o_size = post.tally.size,
        p = p,
        score = ranking_score(my_effects, p),
    )
    output_event(score)
end


function calc_informed_probability(
    post_id::Int,
    target::TalliesTree,
    r::BetaDistribution,
    effects::Dict{Int,Vector{Effect}},
)::Number
    comment_id = target.post_id

    @debug "weighted_average_informed_probability $post_id=>$(comment_id), r=$(r.mean)"

    children = target.children()
    @debug "Got $(length(children)) children for $comment_id"

    @debug "Getting effects of children of $comment_id on $post_id"
    child_effects =
        [calc_thread_effect(post_id, child, r, effects) for child in children] |>
        (x -> filter(effect -> effect.weight > 0, x))

    if length(child_effects) == 0
        return r.mean
    end

    return weighted_average_informed_probability(child_effects)
end


function calc_thread_effect(
    post_id::Int,
    target::TalliesTree,
    prior::BetaDistribution,
    effects::Dict{Int,Vector{Effect}},
)::Effect
    if !target.needs_recalculation
        return target.effect(post_id)
    end

    tally = target.conditional_tally(post_id)
    r_dist = partially_informed_probability_dist(prior, tally)

    effect = Effect(
        post_id = post_id,
        comment_id = target.post_id,
        p = calc_informed_probability(post_id, target, r_dist, effects),
        q = calc_uninformed_probability(prior, tally),
        r = r_dist.mean,
        conditional_tally = tally,
    )
    add!(effects, effect)

    @debug "p=$(effect.p) for $post_id=>$(target.post_id)"

    return effect
end


function weighted_average_informed_probability(child_effects::Vector{Effect})::Number
    total_weight = sum([effect.weight for effect in child_effects])
    weighted_sum = sum([effect.weight * effect.p for effect in child_effects])
    return weighted_sum / total_weight
end


function add!(effects::Dict{Int,Vector{Effect}}, new_effect::Effect)
    if !haskey(effects, new_effect.comment_id)
        effects[new_effect.comment_id] = []
    end
    push!(effects[new_effect.comment_id], new_effect)
end


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


# The total ranking score for a post includes the direct score for
# the post itself, plus the value of its effects on other posts.
function ranking_score(effects::Vector{Effect}, p::Float64)::Float64
    return direct_score(p) + sum([effect_score(e) for e in effects])
end


function effect_score(effect::Effect)::Float64
    return information_gain(effect.p, effect.q, effect.r)
end


function direct_score(p)::Float64
    p * (1 + log2(p))
end
