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
    Base.run(pipeline(`cat sql/simulation-posts.sql`, `sqlite3 $path`))
end

struct SimulationPost
    parent_id::Union{Int, Nothing}
    post_id::Int
    content::String
end

function create_simulation_post!(db::SQLite.DB, post::SimulationPost)::Bool
    DBInterface.execute(
        db,
        "insert into post (parent_id, id, content) values (?, ?, ?)",
        [post.parent_id, post.post_id, post.content]
    )
    return true
end

function run_simulation!(sim::Function, db::SQLite.DB; tag_id=nothing)
    @info "Running simulation $(tag_id)..."
    sim(simulation_step!, db, tag_id)
end

function simulation_step!(
    db::SQLite.DB,
    parent_id::Union{Int, Nothing},
    post_id::Int,
    draws::Vector{Bool},
    simulation_step!::Int;
    start_user::Int = 0,
    tag_id = 1,
)
    vote_event_id = get_last_processed_vote_event_id(db) + 1

    for (i, draw) in enumerate(draws)
        vote = draw == 1 ? 1 : -1
        vote_event = GlobalBrainService.VoteEvent(
            vote_event_id = vote_event_id,
            vote_event_time = simulation_step!,
            user_id = string(i + start_user),
            tag_id = tag_id,
            parent_id = parent_id,
            post_id = post_id,
            note_id = nothing,
            vote = vote,
        )
        GlobalBrainService.process_vote_event(db, vote_event) do vote_event_id::Int, vote_event_time::Int, object
            e = create_event(vote_event_id, vote_event_time, object)
            insert_event(db, e)
        end
        vote_event_id += 1
    end
end
