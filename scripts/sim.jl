if isinteractive()
    include("src/GlobalBrainService.jl")
else
    include("../src/GlobalBrainService.jl")
end


using Main.GlobalBrainService
using Random, Distributions, SQLite
using FilePathsBase

database_path = ENV["SIM_DATABASE_PATH"]

function reset_db(path::String = database_path)::SQLite.DB
    if isfile(path)
        rm(path)
    end
    return get_score_db(path)
end


function vote_processor(db) 
    vote_event_id = 1
    return function(tag_id, parent_id, post_id, draws::Vector{Bool}) 
        t = 0

        for (i, draw) in enumerate(draws)
            vote = draw == 1 ? 1 : -1

            vote_event = GlobalBrainService.VoteEvent(
                id=vote_event_id,
                user_id=string(i),
                tag_id=tag_id,
                parent_id=parent_id,
                post_id=post_id,
                note_id=nothing,
                vote=vote,
                created_at=t
            )
            GlobalBrainService.process_vote_event(db, vote_event) do score
                vote_event_id += 1
            end
        end

    end
end


# Init globals that are visible in all scripts
db = reset_db(database_path)

process_votes = vote_processor(db)

# Loop through each .jl file in the directory
tag_id = 1
for file in readdir("simulations")
    if endswith(file, ".jl")
        global tag_id
        println("Running simulation $file with tag_id=$tag_id")
        include("../simulations/$file")
        tag_id += 1
    end
end

close(db)




