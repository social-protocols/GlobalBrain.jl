"""
    to_detailed_tally(result::SQLite.Row)::DetailedTally

Convert a SQLite result row to a `DetailedTally`.
"""
function to_detailed_tally(row::SQLite.Row)::DetailedTally
    return DetailedTally(
        tag_id = row[:tag_id],
        ancestor_id = row[:ancestor_id] == 0 ? nothing : row[:ancestor_id],
        parent_id = row[:parent_id] == 0 ? nothing : row[:parent_id],
        post_id = row[:post_id],
        parent = BernoulliTally(row[:parentCount], row[:parentTotal]),
        uninformed = BernoulliTally(row[:uninformed_count], row[:uninformed_total]),
        informed = BernoulliTally(row[:informed_count], row[:informed_total]),
        overall = BernoulliTally(row[:selfCount], row[:selfTotal]),
    )
end


function to_effect_event(row::SQLite.Row)::EffectEvent
    return EffectEvent(
        vote_event_id = row[:vote_event_id],
        vote_event_time = row[:vote_event_time],
        effect = Effect(
            tag_id = row[:tag_id],
            post_id = row[:post_id],
            note_id = row[:note_id],
            p = row[:p],
            p_count = row[:p_count],
            q = row[:q],
            p_size = row[:p_size],
            q_count = row[:q_count],
            q_size = row[:q_size],
        )
    )
end
