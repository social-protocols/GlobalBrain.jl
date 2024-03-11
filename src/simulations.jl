function get_sim_db(path::String; reset::Bool = true)::SQLite.DB
    if (reset)
        @info "Resetting simulation database..."
        if isfile(path)
            rm(path)
        end
        return get_score_db(path)
    end
    return get_score_db(path)
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
    dummy_func = (_, _, _) -> nothing
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
        GlobalBrainService.process_vote_event(dummy_func, db, vote_event)
        vote_event_id += 1
    end
end
