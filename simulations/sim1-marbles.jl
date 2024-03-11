# Scenario
# post: "Did you draw a blue marble?"
# users vote honestly.

function marbles(step_func::Function, db::SQLite.DB, tag_id::Int)
    post_id = 1
    n = 100
    p = 0.37
    draws = rand(Bernoulli(p), n)
    step_func(db, nothing, post_id, draws, 1; tag_id = tag_id)
end

# @testset "Expected results" begin
#     # @test_throws AssertionError surprisal(0.0)
#     # @test surprisal(0.25) == 2.0
#     # @test surprisal(0.5) == 1.0
#     # @test surprisal(0.75) ≈ 0.41 atol = 0.01
#     # @test surprisal(1.0) == 0.0
#     # @test_throws AssertionError surprisal(2.0)
#     # @test_throws AssertionError surprisal(0.0, 3)
#     @test  nrow(df) == 1
# end
