compile:
    julia --project compile.jl

sqlite:
    sqlite3 $DATABASE_PATH

reset-db:
    rm -f $DATABASE_PATH
    sqlite3 $DATABASE_PATH < sql/tables.sql
    sqlite3 $DATABASE_PATH < sql/triggers.sql

run:
    ./build/bin/ScheduledScoring $DATABASE_PATH
