
# Global prior on the vote rate (votes / attention). By definition the prior
# average is 1, because attention is calculated as the expected votes for the
# average post.
const GLOBAL_PRIOR_VOTE_RATE_SAMPLE_SIZE = 2.3
const GLOBAL_PRIOR_VOTE_RATE = BetaDistribution(1.0, 2.3)
