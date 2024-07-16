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


function score_tree_and_emit_events(
    tree::TalliesTree,
    emit_event::Function,
    effects::Dict{Int,Vector{Effect}},
)
    post_id = tree.post_id
    @debug "In score post $post_id"

    if !tree.needs_recalculation
        @debug "No recalculation needed for $(post_id). Using existing score"
        return Vector{Score}()
    end

    o = GLOBAL_PRIOR_UPVOTE_PROBABILITY |> (x -> update(x, tree.tally))
    @debug "Overall probability in score_post for $post_id is $(o.mean)"

    p = calc_informed_probability_and_effects(
        post_id,
        tree,
        o,
        (effect) -> add!(effects, effect),
        emit_event,
    )

    for subtree in tree.children()
        score_tree_and_emit_events(subtree, emit_event, effects) # recursion
    end

    score = Score(
        post_id = post_id,
        o = o.mean,
        o_count = tree.tally.count,
        o_size = tree.tally.size,
        p = p,
        score = ranking_score(post_id, effects, p),
    )
    emit_event(score)
end


function calc_informed_probability_and_effects(
    target_id::Int,
    subtree::TalliesTree,
    r::BetaDistribution,
    effect_callback::Function,
    emit_event::Function,
)::Number
    child_effects::Vector{Effect} = map(
        child -> begin
            effect = if !child.needs_recalculation
                child.effect_on(target_id) # TODO: should an event also be emitted for this effect?
            else
                tally = child.conditional_tally(target_id)
                r_dist = partially_informed_probability_dist(r, tally)
                effect = Effect(
                    target_id,
                    child.post_id,
                    calc_informed_probability_and_effects(
                        target_id,
                        child,
                        r_dist,
                        effect_callback,
                        emit_event,
                    ), # recursion
                    calc_uninformed_probability(r, tally),
                    r_dist.mean,
                    tally,
                )
                emit_event(effect)
                effect
            end
            effect_callback(effect)
            return effect
        end,
        subtree.children(),
    )

    return weighted_average_informed_probability(child_effects, r)
end


function weighted_average_informed_probability(
    child_effects::Vector{Effect},
    r::BetaDistribution,
)::Number
    total_weight = sum([effect.weight for effect in child_effects])
    if total_weight == 0
        return r.mean
    end
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
function ranking_score(
    post_id::Int64,
    effects::Dict{Int64,Vector{Effect}},
    p::Float64,
)::Float64
    return direct_score(p) + sum([effect_score(e) for e in get(effects, post_id, [])])
end


function effect_score(effect::Effect)::Float64
    return information_gain(effect.p, effect.q, effect.r)
end


function direct_score(p)::Float64
    p * (1 + log2(p))
end
