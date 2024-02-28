"""
    get_score_db(path::String)::SQLite.DB

Get a connection to the score database at the provided path. If the database does not
exist, an error will be thrown.
"""
function get_score_db(path::String)::SQLite.DB
    init_score_db(path)
    return SQLite.DB(path)
end

function init_score_db(database_path::String)
    if !isfile(database_path)
        @info "Initializing database at $database_path"
        run(pipeline(`cat sql/tables.sql`, `sqlite3 $database_path`))
        run(pipeline(`cat sql/views.sql`, `sqlite3 $database_path`))
        run(pipeline(`cat sql/triggers.sql`, `sqlite3 $database_path`))
    end
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
            , ifnull(parentId,0)    as parentId
            , self.postId                    as postId
            , ifnull(parentCount, 0)   as parentCount
            , ifnull(parentTotal, 0)   as parentTotal
            , ifnull(uninformedCount, 0) as uninformedCount
            , ifnull(uninformedTotal, 0) as uninformedTotal
            , ifnull(informedCount, 0)   as informedCount
            , ifnull(informedTotal, 0)   as informedTotal
            , ifnull(self.count, 0)       as selfCount
            , ifnull(self.total, 0)       as selfTotal
            , NeedsRecalculation.postId is not null as needsRecalculation
        from 
            Tally self
            -- left join NeedsRecalculation on (postId, tagId)
            left join NeedsRecalculation on (NeedsRecalculation.postId = self.postId and NeedsRecalculation.tagId = self.tagId)
            left join DetailedTally on (parentId = detailedTally.postId and self.postId = detailedTally.noteId)
        where 
            ifnull(self.tagId = :tag_id, true)
            and ( 
                    ( :post_id is null and self.parentId is null and needsRecalculation)
                    or 
                    ( self.parentId = :post_id)
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
            Score.tagId
            , ifnull(Score.parentId, 0) parentId
            , Score.postId
            , ifnull(topNoteId, 0) topNoteId
            , ifnull(parentQ, 0) parentQ
            , ifnull(parentP, 0) parentP
            , ifnull(q, 0) q
            , ifnull(p, 0) p
            , ifnull(q, 0) q
            , ifnull(p, 0) p
            , count
            , sampleSize
            , overallP
            , score
           -- , NeedsRecalculation.postId is not null as needsRecalculation

        from Score
        -- left join NeedsRecalculation using (postId)
        where 
            ifnull(Score.tagId = :tag_id, true)
            and ifnull(Score.postId = :post_id, true)
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
    insert_score_event(
        db::SQLite.DB,
        score::ScoreEvent,
    )::Nothing

Insert a `Score` instance into the score database.
"""
function insert_score_event(db::SQLite.DB, score::ScoreEvent)
    # result = SQLite.load!([score], db, "ScoreEvent")


    insert_score_event_sql = """
        insert into ScoreEvent(
              voteEventId
            , voteEventTime
            , tagId
            , parentId
            , postId
            , topNoteId
            , parentQ
            , parentP
            , q
            , p
            , count
            , sampleSize
            , overallP
            , score
        )
        values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        returning scoreEventId;

    """

    results = DBInterface.execute(
        db,
        insert_score_event_sql,
        (
            score.voteEventId,
            score.voteEventTime,
            score.tagId,
            score.parentId,
            score.postId,
            score.topNoteId,
            score.parentQ,
            score.parentP,
            score.q,
            score.p,
            score.count,
            score.sampleSize,
            score.overallP,
            score.score,
        ),
    )

    result = iterate(results)

    return result[1][:scoreEventId]
end


function set_last_processed_vote_event_id(db::SQLite.DB, vote_event_id::Int)
    DBInterface.execute(
        db,
        "update lastVoteEvent set processedVoteEventId = ?",
        [vote_event_id]
    )
end


function get_last_processed_vote_event_id(db::SQLite.DB)
    results = DBInterface.execute(db, "select processedVoteEventId from lastVoteEvent")
    r = iterate(results)
    return r[1][:processedVoteEventId]
end

function insert_vote_event(db::SQLite.DB, vote_event::VoteEvent)

    DBInterface.execute(
        db,
        """
            insert into VoteEventImport
            (
                  voteEventId
                , userId
                , tagId
                , parentId
                , postId
                , noteId
                , vote
                , createdAt
            )
            values (?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            vote_event.id,
            vote_event.user_id,
            vote_event.tag_id,
            vote_event.parent_id,
            vote_event.post_id,
            vote_event.note_id,
            vote_event.vote,
            vote_event.created_at
        )
    )
end


