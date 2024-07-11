function get_root_tallies_data(db::SQLite.DB, last_voted_post_id::Int)::Vector{TalliesData}
    stmt = get_prepared_statement(
        db,
        "get_root_tallies_data",
        """
        -- get the root ancestor for last voted post id
        -- the last voted post id might be a root node.
        select
            Tally.*
            , true as needs_recalculation
        from Tally
        left join lineage on
            (:last_voted_post_id != tally.post_id) -- not strictly necessary, but avoids join in this case
            and ancestor_id = Tally.post_id
            and descendant_id = :last_voted_post_id
        left join Post parent on
            tally.parent_id = parent.id
        where
            (lineage.ancestor_id is not null or :last_voted_post_id = tally.post_id)
            -- the root of the tallies tree that we pass to the algorithm is an ancestor of the post that was voted on
            -- (or the post itself) that either:
            --
            -- 1) has no parent (parent_id is null)
            -- 2) it has a parent (parent_id is not null), but we don't have the parent in the post table, because there has never been a vote on the parent.
            and parent.id is null
        ;
        """,
    )

    results = DBInterface.execute(stmt, [last_voted_post_id])

    return [
        TalliesData(
            SQLTalliesData(
                tally = BernoulliTally(row[:count], row[:total]),
                post_id = row[:post_id],
                needs_recalculation = row[:needs_recalculation],
                last_voted_post_id = last_voted_post_id,
                db = db,
            ),
        ) for row in results
    ]
end


function get_child_tallies_data(
    db::SQLite.DB,
    last_voted_post_id::Int,
    parent_id::Int,
)::Vector{TalliesData}
    stmt = get_prepared_statement(
        db,
        "get_child_tallies_data",
        """
        select
            Tally.*
            , lineage.descendant_id is not null or :last_voted_post_id == Tally.post_id as needs_recalculation
        from Tally
        left join lineage
            on ancestor_id = Tally.post_id and :last_voted_post_id = descendant_id
            or descendant_id = Tally.post_id and :last_voted_post_id = ancestor_id
        where
            (parent_id is :parent_id)
        ;
        """,
    )

    results = DBInterface.execute(stmt, [last_voted_post_id, parent_id])

    return [
        TalliesData(
            SQLTalliesData(
                tally = BernoulliTally(row[:count], row[:total]),
                post_id = row[:post_id],
                needs_recalculation = row[:needs_recalculation],
                last_voted_post_id = last_voted_post_id,
                db = db,
            ),
        ) for row in results
    ]
end

function get_conditional_tally(
    db::SQLite.DB,
    post_id::Int,
    comment_id::Int,
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
            and comment_id = :comment_id
        """,
    )

    results = DBInterface.execute(stmt, [post_id, comment_id]) |> collect_results(
        r -> ConditionalTally(
            post_id = r[:post_id],
            comment_id = r[:comment_id],
            informed = BernoulliTally(r[:informed_count], r[:informed_total]),
            uninformed = BernoulliTally(r[:uninformed_count], r[:uninformed_total]),
        )
    )

    if length(results) == 0
        return ConditionalTally(
            post_id = post_id,
            comment_id = comment_id,
            informed = BernoulliTally(0, 0),
            uninformed = BernoulliTally(0, 0),
        )
    end

    return first(results)
end

function get_effect(db::SQLite.DB, post_id::Int, comment_id::Int)::Effect
    stmt = get_prepared_statement(
        db,
        "get_effect",
        """
        select
            *
        from effect
        where
            post_id = :post_id
            and comment_id = :comment_id
        """,
    )

    results =
        DBInterface.execute(stmt, [post_id, comment_id]) |>
        collect_results(sql_row_to_effect)

    if length(results) == 0
        throw("Missing effect record for $post_id, $comment_id")
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
            -- , parent_id
            , post_id
            -- , p
            -- , q
            , o
            , o_count
            , o_size
            , p
            , score
        )
        values (?, ?, ?, ?, ?, ?, ?, ?)
        on conflict do nothing
        """,
    )

    score = score_event.score
    DBInterface.execute(
        stmt,
        (
            score_event.vote_event_id,
            score_event.vote_event_time,
            score.post_id,
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
            , post_id
            , comment_id
            , p
            , p_count
            , p_size
            , q
            , q_count
            , q_size
            , r
            , weight
        )
        values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        on conflict do nothing
        """,
    )

    effect = effect_event.effect
    DBInterface.execute(
        stmt,
        (
            effect_event.vote_event_id,
            effect_event.vote_event_time,
            effect.post_id,
            effect.comment_id,
            effect.p,
            effect.p_count,
            effect.p_size,
            effect.q,
            effect.q_count,
            effect.q_size,
            effect.r,
            effect.weight,
        ),
    )
end

function insert_event(db::SQLite.DB, event::EffectEvent)
    insert_effect_event(db, event)
end

function insert_event(db::SQLite.DB, event::ScoreEvent)
    insert_score_event(db, event)
end

function get_last_vote_event_id(db::SQLite.DB)
    stmt = get_prepared_statement(
        db,
        "get_last_vote_event_id",
        "select vote_event_id from LastVoteEvent",
    )
    results = DBInterface.execute(stmt) |> collect_results(row -> row[:vote_event_id])
    return first(results)
end

function insert_vote_event(db::SQLite.DB, vote_event::VoteEvent)
    stmt = get_prepared_statement(
        db,
        "insert_vote_event",
        """
            insert into VoteEventImport
            (
                  vote_event_id
                , vote_event_time
                , user_id
                , parent_id
                , post_id
                , vote
            )
            values (?, ?, ?, ?, ?, ?)
        """,
    )
    DBInterface.execute(
        stmt,
        (
            vote_event.vote_event_id,
            vote_event.vote_event_time,
            vote_event.user_id,
            vote_event.parent_id,
            vote_event.post_id,
            vote_event.vote,
        ),
    )
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
        """,
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
        """,
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
        """,
    )

    results =
        DBInterface.execute(stmt, [vote_event_id]) |> collect_results(sql_row_to_vote_event)

    if length(results) == 0
        throw("Missing vote event for vote_event_id=$(vote_event_id)")
    end

    return first(results)
end
