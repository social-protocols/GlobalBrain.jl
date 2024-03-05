# List available recipes in the order in which they appear in this file
_default:
    @just --list --unsorted

compile:
    julia --project compile.jl

instantiate:
    julia --project -e 'using Pkg; Pkg.instantiate()'

runbin:
    ./build/bin/ScheduledScoring $DATABASE_PATH $VOTE_EVENTS_PATH


run:
    test -e $VOTE_EVENTS_PATH || touch $VOTE_EVENTS_PATH
    tail -n +0 -F $VOTE_EVENTS_PATH | julia --project -- scripts/run.jl $DATABASE_PATH - $SCORE_EVENTS_PATH

dev:
    julia --eval "using Pkg; Pkg.develop(path = pwd())"

sqlite:
    sqlite3 $DATABASE_PATH

reset-db:
    rm -f $DATABASE_PATH
    sqlite3 $DATABASE_PATH < sql/tables.sql
    sqlite3 $DATABASE_PATH < sql/views.sql
    sqlite3 $DATABASE_PATH < sql/triggers.sql

sim:
    julia --project scripts/sim.jl
    # && sqlite3 $SIM_DATABASE_PATH "select * from score;"


############ TESTS ##############

test:
    ./test.sh
