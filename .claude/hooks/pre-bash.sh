#!/usr/bin/env bash
# Runs before every Bash tool call. Blocks catastrophic commands (exit 1).
# Non-zero exit = command is blocked. Stdout message is shown to the user.

set -uo pipefail

INPUT=$(cat)

CMD=$(echo "$INPUT" | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('command', ''))
" 2>/dev/null || true)

[[ -z "$CMD" ]] && exit 0

# Patterns that should NEVER run without explicit user confirmation
BLOCKED_PATTERNS=(
  'rm[[:space:]]+-rf[[:space:]]+/'
  'rm[[:space:]]+-rf[[:space:]]+\$HOME'
  'rm[[:space:]]+-rf[[:space:]]+~'
  'DROP[[:space:]]+DATABASE'
  'DROP[[:space:]]+TABLE[[:space:]]+[^I]'  # allow DROP TABLE IF EXISTS
  'DELETE[[:space:]]+FROM[[:space:]]+\w+[[:space:]]*;'  # DELETE without WHERE
  'chmod[[:space:]]+-R[[:space:]]+777[[:space:]]+'
  'mkfs\.'
  '>[[:space:]]*/dev/sd'
  'dd[[:space:]]+if=.*of=/dev/sd'
  'kubectl[[:space:]]+delete[[:space:]]+namespace[[:space:]]+(kube-system|kube-public|default)'
  'terraform[[:space:]]+destroy[[:space:]]+-auto-approve'
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if echo "$CMD" | grep -qiE "$pattern"; then
    echo "BLOCKED by pre-bash hook: matches dangerous pattern."
    echo "Pattern: $pattern"
    echo "If you intend this, run it manually in the terminal."
    exit 1
  fi
done

exit 0
