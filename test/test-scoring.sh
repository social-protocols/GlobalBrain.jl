#!/bin/sh


test_vote_events_json_file='test-data/vote-events.jsonl'
expected_score_events_file='test-data/expected-score-events.jsonl'

TMPDIR=`mktemp -d /tmp/global-brain-service-test.XXXXXX`; (
    set -e
    echo "Testing scoring algorithm";
    touch $TMPDIR/score.db;
    sqlite3 $TMPDIR/score.db < sql/tables.sql;
    sqlite3 $TMPDIR/score.db < sql/views.sql;
    sqlite3 $TMPDIR/score.db < sql/triggers.sql;
    julia --project -- scripts/run.jl $TMPDIR/score.db $test_vote_events_json_file $TMPDIR/score-events.jsonl;
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

