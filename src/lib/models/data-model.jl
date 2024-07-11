Base.@kwdef struct TalliesData
    # TODO: Can we add type signatures for the functions here?
    # TODO if not, add comments with required signatures
    tally::Function
    conditional_tally::Function
    effect::Function # TODO: clarify (i.e., rename) what effects we are getting here and what we do with them
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
        () -> t.tally, # TODO: probably not necessary, we can just use the tally here
        (target_id) -> get_conditional_tally(t.db, target_id, t.post_id),
        (target_id) -> get_effect(t.db, target_id, t.post_id),
        () -> get_child_tallies_data(t.db, t.last_voted_post_id, t.post_id),
        t.needs_recalculation,
        t.post_id,
        t.last_voted_post_id,
    )
end

Base.@kwdef struct ConditionalTally
    post_id::Int
    comment_id::Int
    informed::Tally
    uninformed::Tally
end

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

Base.convert( ::Type{NamedTuple}, e::Effect ) = NamedTuple{propertynames(e)}(e)

Base.@kwdef struct Score
    post_id::Int64
    o::Float64
    o_count::Int64
    o_size::Int64
    p::Float64
    score::Float64
end
