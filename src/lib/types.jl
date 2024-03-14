"""
    Post

A post in a discussion thread. If `parent` is `nothing`, then this post is the
root of the thread.

# Fields

    * `id::Int64`: The id of the post.
    * `parent::Union{Int64, Nothing}`: The id of the parent post.
    * `timestamp::Int64`: The time at which the post was created.
"""
Base.@kwdef struct Post
    id::Int64
    parent::Union{Int64,Nothing}
    timestamp::Int64
end

"""
    Model

Abstract type for a probabilistic model.
"""
abstract type Model end


"""
    BetaBernoulli <: Model

Abstract type for a Beta-Bernoulli model.

See also [`Model`](@ref).
"""
abstract type BetaBernoulli <: Model end


"""
    GammaPoisson <: Model

Abstract type for a Gamma-Poisson model.

See also [`Model`](@ref).
"""
abstract type GammaPoisson <: Model end


"""
    Tally{T <: Model}

A tally for a given model. We count "successes" in trials, thus size
must be greater or equal to count.

# Fields

    * `count::Int`: The number of positive outcomes in the sample.
    * `size::Int`: The total number of outcomes in the sample.

See also [`Model`](@ref).
"""
struct Tally{T<:Model}
    count::Int
    size::Int
    function Tally{T}(count::Int, size::Int) where {T}
        @assert(count >= 0, "count cannot be smaller than 0")
        @assert(size >= count, "size cannot be smaller than count")
        new{T}(count, size)
    end
end


"""
    Distribution{T <: Model}

A distribution for a given model, parameterized by mean and weight.

See also [`Model`](@ref).
"""
struct Distribution{T<:Model}
    mean::Float64
    weight::Float64
end


"""
    BernoulliTally

Short-hand for `Tally{BetaBernoulli}`.

See also [`Tally`](@ref), [`Model`](@ref).
"""
const BernoulliTally = Tally{BetaBernoulli}


"""
    BetaDistribution

Short-hand for `Distribution{BetaBernoulli}`.

See also [`Distribution`](@ref), [`Model`](@ref).
"""
const BetaDistribution = Distribution{BetaBernoulli}


"""
    alpha(dist::BetaDistribution)::Float64

Get the alpha parameter of a Beta distribution.

See also [`BetaDistribution`](@ref), [`beta`](@ref).
"""
alpha(dist::BetaDistribution)::Float64 = dist.mean * dist.weight


"""
    beta(dist::BetaDistribution)::Float64

Get the beta parameter of a Beta distribution.

See also [`BetaDistribution`](@ref), [`alpha`](@ref).
"""
beta(dist::BetaDistribution)::Float64 = (1 - dist.mean) * dist.weight


"""
    PoissonTally

Short-hand for `Tally{GammaPoisson}`.

See also [`Tally`](@ref), [`Model`](@ref).
"""
const PoissonTally = Tally{GammaPoisson}


"""
    GammaDistribution

Short-hand for `Distribution{GammaPoisson}`.

See also [`Distribution`](@ref), [`Model`](@ref).
"""
const GammaDistribution = Distribution{GammaPoisson}


"""
    DetailedTally

All tallies for a post.

# Fields

    * `tag_id::Int64`: The tag id.
    * `parent_id::Union{Int64, Nothing}`: The id of the parent
    of this post if any.
    * `post_id::Int64`: The id of this post.
    * `parent::BernoulliTally`: The current tally tally for the **parent of
    this post**
    * `uninformed::BernoulliTally`: The tally for the **parent of this post**
    given user was not informed of this note.
    * `informed::BernoulliTally`: The tally for the **parent of this post**
    given user was informed of this note.
    * `overall::BernoulliTally`: The current tally for this post.
"""
Base.@kwdef struct DetailedTally
    tag_id::Int64
    ancestor_id::Union{Int64,Nothing}
    parent_id::Union{Int64,Nothing}
    post_id::Int64
    parent::BernoulliTally
    informed::BernoulliTally
    uninformed::BernoulliTally
    overall::BernoulliTally
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
    tag_id::Int64
    post_id::Int64
    note_id::Union{Int64,Nothing}
    p::Float64
    p_count::Int64
    p_size::Int64
    q::Float64
    q_count::Int64
    q_size::Int64
end


# TODO: improve documentation
"""
    Score

The data used to calculate the score of a post.
"""
Base.@kwdef struct Score
    tag_id::Int64
    post_id::Int64
    top_note_id::Union{Int64,Nothing}
    o::Float64
    o_count::Int64
    o_size::Int64
    p::Float64
    score::Float64
end

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
