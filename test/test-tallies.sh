#!/bin/sh

test_vote_events_csv_file='test-data/vote-events.csv'
expected_tallies_file='test-data/expected-tallies.txt'

result=3
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
    rm -rf $TMPDIR
fi

