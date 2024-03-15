include("../src/GlobalBrain.jl")
using Main.GlobalBrain
using Random
using Distributions
using SQLite
using Test

include("../simulations/sim1-marbles.jl")
include("../simulations/sim2-b-implies-a.jl")

begin
    rm("tmp", force = true, recursive = true)
    TEST_DB_PATH = joinpath("tmp", "test.db")
    mkdir("tmp")
    init_sim_db(TEST_DB_PATH)
    db = get_sim_db(TEST_DB_PATH; reset = true)
end

begin
    try
        run_simulation!(marbles, db, tag_id = 1)
    catch e
        @error e
    end
end

begin
    try
        run_simulation!(b_implies_a, db, tag_id = 2)
    catch e
        @error e
    end
end

close(db)
rm("tmp", recursive = true)
