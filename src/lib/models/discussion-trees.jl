Base.@kwdef struct TalliesTree
    children::Function
    tally::Function
    needs_recalculation::Function
    effect::Function
end


struct InMemoryTree
    tally::DetailedTally
    children::Vector{InMemoryTree}
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


function TalliesTree(t::InMemoryTree)
    return TalliesTree(
        (ancestor_id) -> map((c) -> TalliesTree(c), t.children),
        () -> t.tally,
        () -> true,
        (ancestor_id) -> nothing,
    )
end
