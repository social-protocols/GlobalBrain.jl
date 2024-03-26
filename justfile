# List available recipes in the order in which they appear in this file
_default:
    @just --list --unsorted

instantiate:
    julia --project -e 'using Pkg; Pkg.instantiate()'

format:
    julia --project --eval "using JuliaFormatter; format(joinpath(pwd(), \"src\"))"

run:
    test -e $VOTE_EVENTS_PATH || touch $VOTE_EVENTS_PATH
    tail -n +0 -F $VOTE_EVENTS_PATH | julia --project -- scripts/run.jl $DATABASE_PATH - $SCORE_EVENTS_PATH

dev:
    julia --eval "using Pkg; Pkg.develop(path = pwd())"

db:
    litecli $DATABASE_PATH

reset-db:
    rm -f $DATABASE_PATH
    sqlite3 $DATABASE_PATH < sql/tables.sql
    sqlite3 $DATABASE_PATH < sql/views.sql
    sqlite3 $DATABASE_PATH < sql/triggers.sql


sim name="":
    julia --project scripts/sim.jl {{name}}


sim-db:
    litecli $SIM_DATABASE_PATH

test-db:
    litecli $SOCIAL_PROTOCOLS_DATADIR/test.db

app:
  find shiny | entr -cnr bash -c "Rscript -e \"shiny::runApp('shiny', port = 3456)\""

############ TESTS ##############

test:
    julia --project --eval "using Pkg; Pkg.test()"
    ./test.sh
