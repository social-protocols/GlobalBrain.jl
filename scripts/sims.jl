
sim_database_path = ENV["SIM_DATABASE_PATH"]
if isfile(sim_database_path)
    rm(sim_database_path)
end

# Loop through each .jl file in the directory
for file in readdir("simulations")
    if endswith(file, ".jl")
        println("Running simulation $file")
        include("../simulations/$file")
    end
end

