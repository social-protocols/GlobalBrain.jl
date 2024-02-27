"""
    SQLTalliesTree <: TalliesTree

A data structure to represent a tree of tallies stored in an SQLite database.
"""
struct SQLTalliesTree
    tally::GlobalBrain.DetailedTally
    needs_recalculation::Bool
    db::SQLite.DB
end


Base.@kwdef struct ScoreEvent
    scoreEventId::Union{Int,Nothing}
    voteEventId::Int
    voteEventTime::Int
    tagId::Int
    parentId::Union{Int, Nothing}
    postId::Int
    topNoteId::Union{Int,Nothing}
    parentQ::Union{Float64,Nothing}
    parentP::Union{Float64,Nothing}
    q::Union{Float64,Nothing}
    p::Union{Float64,Nothing}
    count::Int
    sampleSize::Int
    overallP::Float64
    score::Float64
end


# Tell Tables.jl that it can access rows in the array
# Tables.rowaccess(::Type{Vector{Score}}) = true

# # Tell Tables.jl how to get the rows from the array
# Tables.rows(x::Vector{Score}) = x


Base.@kwdef struct VoteEvent
    id::Int
    user_id::String
    tag_id::Int
    parent_id::Union{Int, Nothing}
    post_id::Int
    note_id::Union{Int, Nothing}
    vote::Int
    created_at::Int
end
