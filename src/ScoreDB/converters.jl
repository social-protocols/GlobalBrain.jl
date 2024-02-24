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
        tagId = score_data.tag_id,
        parentId = score_data.parent_id,
        postId = score_data.post_id,
        topNoteId = !isnothing(score_data.top_note_effect) ? score_data.top_note_effect.note_id :
            nothing,
        parentQ = !isnothing(score_data.effect) ? score_data.effect.uninformed_probability :
            nothing,
        parentP = !isnothing(score_data.effect) ? score_data.effect.informed_probability :
            nothing,
        q = !isnothing(score_data.top_note_effect) ?
            score_data.top_note_effect.uninformed_probability : nothing,
        p = !isnothing(score_data.top_note_effect) ?
            score_data.top_note_effect.informed_probability : nothing,
        overallP = score_data.self_probability,
        count = score_data.self_tally.count,
        sampleSize = score_data.self_tally.sample_size,
        updatedAt = created_at
    )
end
