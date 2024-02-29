using Random, Distributions, SQLite
using FilePathsBase

if isinteractive()
    include("src/GlobalBrainService.jl")
else
    include("../src/GlobalBrainService.jl")
end

using Main.GlobalBrainService
using DataFrames


sim_database_path = ENV["SIM_DATABASE_PATH"]
function init_sim_db(tag_id)::SQLite.DB
    if isfile(sim_database_path)
        rm(sim_database_path)
    end
    db = get_score_db(sim_database_path)
    # clear_simulation(db, tag_id)
    # println("Inited sim db");
    return db
end

# function clear_simulation(db, tag_id)
#     DBInterface.execute(db, "delete from ScoreEvent where tagId = ?", [tag_id])
#     DBInterface.execute(db, "delete from Score where tagId = ?", [tag_id])
#     DBInterface.execute(db, "delete from VoteEvent where tagId = ?", [tag_id])
#     DBInterface.execute(db, "delete from Vote where tagId = ?", [tag_id])
#     DBInterface.execute(db, "delete from Tally where tagId = ?", [tag_id])
#     DBInterface.execute(db, "delete from ConditionalVote where tagId = ?", [tag_id])
#     DBInterface.execute(db, "delete from ConditionalTally where tagId = ?", [tag_id])
#     # DBInterface.execute(db, "delete from Post where tagId = ?", [tag_id])
#     DBInterface.execute(db, "update lastVoteEvent set importedVoteEventId = 0, processedVoteEventId = 0 where tagId = ?", [tag_id])
# end


function run_simulation(sim::Function; tag_id=nothing) 

    vote_event_id = 1
    db = init_sim_db(tag_id)

    # Init globals that are visible in all scripts
    process_votes = function(parent_id, post_id, draws::Vector{Bool}) 
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

            if isnothing(db)
                error("What is wrong", db)

            end

            GlobalBrainService.process_vote_event(db, vote_event) do score
                # println("Tag_id: $tag_id, vote_event: $vote_event_id, score_event: $score.score_event_id")
            end
            vote_event_id += 1
        end

    end

    sim(process_votes)

    results = DBInterface.execute(db, "select * from score where tagId = ? order by postId", [tag_id]);
    println(DataFrame(results))

    close(db)
end



