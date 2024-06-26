Base.@kwdef struct VoteEvent
    vote_event_id::Int
    vote_event_time::Int
    user_id::String
    parent_id::Union{Int,Nothing}
    post_id::Int64
    vote::Int
end


Base.@kwdef struct EffectEvent
    vote_event_id::Int
    vote_event_time::Int
    effect::Effect
    function EffectEvent(vote_event_id::Int, vote_event_time::Int, effect::Effect)
        return new(vote_event_id, vote_event_time, round_float_fields(effect))
    end
end


Base.@kwdef struct ScoreEvent
    vote_event_id::Int
    vote_event_time::Int
    score::Score
    function ScoreEvent(vote_event_id::Int, vote_event_time::Int, score::Score)
        return new(vote_event_id, vote_event_time, round_float_fields(score))
    end
end


function as_event(vote_event_id::Int, vote_event_time::Int, e::Effect)
    return EffectEvent(vote_event_id, vote_event_time, e)
end

function as_event(vote_event_id::Int, vote_event_time::Int, e::Score)
    return ScoreEvent(vote_event_id, vote_event_time, e)
end


# This function works for structs with keyword constructors
function round_float_fields(s::T) where {T}
    struct_type = typeof(s)
    new_fields = Dict{Symbol,Any}()
    for field in fieldnames(struct_type)
        field_value = getfield(s, field)
        if field_value isa Float64
            new_fields[field] = round(field_value, digits = 4)
        else
            new_fields[field] = field_value
        end
    end
    return struct_type(; new_fields...)
end

# Tell Tables.jl that it can access rows in the array
# Tables.rowaccess(::Type{Vector{Score}}) = true

# # Tell Tables.jl how to get the rows from the array
# Tables.rows(x::Vector{Score}) = x
