struct SimulationPost
    parent_id::Union{Int,Nothing}
    post_id::Int
    content::String
end

struct SimulationVote
    parent_id::Union{Int,Nothing}
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

function create_simulation_post!(db::SQLite.DB, post::SimulationPost, created_at::Int)::Bool
    DBInterface.execute(
        db,
        "insert into post (parent_id, id, content, created_at) values (?, ?, ?, ?)",
        [post.parent_id, post.post_id, post.content, created_at],
    )
    return true
end

function run_simulation!(sim::Function, db::SQLite.DB; tag_id = nothing)
    @info "Running simulation $(tag_id)..."
    sim() do i, posts, votes
        simulation_step!(db, i, posts, votes; tag_id = tag_id)
    end
end

function simulation_step!(
    db::SQLite.DB,
    step::Int,
    posts::Array{SimulationPost},
    votes::Array{SimulationVote};
    tag_id::Int = 1,
)::Dict
    vote_event_id = get_last_processed_vote_event_id(db) + 1

    for p in posts
        create_simulation_post!(db, p, step)
    end

    for v in votes
        vote_event = VoteEvent(
            vote_event_id = vote_event_id,
            vote_event_time = step,
            # TODO: refactor start_user scheme in simulations
            # user_id = string(i + start_user),
            user_id = string(v.user_id),
            tag_id = tag_id,
            parent_id = v.parent_id,
            post_id = v.post_id,
            note_id = nothing,
            vote = v.vote,
        )
        process_vote_event(
            db,
            vote_event,
        ) do vote_event_id::Int, vote_event_time::Int, object
            e = as_event(vote_event_id, vote_event_time, object)
            insert_event(db, e)
        end
        vote_event_id += 1
    end

    score_rows = DBInterface.execute(
        db,
        "select * from score where tag_id = :tag_id",
        [tag_id]
    )
    scores = map(sql_row_to_score, score_rows)
    return Dict(score.post_id => score for score in scores)
end
