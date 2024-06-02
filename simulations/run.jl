include("GlobalBrainSimulations.jl")
using Main.GlobalBrainSimulations
using Test
using Random
using Distributions

scenarios_directory_path = ARGS[1]
filename = length(ARGS) == 2 ? ARGS[2] : nothing

db = get_sim_db(ENV["SIM_DATABASE_PATH"]; reset = true)

for file in readdir(scenarios_directory_path)
    if (!isnothing(filename) && (filename != file))
        continue
    end
    sim = include(joinpath(pwd(), scenarios_directory_path, file))
    sim_name = endswith(file, ".jl") ? String(chop(file, tail = 3)) : file
    @info "Running simulation $(sim_name)..."
    @testset "$(sim_name)" begin
        run_simulation!(sim, db, simulation_name = sim_name)
    end
end

close(db)
