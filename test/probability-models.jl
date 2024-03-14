@testset "Probability models: update and reset BetaDistribution" begin
    beta_dist = BetaDistribution(0.5, 0.5)
    bernoulli_tally = BernoulliTally(8, 10)
    poisson_tally = PoissonTally(8, 10)
    updated_beta_dist = update(beta_dist, bernoulli_tally)
    updated_beta_dist_with_reset_weight = reset_weight(updated_beta_dist, 3.14)

    @test updated_beta_dist.mean ≈ 0.78 atol = 0.01
    @test updated_beta_dist.weight == 10.5
    @test_throws MethodError update(beta_dist, poisson_tally)
    @test updated_beta_dist_with_reset_weight.weight == 3.14
end

@testset "Probability models: update and reset GammaDistribution" begin
    gamma_dist = GammaDistribution(0.1, 2.0)
    poisson_tally = PoissonTally(8, 10)
    bernoulli_tally = BernoulliTally(8, 10)
    updated_gamma_dist = update(gamma_dist, poisson_tally)
    updated_gamma_dist_with_reset_weight = reset_weight(updated_gamma_dist, 3.14)

    @test updated_gamma_dist.mean ≈ 0.68 atol = 0.01
    @test updated_gamma_dist.weight == 12.0
    @test_throws MethodError update(gamma_dist, bernoulli_tally)
    @test updated_gamma_dist_with_reset_weight.weight == 3.14
end

@testset "Probability models: Tally arithmetic" begin
    bernoulli_tally = BernoulliTally(11, 17)
    bernoulli_tally_increased_1 = bernoulli_tally + BernoulliTally(3, 5)
    bernoulli_tally_increased_2 = bernoulli_tally + (7, 10)

    poisson_tally = PoissonTally(12, 16)
    poisson_tally_increased_1 = poisson_tally + PoissonTally(5, 8)
    poisson_tally_increased_2 = poisson_tally + (1, 25)

    @test bernoulli_tally_increased_1.count == 14
    @test bernoulli_tally_increased_1.size == 22
    @test bernoulli_tally_increased_2.count == 18
    @test bernoulli_tally_increased_2.size == 27

    @test poisson_tally_increased_1.count == 17
    @test poisson_tally_increased_1.size == 24
    @test poisson_tally_increased_2.count == 13
    @test poisson_tally_increased_2.size == 41
end
