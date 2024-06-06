function score_posts(output::Function, posts::Vector{TalliesData})
    effects = Dict{Int,Vector{Effect}}()

    for post in posts
        score_post(output, post, effects)
    end
end

function score_post(yield::Function, post::TalliesData, effects::Dict{Int,Vector{Effect}})
    post_id = post.post_id
    @debug "In score post $post_id"

    if !post.needs_recalculation
        @debug "No recalculation needed for $(post_id). Using existing score"
        return Vector{Score}()
    end

    this_tally = post.tally()

    o = GLOBAL_PRIOR_UPVOTE_PROBABILITY |> (x -> update(x, this_tally))

    @debug "Overall probability in score_post for $post_id is $(o.mean)"

    top_thread = find_top_thread(post_id, post, o, effects)
    p = !isnothing(top_thread) ? top_thread.p : o.mean

    my_effects::Vector{Effect} = get(effects, post_id, [])

    for e in my_effects
        yield(e)
    end

    for child in post.children()
        score_post(yield, child, effects)
    end

    score = Score(
        post_id = post_id,
        top_comment_id = !isnothing(top_thread) ? top_thread.comment_id : nothing,
        critical_thread_id = !isnothing(top_thread) ?
                             coalesce(top_thread.comment_id, top_thread.top_subthread_id) : nothing,
        o = o.mean,
        o_count = this_tally.count,
        o_size = this_tally.size,
        p = p,
        score = ranking_score(my_effects, p),
    )

    yield(score)
end


function find_top_thread(
    post_id::Int,
    note::TalliesData,
    r::BetaDistribution,
    effects::Dict{Int,Vector{Effect}},
)::Union{Effect,Nothing}

    comment_id = note.post_id

    @debug "find_top_thread $post_id=>$(comment_id), r=$(r.mean)"

    children = note.children()

    n = length(children)
    @debug "Got $n children for $comment_id"


    @debug "Getting effects of children of $comment_id on $post_id"

    child_effects = [calc_thread_effect(post_id, child, r, effects) for child in children]


    for effect in child_effects
        add!(effects, effect)
    end

    child_effects = filter(x -> thread_score(x) > 0, child_effects)

    if length(child_effects) == 0
        return nothing
    end

    if post_id == 1 && comment_id == 2
        for x in child_effects
            @debug "child_effect=$(thread_score(x))"
        end
    end


    result = reduce((a, b) -> begin
        ma = isnothing(a) ? 0 : thread_score(a)
        mb = isnothing(b) ? 0 : thread_score(b)
        ma > mb ? a : b
    end, child_effects)

    if post_id == 1 && comment_id == 2
        @debug "Result here: $result"
    end

    return result

end


function calc_thread_effect(
    post_id::Int,
    note::TalliesData,
    prior::BetaDistribution,
    effects,
)::Effect

    comment_id = note.post_id

    if !note.needs_recalculation
        return note.effect(post_id)
    end

    tally = note.conditional_tally(post_id)

    (q, r) = upvote_probabilities(prior, tally)

    top_thread = find_top_thread(post_id, note, r, effects)

    @debug "top_thread=$top_thread for $post_id=>$comment_id"

    (p, top_subthread_id) = if !isnothing(top_thread)
        (top_thread.p, coalesce(top_thread.top_subthread_id, top_thread.comment_id))
    else
        (r.mean, nothing)
    end

    @debug "p=$p for $post_id=>$comment_id"

    return Effect(
        post_id = post_id,
        comment_id = comment_id,
        top_subthread_id = top_subthread_id,
        p = p,
        p_count = tally.informed.count,
        p_size = tally.informed.size,
        q = q,
        q_count = tally.uninformed.count,
        q_size = tally.uninformed.size,
        r = r.mean,
    )
end


function add!(effects::Dict{Int,Vector{Effect}}, effect::Effect)
    if !haskey(effects, effect.comment_id)
        effects[effect.comment_id] = []
    end
    push!(effects[effect.comment_id], effect)
end
