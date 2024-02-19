"""
    get_score_db(path::String)::SQLite.DB

Get a connection to the score database at the provided path. If the database does not
exist, an error will be thrown.
"""
function get_score_db(path::String)::SQLite.DB
    if !ispath(path)
        error("Database file does not exist: $path")
    end
    return SQLite.DB(path)
end


"""
    to_detailed_tally(result::SQLite.Row)::DetailedTally

Convert a SQLite result row to a `DetailedTally`.
"""
function to_detailed_tally(row::SQLite.Row)::DetailedTally
    return DetailedTally(
        row[:tagId],
        row[:parentId] == 0 ? nothing : row[:parentId],
        row[:postId],
        BernoulliTally(row[:parentCount], row[:parentTotal]),
        BernoulliTally(row[:uninformedCount], row[:uninformedTotal]),
        BernoulliTally(row[:informedCount], row[:informedTotal]),
        BernoulliTally(row[:selfCount], row[:selfTotal]),
    )
end

function to_score_data(r::SQLite.Row)::ScoreData

    return ScoreData(
        r[:tagId],
        ((r[:parentId]==0) ? nothing : r[:parentId]),
        r[:postId],
        r[:parentId]==0 ? nothing : NoteEffect(
            (r[:parentId]==0 ? nothing : r[:parentId]),
            r[:postId],
            (r[:parentUninformedP]==0 ? nothing : r[:parentUninformedP]),
            (r[:parentInformedP]==0 ? nothing : r[:parentInformedP]),
        ),
        r[:selfP],
        BernoulliTally(r[:count], r[:total]),
        r[:topNoteId]==0 ? nothing : NoteEffect(
            r[:postId],
            (r[:topNoteId]==0 ? nothing : r[:topNoteId]),
            (r[:uninformedP]==0 ? nothing : r[:uninformedP]),
            (r[:informedP]==0 ? nothing : r[:informedP]),
        ),
    )
end


"""
    SQLTalliesTree <: TalliesTree

A data structure to represent a tree of tallies stored in an SQLite database.
"""
struct SQLTalliesTree
    tally::DetailedTally
    needs_recalculation::Bool
    db::SQLite.DB
end

function AsTalliesTree(t::SQLTalliesTree)
    return TalliesTree(
        () -> get_tallies(t.db, t.tally.tag_id, t.tally.post_id),
        () -> t.tally,
        () -> t.needs_recalculation,
        () -> get_score_data(t.db, t.tally.tag_id, t.tally.post_id),
    )
end


"""
    get_tallies(
        db::SQLite.DB,
        tag_id::Union{Int,Nothing},
        post_id::Union{Int,Nothing},
    )::Base.Generator

Get the detailed tallies under a given tag and post, along with a boolean indicating if the tally has 
been updated and thus the score needs to be recalculated. If `tag_id` is `nothing`, tallies for
all tags will be returned. If `post_id` is `nothing`, tallies for all top-level posts will be
returned. If both `tag_id` and `post_id` are `nothing`, all tallies will be returned.
The function returns a vector of `SQLTalliesTree`s.
"""
function get_tallies(
    db::SQLite.DB,
    tag_id::Union{Int,Nothing},
    post_id::Union{Int,Nothing},
)::Vector{TalliesTree}

    sql_query = """
        select
            self.tagId
            , ifnull(post.parentId,0)    as parentId
            , post.id                    as postId
            , ifnull(overallCount, 0)   as parentCount
            , ifnull(overallTotal, 0)   as parentTotal
            , ifnull(uninformedCount, 0) as uninformedCount
            , ifnull(uninformedTotal, 0) as uninformedTotal
            , ifnull(informedCount, 0)   as informedCount
            , ifnull(informedTotal, 0)   as informedTotal
            , ifnull(self.count, 0)       as selfCount
            , ifnull(self.total, 0)       as selfTotal
            , NeedsRecalculation.postId is not null as needsRecalculation
        from 
            Post
            join Tally self on (Post.id = self.postId)
            -- left join NeedsRecalculation on (postId, tagId)
            left join NeedsRecalculation on (NeedsRecalculation.postId = post.id and NeedsRecalculation.tagId = self.tagId)
            left join DetailedTally on (post.parentId = detailedTally.postId and post.id = detailedTally.noteId)
        where 
            ifnull(self.tagId = :tag_id, true)
            and ( 
                    ( :post_id is null and parentId is null and needsRecalculation)
                    or 
                    ( post.parentId = :post_id)
                )
        """

    # println("Getting tallies for post $post_id")

    results = DBInterface.execute(db, sql_query, [tag_id, post_id])

    return [AsTalliesTree(SQLTalliesTree(to_detailed_tally(row), row[:needsRecalculation], db)) for row in results]
