#!/usr/bin/env bash
set -e  # exit on error
for f in test/*.sh; do
  echo "Running $f"
  bash "$f"
done
