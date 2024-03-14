"""
    update(prior::BetaDistribution, new_data::BernoulliTally)::BetaDistribution

Update a `BetaDistribution` with a `BernoulliTally`.

# Parameters

    * `prior::BetaDistribution`: The prior distribution.
    * `new_data::BernoulliTally`: New data to update the distribution with.

See also [`BetaDistribution`](@ref), [`BernoulliTally`](@ref).
"""
function update(prior::BetaDistribution, new_data::BernoulliTally)::BetaDistribution
    return BetaDistribution(
        bayesian_avg(prior, new_data),
        prior.weight + new_data.size,
    )
end


"""
    update(prior::GammaDistribution, new_data::PoissonTally)::GammaDistribution

Update a `GammaDistribution` with a `PoissonTally`.

# Parameters

    * `prior::GammaDistribution`: The prior distribution.
    * `new_data::PoissonTally`: New data to update the distribution with.

See also [`GammaDistribution`](@ref), [`PoissonTally`](@ref).
"""
function update(prior::GammaDistribution, new_data::PoissonTally)::GammaDistribution
    return GammaDistribution(
        bayesian_avg(prior, new_data),
        prior.weight + new_data.size,
    )
end


"""
    bayesian_avg(prior::Distribution, new_data::Tally)::Float64

Calculate the Bayesian average of a distribution with new data.

# Parameters

    * `prior::Distribution`: The prior distribution.
    * `new_data::Tally`: New data to update the distribution with.

See also [`Distribution`](@ref), [`Tally`](@ref).
"""
function bayesian_avg(prior::Distribution, new_data::Tally)::Float64
    return (
        (prior.mean * prior.weight + new_data.count) /
        (prior.weight + new_data.size)
    )
end


"""
    reset_weight(dist::Distribution, new_weight::Float64)::Distribution

Reset the weight of a distribution.

# Parameters

    * `dist::Distribution`: The distribution to reset the weight of.
    * `new_weight::Float64`: The new weight.

# Rationale

When we update an "uninformed" distribution with new "informed" data, the
weight needs to be reset because the prior distribution is the posterior
distribution of a previous update. Since we now get new information which
wasn't available at the time of the previous update, we need to reset the
weight.

See also [`Distribution`](@ref).
"""
function reset_weight(dist::Distribution, new_weight::Float64)
    T = typeof(dist)
    return T(dist.mean, new_weight)
end


"""
    sample(dist::BetaDistribution)::Float64

Draw a random sample from a `BetaDistribution`.

See also [`BetaDistribution`](@ref).
"""
function sample(dist::BetaDistribution)::Float64
    formal_dist = Distributions.Beta(alpha(dist), beta(dist))
    return Random.rand(formal_dist)
end


"""
    sample(dist::GammaDistribution)::Float64

Draw a random sample from a `GammaDistribution`.

See also [`GammaDistribution`](@ref).
"""
function sample(dist::GammaDistribution)::Float64
    formal_dist = Distributions.Gamma(alpha(dist), 1 / beta(dist))
    return Random.rand(formal_dist)
end


function Base.:+(a::Tally, b::Tally)
    T = typeof(a)
    @assert(T == typeof(b), "Tallies must be of the same type")
    return T(a.count + b.count, a.size + b.size)
end


function Base.:-(a::Tally, b::Tally)
    T = typeof(a)
    @assert(T == typeof(b), "Tallies must be of the same type")
    return T(a.count - b.count, a.size - b.size)
end


function Base.:+(a::Tally, b::Tuple{Int,Int})
    T = typeof(a)
    return T(a.count + b[1], a.size + b[2])
end


function Base.:-(a::Tally, b::Tuple{Int,Int})
    T = typeof(a)
    return T(a.count - b[1], a.size - b[2])
end


function unpack(t::Tally)
  return (t.count, t.size)
end
