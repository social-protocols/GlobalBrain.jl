Base.@kwdef struct TalliesData
    tally::Function
    conditional_tally::Function
    effect::Function
    children::Function
    needs_recalculation::Bool
    tag_id::Int
    post_id::Int
end


"""
    SQLTalliesData <: TalliesData

A data structure to represent a tree of tallies stored in an SQLite database.
"""
Base.@kwdef struct SQLTalliesData
    tally::BernoulliTally
    tag_id::Int64
    post_id::Int64
    needs_recalculation::Bool
    db::SQLite.DB
end


function TalliesData(t::SQLTalliesData)
    return TalliesData(
        () -> t.tally,
        (target_id) -> get_conditional_tally(t.db, t.tag_id, target_id, t.post_id),
        (target_id) -> get_effect(t.db, t.tag_id, target_id, t.post_id),
        () -> get_tallies_data(t.db, t.tag_id, t.post_id),
        t.needs_recalculation,
        t.tag_id,
        t.post_id,
    )
end
