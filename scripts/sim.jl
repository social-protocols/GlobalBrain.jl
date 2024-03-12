include("../src/GlobalBrainService.jl")
using Main.GlobalBrainService
using Random
using Distributions
using SQLite

include("../simulations/sim1-marbles.jl")
include("../simulations/sim2-b-implies-a.jl")
include("../simulations/sim3-counter-argument.jl")

db = get_sim_db(ENV["SIM_DATABASE_PATH"]; reset = true)

run_simulation!(marbles, db, tag_id = 1)
run_simulation!(b_implies_a, db, tag_id = 2)
# run_simulation!(counter_argument, db, tag_id = 3)

close(db)
