#!/bin/sh

set -Eeuo pipefail

expected_tallies_file='test-data/expected-tallies.txt'

TMPDIR=`mktemp -d /tmp/global-brain-service-test.XXXXXX`; (
    echo "Testing tallies";
    cat test-data/vote-events.jsonl| jq -s | jq -r '(["vote_event_id","user_id","tag_id","parent_id","post_id","note_id","vote","vote_event_time"]) as $cols | map(. as $row | $cols | map($row[.])) as $rows | $cols, $rows[] | @csv' | tr -d '"' > $TMPDIR/vote-events.csv
    julia --project --eval "using GlobalBrain; init_score_db(ARGS[1])" $TMPDIR/score.db
    sqlite3 $TMPDIR/score.db -csv -header  ".import -skip 1 '|cat' VoteEventImport" < $TMPDIR/vote-events.csv;
    sqlite3 $TMPDIR/score.db -line ".eqp off" ".output $TMPDIR/tallies.txt" "select * from ConditionalTally order by tag_id, post_id, note_id;";
    echo "Comparing $TMPDIR/tallies.txt to $expected_tallies_file";
    diff -b $expected_tallies_file $TMPDIR/tallies.txt
    result=$?
    if [ $result -eq 1 ]; then
        exit 1
    fi
); 
result=$?

if [ $result -eq 1 ]; then
    echo "test failed. Keeping test output in $TMPDIR for debugging."
    exit 1
else
    echo "Tallies tests passed"
    rm -rf $TMPDIR
fi

