
"""
    score_tree(
        tallies::Base.Generator,
        output_result::Function,
    )::Vector{Score}

Score a tree of tallies.

# Parameters

    * `tallies::Base.Generator`: A `Base.Generator` of `SQLTalliesTree`s.
    * `output_result::Function`: A function to output the score or effect. If
      `nothing`, no output is produced. This function can be used for side effects, such as
      writing to a database.
"""
function score_tree(
    output_result::Function,
    tallies::Vector{TalliesTree},
)::Vector{Effect}
    function score_subtree(t::TalliesTree)::Vector{Effect}

        this_tally = t.tally()

        if !t.needs_recalculation()
#            @info "No recalculation needed for $(this_tally.post_id). Using existing effect data"
            return isnothing(this_tally.parent_id) ? [] : [t.effect()]
        else 
#            @info "Calculating score for $(this_tally.post_id)"
        end

        subnote_effects = score_tree(output_result, t.children(this_tally.post_id))

        this_note_effect =
            isnothing(this_tally.parent_id) ? nothing : calc_note_effect(this_tally)

        upvote_probability =
            GLOBAL_PRIOR_UPVOTE_PROBABILITY |>
            (x -> update(x, this_tally.overall)) |>
            (x -> x.mean)

        # Find the top subnote
        # TODO: The top subnote will tend to be one that hasn't received a lot of replies
        #       that reduce its support. Perhaps weigh by amount of attention received? In
        #       general, we need to deal with multiple subnotes better.
        top_subnote_effect = reduce(
            (a, b) -> begin
                ma = isnothing(a) ? 0 : magnitude(a)
                mb = isnothing(b) ? 0 : magnitude(b)
                # TODO: Do we need a tie-breaker here?
                ma > mb ? a : b
            end,
            [x for x in subnote_effects if x.post_id == this_tally.post_id];
            init = nothing,
        )

        this_note_effect_supported = if isnothing(this_note_effect)
            nothing
        else
            informed_probability_supported = if isnothing(top_subnote_effect)
                this_note_effect.p
            else
                supp = calc_note_support(top_subnote_effect)
                this_note_effect.p * supp +
                this_note_effect.q * (1 - supp)
            end
            something(
                Effect(
                    tag_id = this_note_effect.tag_id,
                    post_id = this_note_effect.post_id,
                    note_id = this_note_effect.note_id,
                    p = informed_probability_supported,
                    q = this_note_effect.q,
                    r = this_note_effect.r,
                    p_count = this_note_effect.p_count,
                    q_count = this_note_effect.q_count,
                    r_count = this_note_effect.r_count,
                    p_size = this_note_effect.p_size,
                    q_size = this_note_effect.q_size,
                    r_size = this_note_effect.r_size,
                ),
                nothing,
            )
        end

        effects = isnothing(this_note_effect_supported) ? Vector{Effect}() : [this_note_effect_supported]
        score = total_score(effects, top_subnote_effect, this_tally.overall)

        this_score_data = Score(
            tag_id = this_tally.tag_id,
            # parent_id = this_tally.parent_id,
            post_id = this_tally.post_id,
            # upvote_probability = upvote_probability,
            # tally = this_tally.overall,
            top_note_id = isnothing(top_subnote_effect) ? nothing : top_subnote_effect.note_id,
            # p = isnothing(top_subnote_effect) ? upvote_probability : top_subnote_effect.p,
            # q = isnothing(top_subnote_effect) ? upvote_probability : top_subnote_effect.uninformed_probability,
            o = upvote_probability,
            o_count = this_tally.overall.count,            
            o_size = this_tally.overall.size,
            p = isnothing(top_subnote_effect) ? upvote_probability : top_subnote_effect.p,
            score = score,
        )

        for e in effects
            output_result(e)
        end

        output_result(this_score_data)

        return effects
    end

    return mapreduce(score_subtree, vcat, tallies; init = [])
end

