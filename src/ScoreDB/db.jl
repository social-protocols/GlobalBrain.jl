"""
    get_score_db(path::String)::SQLite.DB

Get a connection to the score database at the provided path. If the database does not
exist, it will be created.
"""
function get_score_db(database_path::String)::SQLite.DB
    if !isfile(database_path)
        init_score_db(database_path)
    end
    return SQLite.DB(database_path)
end

function init_score_db(database_path::String)
    @info "Initializing database at $database_path"
    Base.run(pipeline(`cat sql/tables.sql`, `sqlite3 $database_path`))
    Base.run(pipeline(`cat sql/views.sql`, `sqlite3 $database_path`))
    Base.run(pipeline(`cat sql/triggers.sql`, `sqlite3 $database_path`))
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
    ancestor_id::Union{Int, Nothing},
)::Vector{GlobalBrain.TalliesTree}
    sql_query = """
        select
            tag_id
            , ifnull(parent_id,0)    as parent_id
            , ifnull(ancestor_id,0) as ancestor_id
            , post_id                    as post_id
            , ifnull(parentCount, 0)   as parentCount
            , ifnull(parentTotal, 0)   as parentTotal
            , ifnull(uninformed_count, 0) as uninformed_count
            , ifnull(uninformed_total, 0) as uninformed_total
            , ifnull(informed_count, 0)   as informed_count
            , ifnull(informed_total, 0)   as informed_total
            , ifnull(selfCount, 0)       as selfCount
            , ifnull(selfTotal, 0)       as selfTotal
            , NeedsRecalculation.post_id is not null as needsRecalculation
        from DetailedTally 
        left join NeedsRecalculation using (post_id, tag_id)
        where 
            ifnull(tag_id = :tag_id, true)
            and ( 
                    :post_id = parent_id
                    or ( :post_id is null and parent_id is null )
                )
            and (
                :ancestor_id=ancestor_id 
                or ( :ancestor_id is null and ancestor_id is null )
            )
        """

    results = DBInterface.execute(db, sql_query, [tag_id, post_id, ancestor_id])

    return [
        SQLTalliesTree(to_detailed_tally(row), row[:needsRecalculation], db) |>
            as_tallies_tree
        for row in results
    ]
end


# function get_score_data(
#     db::SQLite.DB,
#     tag_id::Int,
#     post_id::Int,
# )
#     get_score_sql = """
#         select
#             Score.tag_id
#             , ifnull(Score.parent_id, 0) parent_id
#             , Score.post_id
#             , ifnull(top_note_id, 0) top_note_id
#             # , ifnull(p, 0) p
#             # , ifnull(q, 0) q
#             , upvote_probability
#             , count
#             , size
#             , score
#            -- , NeedsRecalculation.post_id is not null as needsRecalculation

#         from Score
#         -- left join NeedsRecalculation using (post_id)
#         where 
#             ifnull(Score.tag_id = :tag_id, true)
#             and ifnull(Score.post_id = :post_id, true)
#             -- Only return existing score data that is not out of date.
#             -- and not needsRecalculation

#     """

#     results = DBInterface.execute(db, get_score_sql, [tag_id, post_id])

#     r = iterate(results)

#     if isnothing(r) 
#         return nothing
#     end

#     # if isnothing(r[1])
#     #     println("No result in get_score_data")
#     #     return nothing
#     # end

#     # println("Got existing score data for post $post_id")

#     return to_score_event(r[1])
# end


function get_effect(
    db::SQLite.DB,
    tag_id::Int,
    post_id::Int,
    note_id::Int
)

    sql = """
        select
            *
        from effect
        where 
            tag_id = :tag_id
            and post_id = :post_id
            and note_id = :note_id
    """

    results = DBInterface.execute(db, sql, [tag_id, post_id, note_id])

    r = iterate(results)

    if isnothing(r)
        throw("Missing effect record for $tag_id, $post_id, $note_id")
    end

    return to_effect_event(r[1]).effect
end



function as_tallies_tree(t::SQLTalliesTree)
    return GlobalBrain.TalliesTree(
        # (ancestor_id) -> get_tallies(t.db, t.tally.tag_id, t.tally.post_id, ancestor_id),
        (ancestor_id) -> get_tallies(t.db, t.tally.tag_id, t.tally.post_id, t.tally.post_id),
        () -> t.tally,
        () -> t.needs_recalculation,
        () -> get_effect(t.db, t.tally.tag_id, t.tally.parent_id, t.tally.post_id),
    )
end




"""
    insert_score_event(
        db::SQLite.DB,
        score::Score,
    )::Nothing

Insert a `Score` instance into the score database.
"""
function insert_score_event(db::SQLite.DB, score_event::ScoreEvent)
    sql = """
        insert into ScoreEvent(
              vote_event_id
            , vote_event_time
            , tag_id
            -- , parent_id
            , post_id
            , top_note_id
            -- , p
            -- , q
            , o
            , o_count
            , o_size
            , p
            , score
        )
        values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        on conflict do nothing
    """

    score = score_event.score
    DBInterface.execute(
        db,
        sql,
        (
            score_event.vote_event_id,
            score_event.vote_event_time,
            score.tag_id,
            # score.parent_id,
            score.post_id,
            score.top_note_id,
            score.o,
            score.o_count,
            score.o_size,
            score.p,
            score.score,
        ),
    )
end


function insert_effect_event(db::SQLite.DB, effect_event::EffectEvent)
    sql = """
        insert into EffectEvent(
              vote_event_id
            , vote_event_time
            , tag_id
            , post_id
            , note_id
            , p
            , p_count
            , p_size
            , q
            , q_count
            , q_size
        )
        values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        on conflict do nothing

    """

    effect = effect_event.effect
    DBInterface.execute(
        db,
        sql,
        (
            effect_event.vote_event_id,
            effect_event.vote_event_time,
            effect.tag_id,
            effect.post_id,
            effect.note_id,
            effect.p,
            effect.p_count,
            effect.p_size,
            effect.q,
            effect.q_count,
            effect.q_size
        ),
    )
end


function insert_event(db::SQLite.DB, event::EffectEvent)
    insert_effect_event(db, event)
end


function insert_event(db::SQLite.DB, event::ScoreEvent)
    insert_score_event(db, event)
end


function set_last_processed_vote_event_id(db::SQLite.DB, vote_event_id::Int)
    DBInterface.execute(
        db,
        "update lastVoteEvent set processed_vote_event_id = ?",
        [vote_event_id]
    )
end


function get_last_processed_vote_event_id(db::SQLite.DB)
    results = DBInterface.execute(db, "select processed_vote_event_id from lastVoteEvent")
    r = iterate(results)
    return r[1][:processed_vote_event_id]
end

function insert_vote_event(db::SQLite.DB, vote_event::VoteEvent)
    DBInterface.execute(
        db,
        """
            insert into VoteEventImport
            (
                  vote_event_id
                , vote_event_time
                , user_id
                , tag_id
                , parent_id
                , post_id
                , note_id
                , vote
            )
            values (?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            vote_event.vote_event_id,
            vote_event.vote_event_time,
            vote_event.user_id,
            vote_event.tag_id,
            vote_event.parent_id,
            vote_event.post_id,
            vote_event.note_id,
            vote_event.vote,
        )
    )
end
