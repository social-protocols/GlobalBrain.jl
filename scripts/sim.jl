include("../src/GlobalBrain.jl")
using Main.GlobalBrain
using Random
using Distributions
using SQLite
using Test


# iterate through simulations in ../simulations
# and run them with the database

simulations = Vector{Function}() 
for simfile in readdir("simulations")
    sim = include(joinpath("..","simulations",simfile))
    push!(simulations, sim)
end

db = get_sim_db(ENV["SIM_DATABASE_PATH"]; reset = true)

requested_sim = length(ARGS) > 0 ? ARGS[1] : nothing

begin
    local sims_run = 0
    for s in simulations
        n = String(Symbol(s))
        if !isnothing(requested_sim) && n != requested_sim
            continue
        end
        # try    
            @info "Running simulation $(n)..."
            run_simulation!(s, db, tag_id = get_or_insert_tag_id(db, n))
            sims_run += 1
        # catch e
            # @error e
        # end
    end

    if sims_run == 0
        if !isnothing(requested_sim) 
            throw("No such simulation $requested_sim")
        else 
            throw("No simulations run")
        end
    end

end

close(db)
