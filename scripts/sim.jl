include("../src/GlobalBrainService.jl")
using Main.GlobalBrainService
using Random
using Distributions
using SQLite
# using FilePathsBase

# function get_vote_processor_func(db, start_vote_event_id = 1)
#     this_sim_vote_event_id = start_vote_event_id
#     return function(tag_id, parent_id, post_id, draws::Vector{Bool})
#         t = 0

#         for (i, draw) in enumerate(draws)
#             vote = draw == 1 ? 1 : -1

#             vote_event = GlobalBrainService.VoteEvent(
#                 vote_event_id = this_sim_vote_event_id,
#                 vote_event_time = t, # TODO
#                 user_id = string(i),
#                 tag_id = tag_id,
#                 parent_id = parent_id,
#                 post_id = post_id,
#                 note_id = nothing,
#                 vote = vote,
#             )

#             GlobalBrainService.process_vote_event(db, vote_event) do vote_event_id::Int, vote_event_time::Int, object
#                 this_sim_vote_event_id += 1
#             end
#         end
#     end
# end


# FROM src/simulations.jl
# process_votes = function(parent_id, post_id::Number, draws::Vector{Bool}; start_user::Number = 0)
#     t = 0

#     for (i, draw) in enumerate(draws)
#         vote = draw == 1 ? 1 : -1

#         vote_event = GlobalBrainService.VoteEvent(
#             vote_event_id = vote_event_id,
#             vote_event_time = t, # TODO
#             user_id = string(i + start_user),
#             tag_id = tag_id,
#             parent_id = parent_id,
#             post_id = post_id,
#             note_id = nothing,
#             vote = vote,
#         )


#         GlobalBrainService.process_vote_event(db, vote_event) do v_event_id, vote_event_time, event
#             # println("Tag_id: $tag_id, vote_event: $vote_event_id, score_event: $score.score_event_id")
#         end
#         vote_event_id += 1
#     end

# end



include("../simulations/sim1-marbles.jl")

db = get_sim_db(ENV["SIM_DATABASE_PATH"]; reset = true)
# vote_processor = get_vote_processor_func(db, 1)

run_simulation!(marbles, db, tag_id = 1)

# # tag_id += 1
# # include("../simulations/sim2-b-implies-a.jl")
# # tag_id += 1
# # include("../simulations/sim3-counter-argument.jl")
# # tag_id += 1
# # include("../simulations/sim4-two-children.jl")
# # tag_id += 1
# # include("../simulations/sim5-oj-simpson.jl")
# # tag_id += 1
# # include("../simulations/sim6.jl")

close(db)
