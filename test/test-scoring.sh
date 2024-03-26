#!/bin/sh


test_vote_events_json_file='test-data/vote-events.jsonl'
expected_score_events_file='test-data/expected-score-events.jsonl'


TEST_DB_FILENAME=$SOCIAL_PROTOCOLS_DATADIR/test.db
rm -r $TEST_DB_FILENAME

TMPDIR=`mktemp -d /tmp/global-brain-service-test.XXXXXX`; (
    set -e
    echo "Testing scoring algorithm";
    touch $TEST_DB_FILENAME;
    sqlite3 $TEST_DB_FILENAME < sql/tables.sql;
    sqlite3 $TEST_DB_FILENAME < sql/views.sql;
    sqlite3 $TEST_DB_FILENAME < sql/triggers.sql;
    julia --project -- scripts/run.jl $TEST_DB_FILENAME $test_vote_events_json_file $TMPDIR/score-events.jsonl;
    echo "Comparing $TMPDIR/score-events.jsonl to $expected_score_events_file";
    diff -b $expected_score_events_file $TMPDIR/score-events.jsonl;
); 
result=$?

if [ $result -eq 1 ]; then
    echo "test failed. Keeping test output in $TMPDIR for debugging."
    exit 1
else
    echo "Scoring tests passed"
    rm -rf $TMPDIR
fi

