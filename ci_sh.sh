#!/usr/bin/env bash
set -eo pipefail

if [ -f /root/sh_env ]; then
	source /root/sh_env
fi

exec bash --posix "$@"
