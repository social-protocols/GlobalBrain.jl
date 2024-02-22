include(joinpath("..", "src", "ScheduledScoring.jl"))
using Main.ScheduledScoring

# Get environment variables
database_path =  get(ENV, "DATABASE_PATH", "")
vote_events_path = get(ENV, "VOTE_EVENTS_PATH", "")


scheduled_scorer(database_path, vote_events_path)

