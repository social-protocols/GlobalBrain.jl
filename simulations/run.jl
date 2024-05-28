include("GlobalBrainSimulations.jl")
using Main.GlobalBrainSimulations
using Test
using Random
using Distributions

sim = include(joinpath(pwd(), ARGS[1]))

db = get_sim_db(ENV["SIM_DATABASE_PATH"]; reset = true)

@info "Running simulation $(ARGS[1])..."
@testset "$(ARGS[1])" begin
    # TODO: extract filename without file ending
    run_simulation!(sim, db, simulation_name = ARGS[1])
end

close(db)
