using DataFrames

"""
    init_score_db(database_path::String)

Create a SQLite database with the schema required to run the Global Brain
service at the provided path if it doesn't already exist.
"""
function init_score_db(database_path::String)
    if isfile(database_path)
        @warn "Database already exists at $database_path"
        return
    end

    db = SQLite.DB(database_path)

    results = DBInterface.execute(db, "PRAGMA journal_mode=WAL;") |> DataFrame

    SQLite.transaction(db) do
        create_tables(db)
        create_views(db)
        create_triggers(db)
        @info "Score database successfully initialized at $database_path"

    end

    return db

end


"""
    get_score_db(database_path::String)::SQLite.DB

Get a connection to the score database at the provided path. If the database does not
exist, it will be created.
"""
function get_score_db(database_path::String)::SQLite.DB
    if !isfile(database_path)
        return init_score_db(database_path)
    end
    return SQLite.DB(database_path)
end


function get_tallies_data(
    db::SQLite.DB,
    tag_id::Int,
    parent_id::Union{Int,Nothing},
)::Vector{TalliesData}
    sql_query = """
        select
            Tally.*
            , NeedsRecalculation.post_id is not null as needs_recalculation
        from Tally
        left join NeedsRecalculation using (post_id, tag_id)
    where
        tally.tag_id = :tag_id
        and
            (:parent_id = parent_id)
            or
            (:parent_id is null and parent_id is null)
    """

    results = DBInterface.execute(db, sql_query, [tag_id, parent_id])

    return [
        TalliesData(
            SQLTalliesData(
                tally = BernoulliTally(row[:count], row[:total]),
                tag_id = tag_id,
                post_id = row[:post_id],
                needs_recalculation = row[:needs_recalculation],
                db = db,
            ),
        ) for row in results
    ]
end

function get_conditional_tally(
    db::SQLite.DB,
    tag_id::Int,
    post_id::Int,
    note_id::Int,
)::ConditionalTally
    sql_query = """
        select
            *
        from ConditionalTally 
        where 
            post_id = :post_id
            and note_id = :note_id
            and tag_id = :tag_id
        """

    results = DBInterface.execute(db, sql_query, [post_id, note_id, tag_id]) |> DataFrame

    if nrow(results) == 0
        return ConditionalTally(
            tag_id = tag_id,
            post_id = post_id,
            note_id = note_id,
            informed = BernoulliTally(0, 0),
            uninformed = BernoulliTally(0, 0),
        )
    end

    r = first(results)

    return ConditionalTally(
        tag_id = r[:tag_id],
        post_id = r[:post_id],
        note_id = r[:note_id],
        informed = BernoulliTally(r[:informed_count], r[:informed_total]),
        uninformed = BernoulliTally(r[:uninformed_count], r[:uninformed_total]),
    )
end

function get_effect(db::SQLite.DB, tag_id::Int, post_id::Int, note_id::Int)

    sql = """
        select
            *,
            ifnull(top_subthread_id, 0) as top_subthread_id
        from effect
        where 
            tag_id = :tag_id
            and post_id = :post_id
            and note_id = :note_id
    """

    results = DBInterface.execute(db, sql, [tag_id, post_id, note_id]) |> DataFrame

    if nrow(results) == 0
        throw("Missing effect record for $tag_id, $post_id, $note_id")
    end

    r = first(results)

    return sql_row_to_effect_event(r).effect
end

"""
    insert_score_event(
        db::SQLite.DB,
        score_event::ScoreEvent,
    )::Nothing

Insert a `ScoreEvent` instance into the score database.
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
            , critical_thread_id
            -- , p
            -- , q
            , o
            , o_count
            , o_size
            , p
            , score
        )
        values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
            score.critical_thread_id,
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
            , top_subthread_id
            , p
            , p_count
            , p_size
            , q
            , q_count
            , q_size
            , r
        )
        values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
            effect.top_subthread_id,
            effect.p,
            effect.p_count,
            effect.p_size,
            effect.q,
            effect.q_count,
            effect.q_size,
            effect.r,
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
        [vote_event_id],
    )
end


function get_last_processed_vote_event_id(db::SQLite.DB)
    results = DBInterface.execute(db, "select processed_vote_event_id from lastVoteEvent") |> DataFrame
    return first(results)[:processed_vote_event_id]
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
        ),
    )
end

using DataFrames
function sql_row_to_effect_event(row::DataFrames.DataFrameRow{DataFrames.DataFrame, DataFrames.Index})::EffectEvent
    return EffectEvent(
        vote_event_id = row[:vote_event_id],
        vote_event_time = row[:vote_event_time],
        effect = Effect(
            tag_id = row[:tag_id],
            post_id = row[:post_id],
            note_id = row[:note_id],
            top_subthread_id = ismissing(row[:top_subthread_id]) ? nothing : row[:top_subthread_id],
            p = row[:p],
            p_count = row[:p_count],
            q = row[:q],
            p_size = row[:p_size],
            q_count = row[:q_count],
            q_size = row[:q_size],
            r = row[:r],
        ),
    )
end


function sql_row_to_score(row::SQLite.Row)::Score
    return Score(
        tag_id = row[:tag_id],
        post_id = row[:post_id],
        top_note_id = sql_missing_to_nothing(row[:top_note_id]),
        critical_thread_id = sql_missing_to_nothing(row[:critical_thread_id]),
        o = row[:o],
        o_count = row[:o_count],
        o_size = row[:o_size],
        p = row[:p],
        score = row[:score],
    )
end


function sql_missing_to_nothing(val::Any)
    return ismissing(val) ? nothing : val
end


function get_or_insert_tag_id(db::SQLite.DB, tag::String)

    results = DBInterface.execute(
        db,
        "insert into tag(tag) values (?) on conflict do nothing returning id",
        [tag],
    ) |> DataFrame

    if nrow(results) == 0
        error("Failed to get/insert tag $tag")
    end

    result = first(results)

    return result[:id]
end
