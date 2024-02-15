compile:
    julia --project compile.jl

sqlite:
    sqlite3 $DATABASE_PATH

run:
    ./build/bin/ScheduledScoring $DATABASE_PATH
