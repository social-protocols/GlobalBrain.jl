"""
    to_detailed_tally(result::SQLite.Row)::GlobalBrain.DetailedTally

Convert a SQLite result row to a `GlobalBrain.DetailedTally`.
"""
function to_detailed_tally(row::SQLite.Row)::GlobalBrain.DetailedTally
    return GlobalBrain.DetailedTally(
        row[:tagId],
        row[:parentId] == 0 ? nothing : row[:parentId],
        row[:postId],
        GlobalBrain.BernoulliTally(row[:parentCount], row[:parentTotal]),
        GlobalBrain.BernoulliTally(row[:uninformedCount], row[:uninformedTotal]),
        GlobalBrain.BernoulliTally(row[:informedCount], row[:informedTotal]),
        GlobalBrain.BernoulliTally(row[:selfCount], row[:selfTotal]),
    )
end


"""
    to_score_data(r::SQLite.Row)::GlobalBrain.ScoreData

Convert a SQLite result row to a `GlobalBrain.ScoreData`.
"""
function to_score_data(row::SQLite.Row)::GlobalBrain.ScoreData
    return GlobalBrain.ScoreData(
        tag_id = row[:tagId],
        parent_id = ((row[:parentId] == 0) ? nothing : row[:parentId]),
        post_id = row[:postId],
        effect = row[:parentId] == 0 ? nothing : GlobalBrain.NoteEffect(
            (row[:parentId] == 0 ? nothing : row[:parentId]),
            row[:postId],
            (row[:parentQ] == 0 ? nothing : row[:parentQ]),
            (row[:parentP] == 0 ? nothing : row[:parentP]),
        ),
        self_probability = row[:overallP],
        self_tally = GlobalBrain.BernoulliTally(row[:count], row[:sampleSize]),
        top_note_effect = row[:topNoteId] == 0 ? nothing : GlobalBrain.NoteEffect(
            row[:postId],
            (row[:topNoteId] == 0 ? nothing : row[:topNoteId]),
            (row[:q] == 0 ? nothing : row[:q]),
            (row[:p] == 0 ? nothing : row[:p]),
        ),
    )
end


"""
    as_score_event(
        score_data::GlobalBrain.ScoreData
        vote_event_id::Int,
        vote_event_time::Int,
    )::ScoreEvent

Convert a `GlobalBrain.ScoreData` object to a flat `Score` for the database.
"""
function as_score_event(
    score_data::GlobalBrain.ScoreData,
    vote_event_id::Int,
    vote_event_time::Int,
)::ScoreEvent

    function rnd(x)
        return round(x, digits=4)
    end

    return ScoreEvent(
        score_event_id = nothing, # Assigned by database
        vote_event_id = vote_event_id,
        vote_event_time = vote_event_time,
        tag_id = score_data.tag_id,
        parent_id = score_data.parent_id,
        post_id = score_data.post_id,
        top_note_id = !isnothing(score_data.top_note_effect) ? score_data.top_note_effect.note_id :
            nothing,
        parent_q = !isnothing(score_data.effect) ? rnd(score_data.effect.uninformed_probability) :
            nothing,
        parent_p = !isnothing(score_data.effect) ? rnd(score_data.effect.informed_probability) :
            nothing,
        q = !isnothing(score_data.top_note_effect) ?
            rnd(score_data.top_note_effect.uninformed_probability) : nothing,
        p = !isnothing(score_data.top_note_effect) ?
            rnd(score_data.top_note_effect.informed_probability) : nothing,
        count = score_data.self_tally.count,
        sample_size = score_data.self_tally.sample_size,
        overall_p = score_data.self_probability,
    )
end


function with_score_event_id(r::ScoreEvent, score_event_id::Integer)::ScoreEvent
    return ScoreEvent(
        score_event_id = score_event_id,
        vote_event_id = r.vote_event_id,
        vote_event_time = r.vote_event_time,
        tag_id = r.tag_id,
        parent_id = r.parent_id,
        post_id = r.post_id,
        top_note_id = r.top_note_id,
        parent_q = r.parent_q,
        parent_p = r.parent_p,
        q = r.q,
        p = r.p,
        count = r.count,
        sample_size = r.sample_size,
        overall_p = r.overall_p,
    )
end
