include("GlobalBrainSimulations.jl")
using Main.GlobalBrainSimulations
using Test
using Random
using Distributions

default_scenarios_path = joinpath(@__DIR__, "scenarios")

if length(ARGS) > 1
    throw("Too many arguments. Usage: julia run.jl [path]")
end

path_argument = length(ARGS) == 1 ? ARGS[1] : nothing

path =
    isnothing(path_argument) ?
    begin
        @info "Running all scenarios under $default_scenarios_path"
        default_scenarios_path
    end : joinpath(pwd(), path_argument)

function expand_path(path::String)
    Vector{String}
    if isdir(path)
        return collect(
            Iterators.flatten([
                expand_path(joinpath(path, filename)) for filename in readdir(path)
            ]),
        )
    end
    return [path]
end

filenames = expand_path(path)

if length(filenames) == 0
    throw("No files found in $path")
end

helpers_path = joinpath(@__DIR__, "helpers")
for file in readdir(helpers_path)
    @info "Including $file"
    include(joinpath(helpers_path, file))
end

db = get_sim_db(ENV["SIM_DATABASE_PATH"]; reset = true)

for file in filenames
    sim = include(file)
    sim_name =
        endswith(file, ".jl") ? String(chop(basename(file), tail = 3)) : basename(file)
    @info "Running simulation $(sim_name)..."
    begin
        run_simulation!(sim, db, simulation_name = sim_name)
    end
end

close(db)
