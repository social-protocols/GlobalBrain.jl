include(joinpath("..", "src", "GlobalBrainService.jl"))
using Main.GlobalBrainService

database_path = ARGS[1]
vote_events_path = ARGS[2]
score_events_path = ARGS[3]

scheduled_scorer(database_path, vote_events_path, score_events_path)
