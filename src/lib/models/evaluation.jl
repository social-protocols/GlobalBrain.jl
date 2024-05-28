Base.@kwdef struct ConditionalTally
    post_id::Int
    note_id::Int
    informed::Tally
    uninformed::Tally
end

"""
    Effect

The effect of a note on a post, given by the upvote probabilities given the
note was shown and not shown respectively.

# Fields

    * `post_id::Int64`: The id of the post.
    * `note_id::Union{Int64, Nothing}`: The id of the note. If
    `nothing`, then this is the root post.
    * `uninformed_probability::Float64`: The probability of an upvote given the
    note was not shown.
    * `informed_probability::Float64`: The probability of an upvote given the
    note was shown.
"""
Base.@kwdef struct Effect
    post_id::Int64
    note_id::Union{Int64,Nothing}
    top_subthread_id::Union{Int64,Nothing}
    p::Float64
    p_count::Int64
    p_size::Int64
    q::Float64
    q_count::Int64
    q_size::Int64
    r::Float64
end


# TODO: improve documentation
"""
    Score

The data used to calculate the score of a post.
"""
Base.@kwdef struct Score
    post_id::Int64
    top_note_id::Union{Int64,Nothing}
    critical_thread_id::Union{Int64,Nothing}
    o::Float64
    o_count::Int64
    o_size::Int64
    p::Float64
    score::Float64
end
