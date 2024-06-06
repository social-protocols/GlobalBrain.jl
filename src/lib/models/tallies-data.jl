Base.@kwdef struct TalliesData
    tally::Function
    conditional_tally::Function
    effect::Function
    children::Function
    needs_recalculation::Bool
    post_id::Int
    last_voted_post_id::Int
end


"""
    SQLTalliesData <: TalliesData

A data structure to represent a tree of tallies stored in an SQLite database.
"""
Base.@kwdef struct SQLTalliesData
    tally::BernoulliTally
    post_id::Int64
    needs_recalculation::Bool
    last_voted_post_id::Int64
    db::SQLite.DB
end


function TalliesData(t::SQLTalliesData)
    return TalliesData(
        () -> t.tally,
        (target_id) -> get_conditional_tally(t.db, target_id, t.post_id),
        (target_id) -> get_effect(t.db, target_id, t.post_id),
        () -> get_child_tallies_data(t.db, t.last_voted_post_id, t.post_id),
        t.needs_recalculation,
        t.post_id,
        t.last_voted_post_id,
    )
end
