global preparedStatements = Dict{String,SQLite.Stmt}()

# Generic function to iterate over a SQLite query result and place results in
# a vector. It is often convenient by default to iterate over the results of
# a query, even if they are not needed, because to commit transactions there
# can not be any open SQL statement. But you can't just put each SQLite.Row into
# a vector (.e.g [row for row in result]) because the SQLite.Row object contains
# only a reference to the query, and not the actual data. You actually need to read
# the values out of the row and put them somewhere. The optional converter function
# takes a SQLite.Row and returns whatever data is required.
function collect_results(optional_converter::Union{Function,Nothing} = nothing)
    converter = !isnothing(optional_converter) ? optional_converter : x -> begin
        nothing
    end
    f = rows -> begin
        return [converter(row) for row in rows]
    end
    return f
end

function get_prepared_statement(db::SQLite.DB, stmt_key::String, sql_query::String)
    if !haskey(preparedStatements, stmt_key)
        preparedStatements[stmt_key] = DBInterface.prepare(db, sql_query)
    end
    return preparedStatements[stmt_key]
end

function sql_row_to_effect(row::SQLite.Row)::Effect
    Effect(
        post_id = row[:post_id],
        comment_id = row[:comment_id],
        p = row[:p],
        p_count = row[:p_count],
        q = row[:q],
        p_size = row[:p_size],
        q_count = row[:q_count],
        q_size = row[:q_size],
        r = row[:r],
        weight = row[:weight],
    )
end

function sql_row_to_score(row::SQLite.Row)::Score
    return Score(
        post_id = row[:post_id],
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
        parent_id = sql_missing_to_nothing(row[:parent_id]),
        post_id = row[:post_id],
        vote = row[:vote],
    )
end

function sql_missing_to_nothing(val::Any)
    return ismissing(val) ? nothing : val
end
