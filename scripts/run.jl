include(joinpath("..", "src", "GlobalBrainService.jl"))
using Main.GlobalBrainService

# Get environment variables
database_path =  get(ENV, "DATABASE_PATH", "")
vote_events_path = get(ENV, "VOTE_EVENTS_PATH", "")
score_events_path = get(ENV, "SCORE_EVENTS_PATH", "")


scheduled_scorer(database_path, vote_events_path, score_events_path)

