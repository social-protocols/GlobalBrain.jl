include("../src/GlobalBrain.jl")
using Main.GlobalBrain
using Random
using Distributions
using SQLite
using Test

include("../simulations/sim1-marbles.jl")
include("../simulations/sim2-b-implies-a.jl")
include("../simulations/sim3-counter-argument.jl")

db = get_sim_db(ENV["SIM_DATABASE_PATH"]; reset = true)

begin
    try
		run_simulation!(marbles, db, tag_id = get_or_insert_tag_id(db, "marbles"))
    catch e
        @error e
    end
end

begin
    try
		run_simulation!(b_implies_a, db, tag_id = get_or_insert_tag_id(db, "b_implies_a"))
    catch e
        @error e
    end
end

begin
    try
		run_simulation!(counter_argument, db, tag_id = get_or_insert_tag_id(db, "counter_argument"))
    catch e
        @error e
    end
end



close(db)
