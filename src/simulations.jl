struct SimulationPost
    parent_id::Union{Int,Nothing}
    post_id::Int
    content::String
end

struct SimulationVote
    post_id::Int
    vote::Int
    user_id::Int
end

function get_sim_db(path::String; reset::Bool = false)::SQLite.DB
    if (reset | !isfile(path))
        init_sim_db(path)
    end
    return get_score_db(path)
end

function init_sim_db(path::String)
    @info "Initializing simulation database..."
    if isfile(path)
        rm(path)
    end
    init_score_db(path)
end

function run_simulation!(sim::Function, db::SQLite.DB; tag_id)

    s = Simulation(
        db,
        tag_id,
        0,
    )

    sim(SimulationAPI(s))


    # sim() do i, posts, votes
    #     simulation_votes!(db, i, posts, votes; tag_id = tag_id)
    # end
end

struct SimulationAPI
    post!::Function
    step!::Function
end

mutable struct Simulation
    db::SQLite.DB
    tag_id::Int
    step::Int
end

function SimulationAPI(sim::Simulation)
    return SimulationAPI(
        # function() "foo" end,
        function(parent_id::Union{Number, Nothing}, content::String)
            create_simulation_post!(sim.db, parent_id, content)
        end,
        function(step::Int, votes::Array{SimulationVote})
            if sim.step == step 
                # throw: error already processed this step
                throw("Already processed step $(step)")
            end
            scores = simulation_votes!(sim.db, step, votes, sim.tag_id)
            sim.step = step
            scores
        end
    )

end


function create_simulation_post!(db::SQLite.DB, parent_id::Union{Int,Nothing}, content::String)::SimulationPost
    result = DBInterface.execute(
        db,
        "insert into post (parent_id, content) values (?, ?) on conflict do nothing returning id",
        [parent_id, content],
    )
    r = iterate(result)

    return SimulationPost(
        parent_id,
        r[1].id,
        content,
    )
end

using Memoize

@memoize function get_parent_id(db::SQLite.DB, post_id::Int)
    r = DBInterface.execute(db, "select parent_id as parent_id from post where id = ?", [post_id])
    r = iterate(r)
    id = r[1][:parent_id]
    return ismissing(id) ? nothing : id
end



function simulation_votes!(
    db::SQLite.DB,
    step::Int,
    votes::Array{SimulationVote},
    tag_id::Int,
)::Dict
    vote_event_id = get_last_processed_vote_event_id(db) + 1

    # for p in posts
    #     create_simulation_post!(db, p, step)
    # end


    for v in shuffle(votes)
        parent_id = get_parent_id(db, v.post_id)
        vote_event = VoteEvent(
            vote_event_id = vote_event_id,
            vote_event_time = step,
            # TODO: refactor start_user scheme in simulations
            # user_id = string(i + start_user),
            user_id = string(v.user_id),
            tag_id = tag_id,
            parent_id = parent_id,
            post_id = v.post_id,
            note_id = nothing,
            vote = v.vote,
        )
        process_vote_event(db, vote_event) do object
            e = as_event(vote_event_id, step, object)
            insert_event(db, e)
        end
        vote_event_id += 1
    end

    score_rows =
        DBInterface.execute(db, "select * from score where tag_id = :tag_id", [tag_id])
    scores = map(sql_row_to_score, score_rows)
    return Dict(score.post_id => score for score in scores)
end
