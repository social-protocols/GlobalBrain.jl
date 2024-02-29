"""
    to_detailed_tally(result::SQLite.Row)::GlobalBrain.DetailedTally

Convert a SQLite result row to a `GlobalBrain.DetailedTally`.
"""
function to_detailed_tally(row::SQLite.Row)::GlobalBrain.DetailedTally
    return GlobalBrain.DetailedTally(
        tag_id = row[:tagId],
        parent_id = row[:parentId] == 0 ? nothing : row[:parentId],
        post_id = row[:postId],
        parent = GlobalBrain.BernoulliTally(row[:parentCount], row[:parentTotal]),
        uninformed = GlobalBrain.BernoulliTally(row[:uninformedCount], row[:uninformedTotal]),
        informed = GlobalBrain.BernoulliTally(row[:informedCount], row[:informedTotal]),
        overall = GlobalBrain.BernoulliTally(row[:selfCount], row[:selfTotal]),
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
            post_id = (row[:parentId] == 0 ? nothing : row[:parentId]),
            note_id = row[:postId],
            informed_probability = (row[:parentP] == 0 ? nothing : row[:parentP]),
            uninformed_probability = (row[:parentQ] == 0 ? nothing : row[:parentQ]),
            # informed_tally = BernoulliTally(row[:informedCount], row[:informedSampleSize]),
            # uninformed_tally = BernoulliTally(row[:uninformedCount], row[:uninformedSampleSize]),
        ),
        overall_probability = row[:overallP],
        # overall_tally = GlobalBrain.BernoulliTally(row[:overallCount], row[:overallSampleSize]),
        overall_tally = GlobalBrain.BernoulliTally(row[:count], row[:sampleSize]),
        top_note_effect = row[:topNoteId] == 0 ? nothing : GlobalBrain.NoteEffect(
            post_id = row[:postId],
            note_id = (row[:topNoteId] == 0 ? nothing : row[:topNoteId]),
            informed_probability = (row[:p] == 0 ? nothing : row[:p]),
            uninformed_probability = (row[:q] == 0 ? nothing : row[:q]),
        )
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
        return isnothing(x) ? nothing : round(x, digits=4)
    end

    return ScoreEvent(
        scoreEventId = nothing, # Assigned by database
        voteEventId = vote_event_id,
        voteEventTime = vote_event_time,
        tagId = score_data.tag_id,
        parentId = score_data.parent_id,
        postId = score_data.post_id,
        topNoteId = top_note_id(score_data),
        parentP = rnd(parent_informed_probability(score_data)),
        parentQ = rnd(parent_uninformed_probability(score_data)),
        # parentP = parent_informed_probability(score_data),
        # parentQ = parent_uninformed_probability(score_data),
        p = rnd(informed_probability(score_data)),
        q = rnd(uninformed_probability(score_data)),
        overallP = rnd(score_data.overall_probability),
        # informedCount = informed_tally(score_data).count,
        # informedSampleSize = informed_tally(score_data).sample_size,
        # uninformedCount = uninformed_tally(score_data).count,
        # uninformedSampleSize = uninformed_tally(score_data).sample_size,
        # overallCount = score_data.overall_tally.count,
        # overallSampleSize = score_data.overall_tally.sample_size,
        count = score_data.overall_tally.count,
        sampleSize = score_data.overall_tally.sample_size,
        score = rnd(score(score_data)),
    )
end


function with_score_event_id(r::ScoreEvent, score_event_id::Integer)::ScoreEvent
    return ScoreEvent(
        scoreEventId = score_event_id,
        voteEventId = r.voteEventId,
        voteEventTime = r.voteEventTime,
        tagId = r.tagId,
        parentId = r.parentId,
        postId = r.postId,
        topNoteId = r.topNoteId,
        parentP = r.parentP,
        parentQ = r.parentQ,
        p = r.p,
        q = r.q,
        overallP = r.overallP,
        # informedCount = r.informedCount,
        # informedSampleSize = r.informedSampleSize,
        # uninformedCount = r.uninformedCount,
        # uninformedSampleSize = r.uninformedSampleSize,
        # overallCount = r.overallCount,
        # overallSampleSize = r.overallSampleSize,
        count = r.count,
        sampleSize = r.sampleSize,
        score = r.score,
    )
end
