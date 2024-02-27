#!/bin/sh

test_vote_events_csv_file='test-data/vote-events.csv'
expected_tallies_file='test-data/expected-tallies.txt'

#test-events-json-to-csv:
#    cat test-data/vote-events.jsonl| jq -s | jq -r '(map(keys) | add | unique) as $cols | map(. as $row | $cols | map($row[.])) as $rows | $cols, $rows[] | @csv' > test-data/vote-events.csv

TMPDIR=`mktemp -d /tmp/global-brain-service-test.XXXXXX`; (
    echo "Testing tallies";
    touch $TMPDIR/score.db;
    sqlite3 $TMPDIR/score.db < sql/tables.sql;
    sqlite3 $TMPDIR/score.db < sql/views.sql;
    sqlite3 $TMPDIR/score.db < sql/triggers.sql;
    sqlite3 $TMPDIR/score.db -csv -header  ".import -skip 1 '|cat' VoteEventImport" < $test_vote_events_csv_file;
    sqlite3 $TMPDIR/score.db -line ".eqp off" ".output $TMPDIR/tallies.txt" "select * from DetailedTally";
    echo "Comparing $TMPDIR/tallies.txt to $expected_tallies_file";
    diff $expected_tallies_file $TMPDIR/tallies.txt
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

