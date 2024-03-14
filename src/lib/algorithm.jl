"""
    score_tree(
        output_result::Function,
        tallies::Base.Generator,
    )::Vector{Score}

Score a tree of tallies.

# Parameters
    * `output_result::Function`: A function to output the score or effect. This function can be used for side effects, such as
      writing to a database.
    * `tallies::Base.Generator`: A `Base.Generator` of `SQLTalliesTree`s.
"""
function score_tree(
    output_results::Function,
    tallies::Vector{TalliesTree}
)
    effects = Dict{Int, Vector{Effect}}()

    for post in tallies
        score_post(output_results, post, effects)
    end

end

function score_post(
    output_results::Function,
    post::TalliesTree,
    effects::Dict{Int, Vector{Effect}},
)

    this_tally = post.tally()

    if !post.needs_recalculation()
        # @info "No recalculation needed for $(this_tally.post_id). Using existing effect data"
        return
    else
        # @info "Calculating score for $(this_tally.post_id)"
    end

    post_id = this_tally.post_id

    # @info "Scoring post $post_id"
    
    o =
        GLOBAL_PRIOR_UPVOTE_PROBABILITY |>
        (x -> update(x, this_tally.overall))

    # @info "Overall probability in score_post for $post_id is $(o.mean)"

    # @info "Calling find_top_note_effect_relative $post_id=>$(post.tally().post_id)"

    top_note_effect = find_top_note_effect_relative(post_id, o, post, effects)

    my_effects::Vector{Effect} = get(effects, post_id, [])
    for e in my_effects
        output_results(e)
    end
    my_score = total_score(my_effects, top_note_effect, this_tally.overall)

    children = post.children(post_id)
    for child in children
        score_post(output_results, child, effects)
    end

    score = Score(
        tag_id = this_tally.tag_id,
        post_id = post_id,
        top_note_id = !isnothing(top_note_effect) ? top_note_effect.note_id : nothing,
        o = o.mean,
        o_count = this_tally.overall.count,
        o_size = this_tally.overall.size,
        p = !isnothing(top_note_effect) ? top_note_effect.p : o.mean,
        score = my_score,
    ) 

    output_results(score)

end


function find_top_note_effect_relative(
    post_id::Int,
    r::BetaDistribution,
    note::TalliesTree,
    effects::Dict{Int, Vector{Effect}},
)::Union{Effect,Nothing}

    note_id = note.tally().post_id

    @info "Finding top note effect relative $post_id, r=$(r.mean), $(note_id)"

    children = note.children(post_id)

    n = length(children)
    # @info "Got children $n children for $note_id"

    if length(children) == 0
        return nothing
    end

    # @info "Getting child effects"

    child_effects = [calc_note_effect_relative(post_id, r, child, effects) for child in children]

    # @info "Got child effects $child_effects"

    for effect in child_effects
        add!(effects, effect) 
    end

    return reduce(
        (a, b) -> begin
            ma = isnothing(a) ? 0 : score_effect(a)
            mb = isnothing(b) ? 0 : score_effect(b)
            ma > mb ? a : b
        end,
        child_effects
    )
end


function calc_note_effect_relative(post_id, prior::BetaDistribution, note::TalliesTree, effects)

        # this_note_effect = 
        # @info "Calculated relative note effect $post_id, $prior, $(note.tally().post_id): $effect"
    tally = note.tally()
    note_id = tally.post_id

    uninformed_probability =
        prior |>
        (x -> reset_weight(x, GLOBAL_PRIOR_INFORMED_UPVOTE_PROBABILITY_SAMPLE_SIZE)) |>
        (x -> update(x, tally.uninformed)) |>
        (x -> x.mean)

    @info "Uninformed probability for $post_id=>$note_id is $uninformed_probability $(prior.mean):($(tally.uninformed.count), $(tally.uninformed.size))"

    informed_probability =
        prior |>
        (x -> reset_weight(x, GLOBAL_PRIOR_INFORMED_UPVOTE_PROBABILITY_SAMPLE_SIZE)) |>
        (x -> update(x, tally.informed))

    @info "Informed probability for $post_id=>$note_id is $(informed_probability.mean) $(prior.mean):($(tally.informed.count), $(tally.informed.size))"


    # First find the top note effect on me!
    # top_subnote_effect = find_top_note_effect_relative(post_id, informed_probability, note, effects)
    # supp = calc_note_support(top_subnote_effect)
    # prior = this_note_effect.p * supp + this_note_effect.q * (1 - supp)

    # informed_probability_supported = if isnothing(top_subnote_effect)
    #     this_note_effect.p
    # else
    #     top_subnote_effect.p
    # end


    top_child_effect = find_top_note_effect_relative(post_id, informed_probability, note, effects)

    @info "top_child_effect=$top_child_effect for $post_id=>$(note.tally().post_id)"

    informed_probability_adjusted = if !isnothing(top_child_effect)
        top_child_effect.p 
    else
        informed_probability.mean
    end

    @info "informed_probability_adjusted=$informed_probability_adjusted for $post_id=>$(note.tally().post_id)"

    return Effect(
        tag_id = tally.tag_id,
        post_id = post_id,
        note_id = note_id,

        p = informed_probability_adjusted,
        p_count = tally.informed.count,
        p_size = tally.informed.size,

        q = uninformed_probability,
        q_count = tally.uninformed.count,
        q_size = tally.uninformed.size,
    )
end


function add!(effects::Dict{Int, Vector{Effect}}, effect::Effect)
    if !haskey(effects, effect.note_id)
        effects[effect.note_id] = []
    end
    push!(effects[effect.note_id], effect)
end


function score_effect(effect::Effect)
    return relative_entropy(effect.p, effect.q) * effect.p_size
end
