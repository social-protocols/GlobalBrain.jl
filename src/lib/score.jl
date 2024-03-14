function score(effect::Effect)::Float64 
	return relative_entropy(effect.p, effect.q)
end

function total_score(effects::Vector{Effect}, top_note_effect::Union{Effect, Nothing}, tally::BernoulliTally)::Float64
	r =
        GLOBAL_PRIOR_UPVOTE_PROBABILITY |>
        (x -> update(x, tally)) |>
        (x -> x.mean)

	p = isnothing(top_note_effect) ? r : top_note_effect.p

    post_score = p*(1 + log2(p))
    note_score = sum([score(e) for e in effects])

	return post_score + note_score
end