end


function get_score_data(
    db::SQLite.DB,
    tag_id::Int,
    post_id::Int,
)
    get_score_sql = """
        select
            ScoreData.tagId
            , ifnull(ScoreData.parentId, 0) parentId
            , ScoreData.postId
            , ifnull(topNoteId, 0) topNoteId
            , ifnull(parentUninformedP, 0) parentUninformedP
            , ifnull(parentInformedP, 0) parentInformedP
            , ifnull(uninformedP, 0) uninformedP
            , ifnull(informedP, 0) informedP
            , ifnull(uninformedP, 0) uninformedP
            , ifnull(informedP, 0) informedP
            , count
            , total
            , selfP
           -- , NeedsRecalculation.postId is not null as needsRecalculation

        from ScoreData
        -- left join NeedsRecalculation using (postId)
        where 
            ifnull(ScoreData.tagId = :tag_id, true)
            and ifnull(ScoreData.postId = :post_id, true)
            -- Only return existing score data that is not out of date.
            -- and not needsRecalculation

    """
    # println("Getting score data for post $post_id")

    results = DBInterface.execute(db, get_score_sql, [tag_id, post_id])

    r = iterate(results)

    if isnothing(r) 
        # println("No result in get_score_data")
        return nothing
    end

    # if isnothing(r[1])
    #     println("No result in get_score_data")
    #     return nothing
    # end

    # println("Got existing score data for post $post_id")

    return to_score_data(r[1])

end

"""
    insert_score_data(
        db::SQLite.DB,
        score_data::ScoreData,
    )::Nothing

Insert a `ScoreData` instance into the score database.
"""
function insert_score_data(db::SQLite.DB, score_data::ScoreData)
    sql_query = """
        insert or replace into ScoreData(
            tagId
            , parentId
            , postId
            , topNoteId
            , parentUninformedP
            , parentInformedP
            , uninformedP
            , informedP
            , count
            , total
            , selfP
        ) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """

    DBInterface.execute(
        db,
        sql_query,
        [
            score_data.tag_id,
            score_data.parent_id,
            score_data.post_id,
            score_data.top_note_effect !== nothing ? score_data.top_note_effect.note_id :
            nothing,
            score_data.effect !== nothing ? score_data.effect.uninformed_probability :
            nothing,
            score_data.effect !== nothing ? score_data.effect.informed_probability :
            nothing,
            score_data.top_note_effect !== nothing ?
            score_data.top_note_effect.uninformed_probability : nothing,
            score_data.top_note_effect !== nothing ?
            score_data.top_note_effect.informed_probability : nothing,
            score_data.self_tally.count,
            score_data.self_tally.sample_size,
            score_data.self_probability
        ],
    )


end

function set_last_processed_vote_event_id(db::SQLite.DB)
    DBInterface.execute(db, "update lastVoteEvent set processedVoteEventId = importedVoteEventId;")
end

function get_last_processed_vote_event_id(db::SQLite.DB)
    results = DBInterface.execute(db, "select processedVoteEventId from lastVoteEvent;")
    r = iterate(results)
    return r[1][:processedVoteEventId]
end
