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
    get_tallies(
        db::SQLite.DB,
        tag_id::Union{Int, Nothing},
        post_id::Union{Int, Nothing},
    )::Vector{GlobalBrain.TalliesTree}

Get the detailed tallies under a given tag and post, along with a boolean indicating if the tally has 
been updated and thus the score needs to be recalculated. If `tag_id` is `nothing`, tallies for
all tags will be returned. If `post_id` is `nothing`, tallies for all top-level posts will be
returned. If both `tag_id` and `post_id` are `nothing`, all tallies will be returned.
The function returns a vector of `SQLTalliesTree`s.
"""
function get_tallies(
    db::SQLite.DB,
    tag_id::Union{Int, Nothing},
    post_id::Union{Int, Nothing},
)::Vector{GlobalBrain.TalliesTree}
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

    results = DBInterface.execute(db, sql_query, [tag_id, post_id])

    return [
        SQLTalliesTree(to_detailed_tally(row), row[:needsRecalculation], db) |>
            as_tallies_tree
        for row in results
    ]
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
            , ifnull(parentQ, 0) parentQ
            , ifnull(parentP, 0) parentP
            , ifnull(q, 0) q
            , ifnull(p, 0) p
            , ifnull(q, 0) q
            , ifnull(p, 0) p
            , overallP
            , count
            , sampleSize
           -- , NeedsRecalculation.postId is not null as needsRecalculation

        from ScoreData
        -- left join NeedsRecalculation using (postId)
        where 
            ifnull(ScoreData.tagId = :tag_id, true)
            and ifnull(ScoreData.postId = :post_id, true)
            -- Only return existing score data that is not out of date.
            -- and not needsRecalculation

    """

    results = DBInterface.execute(db, get_score_sql, [tag_id, post_id])

    r = iterate(results)

    if isnothing(r) 
        return nothing
    end

    # if isnothing(r[1])
    #     println("No result in get_score_data")
    #     return nothing
    # end

    # println("Got existing score data for post $post_id")

    return to_score_data(r[1])
end


function as_tallies_tree(t::SQLTalliesTree)
    return GlobalBrain.TalliesTree(
        () -> get_tallies(t.db, t.tally.tag_id, t.tally.post_id),
        () -> t.tally,
        () -> t.needs_recalculation,
        () -> get_score_data(t.db, t.tally.tag_id, t.tally.post_id),
    )
end


"""
    insert_score_data(
        db::SQLite.DB,
        score_data::ScoreData,
    )::Nothing

Insert a `ScoreData` instance into the score database.
"""
function insert_score_data(db::SQLite.DB, score_data_record::ScoreDataRecord)
    SQLite.load!([score_data_record], db, "ScoreData"; on_conflict="REPLACE")
end



function set_last_processed_vote_event_id(db::SQLite.DB)
    DBInterface.execute(
        db,
        "update lastVoteEvent set processedVoteEventId = importedVoteEventId"
    )
end


function get_last_processed_vote_event_id(db::SQLite.DB)
    results = DBInterface.execute(db, "select processedVoteEventId from lastVoteEvent")
    r = iterate(results)
    return r[1][:processedVoteEventId]
end
