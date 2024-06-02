global preparedStatements = Dict{String, SQLite.Stmt}()

# Generic function to iterate over a SQLite query result and place results in
# a vector. It is often convenient by default to iterate over the results of
# a query, even if they are not needed, because to commit transactions there
# can not be any open SQL statement. But you can't just put each SQLite.Row into
# a vector (.e.g [row for row in result]) because the SQLite.Row object contains
# only a reference to the query, and not the actual data. You actually need to read
# the values out of the row and put them somewhere. The optional converter function
# takes a SQLite.Row and returns whatever data is required.
function collect_results(optional_converter::Union{Function, Nothing} =
nothing)

    converter = !isnothing(optional_converter) ? optional_converter : x -> begin
        nothing
    end 

    f = rows -> begin
        return [converter(row) for row in rows]
    end

    return f

end

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

    DBInterface.execute(db, "PRAGMA journal_mode=WAL;") |> collect_results()

    SQLite.transaction(db) do
        create_tables(db)
        create_views(db)
        create_triggers(db)
        @info "Score database successfully initialized at $database_path"
    end

    return db
end


function get_score_db(database_path::String)::SQLite.DB
    if !isfile(database_path)
        return init_score_db(database_path)
    end
    return SQLite.DB(database_path)
end


function get_prepared_statement(db::SQLite.DB, stmt_key::String, sql_query::String)
    if !haskey(preparedStatements, stmt_key)
        preparedStatements[stmt_key] = DBInterface.prepare(
            db,
            sql_query
        )
    end
    return preparedStatements[stmt_key]
end


function get_tallies_data(
    db::SQLite.DB,
    tag_id::Int,
    parent_id::Union{Int,Nothing},
)::Vector{TalliesData}

    stmt = get_prepared_statement(
        db,
        "get_tallies_data",
        """
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
    )

    results = DBInterface.execute(stmt, [tag_id, parent_id])

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

    stmt = get_prepared_statement(
        db,
        "get_conditional_tally",
        """
        select
            *
        from ConditionalTally 
        where
            post_id = :post_id
            and note_id = :note_id
            and tag_id = :tag_id
        """
    )

    results = DBInterface.execute(stmt, [post_id, note_id, tag_id]) |> collect_results(r -> begin
        ConditionalTally(
            tag_id = r[:tag_id],
            post_id = r[:post_id],
            note_id = r[:note_id],
            informed = BernoulliTally(r[:informed_count], r[:informed_total]),
            uninformed = BernoulliTally(r[:uninformed_count], r[:uninformed_total]),
        )
    end)

    if length(results) == 0
        return ConditionalTally(
            tag_id = tag_id,
            post_id = post_id,
            note_id = note_id,
            informed = BernoulliTally(0, 0),
            uninformed = BernoulliTally(0, 0),
        )
    end

    return first(results)

end


function get_effect(db::SQLite.DB, tag_id::Int, post_id::Int, note_id::Int)::Effect

    stmt = get_prepared_statement(
        db,
        "get_effect",
        """
        select
            *
        from effect
        where
            tag_id = :tag_id
            and post_id = :post_id
            and note_id = :note_id
        """
    )

    results = DBInterface.execute(stmt, [tag_id, post_id, note_id]) |> collect_results(sql_row_to_effect)

    if length(results) == 0
        throw("Missing effect record for $tag_id, $post_id, $note_id")
    end

    return first(results)
end


function insert_score_event(db::SQLite.DB, score_event::ScoreEvent)
    stmt = get_prepared_statement(
        db,
        "insert_score_event",
        """
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
    )

    score = score_event.score
    DBInterface.execute(
        stmt,
        (
            score_event.vote_event_id,
            score_event.vote_event_time,
            score.tag_id,
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
    stmt = get_prepared_statement(
        db,
        "insert_effect_event",
        """
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
    )

    effect = effect_event.effect
    DBInterface.execute(
        stmt,
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
    stmt = get_prepared_statement(
        db,
        "set_last_processed_vote_event_id",
        "update lastVoteEvent set processed_vote_event_id = ?",
    )
    DBInterface.execute(
        stmt,
        [vote_event_id],
    )
end


function get_last_processed_vote_event_id(db::SQLite.DB)
    stmt = get_prepared_statement(
        db,
        "get_last_processed_vote_event_id",
        "select processed_vote_event_id from lastVoteEvent",
    )

    results = DBInterface.execute(stmt) |> collect_results(row -> begin
        row[:processed_vote_event_id]
    end)

    return first(results)
end

function insert_vote_event(db::SQLite.DB, vote_event::VoteEvent)
    stmt = get_prepared_statement(
        db,
        "insert_vote_event",
        """
            insert into VoteEvent
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
        """
    )

    DBInterface.execute(
        stmt,
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

function sql_row_to_effect(row::SQLite.Row)::Effect
    Effect(
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


function sql_row_to_vote_event(row::SQLite.Row)::VoteEvent
    return VoteEvent(
        vote_event_id = row[:vote_event_id],
        vote_event_time = row[:vote_event_time],
        user_id = row[:user_id],
        tag_id = row[:tag_id],
        parent_id = sql_missing_to_nothing(row[:parent_id]),
        post_id = row[:post_id],
        note_id = sql_missing_to_nothing(row[:note_id]),
        vote = row[:vote],
    )
end

function sql_missing_to_nothing(val::Any)
    return ismissing(val) ? nothing : val
end

function get_effects_for_vote_event(db::SQLite.DB, vote_event_id::Number)::Vector{Effect}

    stmt = get_prepared_statement(
        db,
        "get_effects_for_vote_event",
        """
        select
            *
        from EffectEvent
        where
            vote_event_id = :vote_event_Id
        """
    )

    return DBInterface.execute(stmt, [vote_event_id]) |> collect_results(sql_row_to_effect)
end


function get_scores_for_vote_event(db::SQLite.DB, vote_event_id::Number)::Vector{Score}

    stmt = get_prepared_statement(
        db,
        "get_scores_for_vote_event",
        """
        select
            *
        from ScoreEvent
        where
            vote_event_id = :vote_event_Id
        """
    )

    return DBInterface.execute(stmt, [vote_event_id]) |> collect_results(sql_row_to_score)
end

function get_vote_event(db::SQLite.DB, vote_event_id::Int)::VoteEvent

    stmt = get_prepared_statement(
        db,
        "get_vote_event",
        """
        select 
            *
        from VoteEvent
        where
            vote_event_id = :vote_event_id
        """
    )

    results = DBInterface.execute(stmt, [vote_event_id]) |> collect_results(sql_row_to_vote_event)

    if length(results) == 0
        throw("Missing vote event for vote_event_id=$(vote_event_id)")
    end

    return first(results)
end
