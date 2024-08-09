#!/bin/sh
set -Eeuo pipefail

curl \
  --verbose \
  --header "Content-Type: application/json" \
  --data '{ "payload": [ {"user_id":"105","tag_id":1,"parent_id":null,"post_id":1,"comment_id":null,"vote":1,"vote_event_time":1708772663570,"vote_event_id":5} ] }' \
  http://127.0.0.1:8000/score
