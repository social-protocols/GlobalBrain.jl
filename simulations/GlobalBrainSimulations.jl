module GlobalBrainSimulations

include("../src/GlobalBrain.jl")

using SQLite
using .GlobalBrain
using Distributions
using Memoize
using Random

export SimulationAPI
export SimulationVote
export get_sim_db
export run_simulation!

const LEGACY_TAG_ID = 1

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

mutable struct Simulation
    db::SQLite.DB
    simulation_id::Int
    step::Int
end

struct SimulationAPI
    post!::Function
    step!::Function
end

function SimulationAPI(sim::Simulation)
    return SimulationAPI(
        function (parent_id::Union{Number,Nothing}, content::String)
            create_simulation_post!(
                sim.db,
                sim.simulation_id,
                parent_id,
                content
            )
        end,
        function (
            step::Int,
            votes::Array{SimulationVote};
            description::Union{String,Nothing} = nothing,
        )
            if sim.step == step
                throw("Already processed step $(step)")
            end
            scores = simulation_step!(
                sim.db,
                step,
                votes,
                sim.simulation_id;
                description = description,
            )
            sim.step = step
            scores
        end,
    )
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
    db = init_score_db(path)
    create_sim_db_tables(db)
end

function create_sim_db_tables(db::SQLite.DB)
    DBInterface.execute(
        db,
        """
        create table Simulation (
            simulation_id integer not null primary key autoincrement
            , simulation_name text not null
            , created_at integer not null default (unixepoch('subsec')*1000)
        )
        """
    )

    DBInterface.execute(
        db,
        """
        create table PostSimulation (
            post_id integer not null
            , simulation_id integer not null
            , primary key(post_id, simulation_id)
        )
        """
    )

    DBInterface.execute(
        db,
        """
        create table Period (
              simulation_id integer not null
            , step integer not null
            , description text
        )
        """,
    )
end

function insert_simulation(db::SQLite.DB, simulation_name::String)::Int
    return DBInterface.execute(
        db,
        """
        insert into Simulation (simulation_name)
        values (?) returning simulation_id
        """,
        [simulation_name],
    ) |> collect_results(row -> row[:simulation_id]) |> first
end

function run_simulation!(sim::Function, db::SQLite.DB; simulation_name = "default")
    simulation_id = insert_simulation(db, simulation_name)
    s = Simulation(db, simulation_id, 0)
    sim(SimulationAPI(s))
end

function create_simulation_post!(
    db::SQLite.DB,
    simulation_id::Int,
    parent_id::Union{Int,Nothing},
    content::String,
)::SimulationPost
    results = DBInterface.execute(
        db,
        """
        insert into post (parent_id, content)
        values (?, ?)
        on conflict do nothing returning id
        """,
        [parent_id, content],
    ) |> collect_results(row -> row[:id])

    if length(results) == 0
        error("Failed to insert post")
    end

    id = first(results)
    
    DBInterface.execute(
        db,
        """
        insert into PostSimulation (post_id, simulation_id)
        values (?, ?)
        """,
        [id, simulation_id]
    )

    return SimulationPost(parent_id, id, content)
end

function simulation_step!(
    db::SQLite.DB,
    step::Int,
    votes::Array{SimulationVote},
    simulation_id::Int;
    description::Union{String,Nothing} = nothing,
)::Tuple{Dict, Dict}
    vote_event_id = get_last_processed_vote_event_id(db) + 1

    DBInterface.execute(
        db,
        "insert into period (simulation_id, step, description) values (?, ?, ?)",
        [simulation_id, step, description],
    ) |> collect_results()

    for v in shuffle(votes)
        parent_id = get_parent_id(db, v.post_id)
        vote_event = VoteEvent(
            vote_event_id = vote_event_id,
            vote_event_time = step,
            user_id = string(v.user_id),
            tag_id = LEGACY_TAG_ID,
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

    scores = DBInterface.execute(
        db,
        """
        select Score.* from Score
        join PostSimulation
        on PostSimulation.post_id = Score.post_id
        where PostSimulation.simulation_id = ?
        """,
        [simulation_id]
    ) |> collect_results(row -> sql_row_to_score(row))

    effects = DBInterface.execute(
        db,
        """
        select Effect.* from Effect
        join PostSimulation
        on PostSimulation.post_id = Effect.post_id
        where PostSimulation.simulation_id = ?
        """,
        [simulation_id]
    ) |> collect_results(row -> sql_row_to_effect(row))

    return (
        Dict(score.post_id => score for score in scores),
        Dict((effect.post_id, effect.note_id) => effect for effect in effects),
    )
end

@memoize function get_parent_id(db::SQLite.DB, post_id::Int)
    results = DBInterface.execute(
        db,
        "select parent_id as parent_id from post where id = ?",
        [post_id],
    ) |> collect_results(row -> row[:parent_id])

    if length(results) == 0
        error("Failed to get parent id for $post_id")
    end

    id = first(results)
    return ismissing(id) ? nothing : id
end

end
