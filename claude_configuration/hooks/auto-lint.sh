#!/bin/bash
set -e
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[ -z "$FILE_PATH" ] && exit 0

if [[ "$FILE_PATH" == *.rb ]]; then
    shadowenv exec -- bundle exec rubocop -a "$FILE_PATH" --force-exclusion 2>/dev/null || true
fi
exit 0
