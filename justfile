# List available recipes in the order in which they appear in this file
_default:
    @just --list --unsorted

instantiate:
    julia --project -e 'using Pkg; Pkg.instantiate()'

format:
    cd app && npx prettier --write --ignore-path public/google-charts-loader.js .
    cd globalbrain-node && npx prettier --write . 
    julia -e 'using Pkg; Pkg.add("JuliaFormatter")'
    julia --eval "using JuliaFormatter; format(joinpath(pwd(), \"src\"))"

run:
    test -e $VOTE_EVENTS_PATH || touch $VOTE_EVENTS_PATH
    tail -n +0 -F $VOTE_EVENTS_PATH | julia --project -- scripts/run.jl $DATABASE_PATH - $SCORE_EVENTS_PATH

dev:
    julia --eval "using Pkg; Pkg.develop(path = pwd())"

db query="":
    litecli $DATABASE_PATH -e "{{query}}"

reset-db:
    rm -f $DATABASE_PATH
    julia --project --eval "using GlobalBrain; init_score_db(ARGS[1])" $DATABASE_PATH
    rm ~/social-protocols-data/score-events.jsonl

sim name="":
    time julia --project=simulations simulations/run.jl simulations/scenarios {{name}}

sim-db query="":
    litecli $SIM_DATABASE_PATH -e "{{query}}"

test-db query="":
    litecli $SOCIAL_PROTOCOLS_DATADIR/test.db -e "{{query}}"

visualize:
    cd app && npm install && npm run dev

typecheck: 
    cd app && npx tsc

ci-test:
    earthly +ci-test

build-shared-library:
    rm -rf globalbrain-node/julia/build
    cd globalbrain-node/julia && julia -t auto --startup-file=no --project -e 'using Pkg; Pkg.instantiate(); include("build.jl")'
    cd globalbrain-node && npm install && npm test


############ TESTS ##############

test:
    julia --project --eval "using Pkg; Pkg.test()"
    ./test.sh
