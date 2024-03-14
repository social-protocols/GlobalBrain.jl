module GlobalBrain

# import DBInterface
import Distributions
import SQLite
import Random
import Dates
# import Turing
# import MCMCChains
# import Logging

include("types.jl")
include("constants.jl")
include("binary-entropy.jl")
include("probabilities.jl")
include("algorithm.jl")
include("score.jl")
include("note-effect.jl")

# --- Exported types
# ------------------

export Post
# export Vote

export Model
export BetaBernoulli
export GammaPoisson
export DetailedTally
export BernoulliTally
export PoissonTally
export Distribution
export BetaDistribution
export GammaDistribution
export alpha
export beta

export Effect
export Score

export TalliesTree
export InMemoryTree

# --- Exports from probabilities.jl
# ---------------------------------

export update
export bayesian_avg
export reset_weight
export sample
export unpack
export +
export -



# --- Exports from .BinaryEntropy
# -------------------------------

using .BinaryEntropy

export surprisal
export entropy
export cross_entropy
export relative_entropy
export information_gain


# --- Exports from algorithm.jl
# -----------------------------

export score_tree

# --- Exports from score.jl
# -----------------------------

export score

end
