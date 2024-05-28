#!/bin/sh

set -Eeuo pipefail

test_vote_events_json_file='test-data/vote-events.jsonl'
expected_score_events_file='test-data/expected-score-events.jsonl'

TEST_DB_FILENAME=$SOCIAL_PROTOCOLS_DATADIR/test.db
rm -f $TEST_DB_FILENAME

echo "Using test database $TEST_DB_FILENAME"

TMPDIR=`mktemp -d /tmp/global-brain-service-test.XXXXXX`; (
    set -e
    echo "Testing scoring algorithm";
    julia --project --eval "using GlobalBrain; init_score_db(ARGS[1])" $TEST_DB_FILENAME
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

