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
