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
        row[:tagId],
        ((row[:parentId] == 0) ? nothing : row[:parentId]),
        row[:postId],
        row[:parentId] == 0 ? nothing : GlobalBrain.NoteEffect(
            (row[:parentId] == 0 ? nothing : row[:parentId]),
            row[:postId],
            (row[:parentUninformedP] == 0 ? nothing : row[:parentUninformedP]),
            (row[:parentInformedP] == 0 ? nothing : row[:parentInformedP]),
        ),
        row[:selfP],
        GlobalBrain.BernoulliTally(row[:count], row[:total]),
        row[:topNoteId] == 0 ? nothing : GlobalBrain.NoteEffect(
            row[:postId],
            (row[:topNoteId] == 0 ? nothing : row[:topNoteId]),
            (row[:uninformedP] == 0 ? nothing : row[:uninformedP]),
            (row[:informedP] == 0 ? nothing : row[:informedP]),
        ),
    )
end


"""
    as_score_data_record(
        score_data::GlobalBrain.ScoreData,
        created_at::Int,
    )::ScoreDataRecord

Convert a `GlobalBrain.ScoreData` object to a flat `ScoreDataRecord` for the database.
"""
function as_score_data_record(
    score_data::GlobalBrain.ScoreData,
    created_at::Int,
)::ScoreDataRecord
    return ScoreDataRecord(
        score_data.tag_id,
        score_data.parent_id,
        score_data.post_id,
        !isnothing(score_data.top_note_effect) ? score_data.top_note_effect.note_id :
        nothing,
        !isnothing(score_data.effect) ? score_data.effect.uninformed_probability :
        nothing,
        !isnothing(score_data.effect) ? score_data.effect.informed_probability :
        nothing,
        !isnothing(score_data.top_note_effect) ?
        score_data.top_note_effect.uninformed_probability : nothing,
        !isnothing(score_data.top_note_effect) ?
        score_data.top_note_effect.informed_probability : nothing,
        score_data.self_tally.count,
        score_data.self_tally.sample_size,
        score_data.self_probability,
        created_at
    )
end
