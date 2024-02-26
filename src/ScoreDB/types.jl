"""
    SQLTalliesTree <: TalliesTree

A data structure to represent a tree of tallies stored in an SQLite database.
"""
struct SQLTalliesTree
    tally::GlobalBrain.DetailedTally
    needs_recalculation::Bool
    db::SQLite.DB
end


Base.@kwdef struct Score
    score_event_id::Union{Int,Nothing}
    vote_event_id::Int
    vote_event_time::Int
    tag_id::Int
    parent_id::Union{Int, Nothing}
    post_id::Int
    top_note_id::Union{Int,Nothing}
    parent_q::Union{Float64,Nothing}
    parent_p::Union{Float64,Nothing}
    q::Union{Float64,Nothing}
    p::Union{Float64,Nothing}
    count::Int
    sample_size::Int
    overall_p::Float64
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
