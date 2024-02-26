#!/bin/bash
set -e  # exit on error
for f in test/*.sh; do
  bash "$f"
done