include("GlobalBrainSimulations.jl")
using Main.GlobalBrainSimulations
using GlobalBrain
using Test
using Random

sim = include(joinpath(pwd(), ARGS[1]))

db = get_sim_db(ENV["SIM_DATABASE_PATH"]; reset = true)

@info "Running simulation $(ARGS[1])..."
@testset "$(ARGS[1])" begin
    run_simulation!(sim, db, tag_id = get_or_insert_tag_id(db, ARGS[1]))
end

close(db)
