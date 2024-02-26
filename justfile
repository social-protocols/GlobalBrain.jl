compile:
    julia --project compile.jl

runbin:
    ./build/bin/ScheduledScoring $DATABASE_PATH $VOTE_EVENTS_PATH

run:
    test -e $VOTE_EVENTS_PATH || touch $VOTE_EVENTS_PATH
    tail -n +0 -F $VOTE_EVENTS_PATH | julia --project -- scripts/run.jl $DATABASE_PATH - $SCORE_EVENTS_PATH

runtest:
    cat $VOTE_EVENTS_TEST_PATH | julia --project -- scripts/run.jl $DATABASE_PATH - $SCORE_EVENTS_PATH

dev:
    julia --eval "using Pkg; Pkg.develop(path = pwd())"

sqlite:
    sqlite3 $DATABASE_PATH

reset-db:
    rm -f $DATABASE_PATH
    sqlite3 $DATABASE_PATH < sql/tables.sql
    sqlite3 $DATABASE_PATH < sql/views.sql
    sqlite3 $DATABASE_PATH < sql/triggers.sql




#test-events-json-to-csv:
#    cat test-data/vote-events.jsonl| jq -s | jq -r '(map(keys) | add | unique) as $cols | map(. as $row | $cols | map($row[.])) as $rows | $cols, $rows[] | @csv' > test-data/#vote-events.csv


test-vote-events-csv-file := 'test-data/vote-events.csv'
test-tallies-file := 'test-data/tallies.txt'    
expected-tallies-file := 'test-data/expected-tallies.txt'
test-database-file := "test-data/test.db"

test-tallies:
    rm -f {{test-database-file}}
    rm -f {{test-tallies-file}}

    sqlite3 {{test-database-file}} < sql/tables.sql
    sqlite3 {{test-database-file}} < sql/views.sql
    sqlite3 {{test-database-file}} < sql/triggers.sql
    sqlite3 {{test-database-file}} -csv -header  ".import -skip 1 '|cat' VoteEventImport" < {{test-vote-events-csv-file}}

    sqlite3 {{test-database-file}} -line "select * from DetailedTally" > {{test-tallies-file}}    

    @echo "Comparing {{test-tallies-file}} to {{expected-tallies-file}}"
    @diff {{expected-tallies-file}} {{test-tallies-file}}
    @echo "Tests passed"



test-vote-events-json-file := 'test-data/vote-events.jsonl'
test-score-events-file := 'test-data/score-events.jsonl'    
expected-score-events-file := 'test-data/expected-score-events.jsonl'

test-service:
    rm -f {{test-database-file}}
    rm -f {{test-score-events-file}}

    sqlite3 {{test-database-file}} < sql/tables.sql
    sqlite3 {{test-database-file}} < sql/views.sql
    sqlite3 {{test-database-file}} < sql/triggers.sql

    julia --project -- scripts/run.jl {{test-database-file}} {{test-vote-events-json-file}} {{test-score-events-file}}

    @echo "Comparing {{test-score-events-file}} to {{expected-score-events-file}}"
    @diff {{expected-score-events-file}} {{test-score-events-file}}
    @echo "Tests passed"

test:
    just test-tallies
    just test-service
