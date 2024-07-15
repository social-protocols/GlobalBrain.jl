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

# This struct has no keyword constructor. The only constructor that should be used is the
# inner constructor provided in this struct that constructs TalliesTrees from SQLTalliesData.
struct TalliesTree
    tally::BernoulliTally
    post_id::Int
    needs_recalculation::Bool
    last_voted_post_id::Int
    children::Function
    conditional_tally::Function
    effect::Function # TODO: clarify (i.e., rename) what effects we are getting here and what we do with them

    function TalliesTree(t::SQLTalliesData)
        return new(
            t.tally,
            t.post_id,
            t.needs_recalculation,
            t.last_voted_post_id,
            () -> get_child_tallies_data(t.db, t.last_voted_post_id, t.post_id),
            (target_id) -> get_conditional_tally(t.db, target_id, t.post_id),
            (target_id) -> get_effect(t.db, target_id, t.post_id),
        )
    end
end

Base.@kwdef struct ConditionalTally
    post_id::Int
    comment_id::Int
    informed::Tally
    uninformed::Tally
end

# Effect has a keyword constructor so that it can be constructed from database rows.
# When constructing effects in calculations, it's usually better to use the constructor
# provided below, which derives the weight from the other attributes.
Base.@kwdef struct Effect
    post_id::Int64
    comment_id::Union{Int64,Nothing}
    p::Float64
    p_count::Int64
    p_size::Int64
    q::Float64
    q_count::Int64
    q_size::Int64
    r::Float64
    weight::Float64
end

function Effect(
    post_id::Int64,
    comment_id::Union{Int64,Nothing},
    p::Float64,
    q::Float64,
    r::Float64,
    conditional_tally::ConditionalTally,
)
    return Effect(
        post_id = post_id,
        comment_id = comment_id,
        p = p,
        p_count = conditional_tally.informed.count,
        p_size = conditional_tally.informed.size,
        q = q,
        q_count = conditional_tally.uninformed.count,
        q_size = conditional_tally.uninformed.size,
        r = r,
        weight = relative_entropy(p, q) * conditional_tally.informed.size, # weight is derived
    )
end

Base.convert( ::Type{NamedTuple}, e::Effect ) = NamedTuple{propertynames(e)}(e)

Base.@kwdef struct Score
    post_id::Int64
    o::Float64
    o_count::Int64
    o_size::Int64
    p::Float64
    score::Float64
end
