"""
    SQLTalliesTree <: TalliesTree

A data structure to represent a tree of tallies stored in an SQLite database.
"""
struct SQLTalliesTree
    tally::GlobalBrain.DetailedTally
    needs_recalculation::Bool
    db::SQLite.DB
end


struct ScoreDataRecord
    tagId::Int
    parentId::Union{Int, Nothing}
    postId::Int
    topNoteId::Union{Int,Nothing}
    parentUninformedP::Union{Float64,Nothing}
    parentInformedP::Union{Float64,Nothing}
    uninformedP::Union{Float64,Nothing}
    informedP::Union{Float64,Nothing}
    count::Int
    total::Int
    selfP::Float64
    updatedAt::Int
end


# Tell Tables.jl that it can access rows in the array
Tables.rowaccess(::Type{Vector{ScoreDataRecord}}) = true

# Tell Tables.jl how to get the rows from the array
Tables.rows(x::Vector{ScoreDataRecord}) = x
