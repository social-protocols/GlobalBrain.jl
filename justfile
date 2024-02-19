compile:
    julia --project compile.jl

run:
    ./build/bin/ScheduledScoring $DATABASE_PATH $VOTE_EVENTS_PATH

sqlite:
    sqlite3 $DATABASE_PATH

reset-db:
    rm -f $DATABASE_PATH
#    sqlite3 $DATABASE_PATH < ScheduledScoring.jl/sql/tables.sql
#    sqlite3 $DATABASE_PATH < ScheduledScoring.jl/sql/views.sql
#    sqlite3 $DATABASE_PATH < ScheduledScoring.jl/sql/triggers.sql
#    sqlite3 $DATABASE_PATH < ScheduledScoring.jl/sql/import-vote-events.sql

import-vote-events:
#    sqlite3 $DATABASE_PATH < ScheduledScoring.jl/sql/import-vote-events.sql
