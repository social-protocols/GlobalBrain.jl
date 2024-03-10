"""
    to_detailed_tally(result::SQLite.Row)::GlobalBrain.DetailedTally

Convert a SQLite result row to a `GlobalBrain.DetailedTally`.
"""
function to_detailed_tally(row::SQLite.Row)::GlobalBrain.DetailedTally
    return GlobalBrain.DetailedTally(
        tag_id = row[:tag_id],
        ancestor_id = row[:ancestor_id] == 0 ? nothing : row[:ancestor_id],
        parent_id = row[:parent_id] == 0 ? nothing : row[:parent_id],
        post_id = row[:post_id],
        parent = GlobalBrain.BernoulliTally(row[:parentCount], row[:parentTotal]),
        uninformed = GlobalBrain.BernoulliTally(row[:uninformed_count], row[:uninformed_total]),
        informed = GlobalBrain.BernoulliTally(row[:informed_count], row[:informed_total]),
        overall = GlobalBrain.BernoulliTally(row[:selfCount], row[:selfTotal]),
    )
end


function to_effect_event(row::SQLite.Row)::EffectEvent
    return EffectEvent(
        vote_event_id = row[:vote_event_id],
        vote_event_time = row[:vote_event_time],
        effect = GlobalBrain.Effect(
            tag_id = row[:tag_id],
            post_id = row[:post_id],
            note_id = row[:note_id],
            p = row[:p],
            q = row[:q],
            r = row[:r],
            p_count = row[:p_count],
            q_count = row[:q_count],
            r_count = row[:r_count],
            p_size = row[:p_size],
            q_size = row[:q_size],
            r_size = row[:r_size],
        )
    )
end
