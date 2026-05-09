#!/usr/bin/env bash
# Runs after Write/Edit tool calls. Validates the changed file by type.
# Outputs feedback to Claude (stdout). Never blocks (PostToolUse).

set -uo pipefail

INPUT=$(cat)

FILE=$(echo "$INPUT" | python3 -c "
import json, sys
d = json.load(sys.stdin)
inp = d.get('tool_input', {})
print(inp.get('file_path', ''))
" 2>/dev/null || true)

[[ -z "$FILE" || ! -f "$FILE" ]] && exit 0

case "$FILE" in
  *.tf)
    if command -v terraform &>/dev/null; then
      terraform fmt "$FILE" &>/dev/null && echo "[hook] terraform fmt applied: $FILE"
      cd "$(dirname "$FILE")" && terraform validate -no-color 2>&1 | grep -E "^(Error|Warning|Success)" || true
    fi
    ;;
  *.py)
    if command -v python3 &>/dev/null; then
      OUT=$(python3 -m py_compile "$FILE" 2>&1)
      if [[ -n "$OUT" ]]; then
        echo "[hook] Python syntax error in $FILE:"
        echo "$OUT"
      fi
    fi
    ;;
  *.yaml|*.yml)
    if command -v python3 &>/dev/null; then
      OUT=$(python3 -c "import yaml, sys; yaml.safe_load(open(sys.argv[1]))" "$FILE" 2>&1)
      if [[ -n "$OUT" ]]; then
        echo "[hook] YAML parse error in $FILE:"
        echo "$OUT"
      fi
    fi
    ;;
  *.json)
    if command -v python3 &>/dev/null; then
      OUT=$(python3 -m json.tool "$FILE" > /dev/null 2>&1 || python3 -m json.tool "$FILE" 2>&1)
      if [[ -n "$OUT" ]]; then
        echo "[hook] JSON parse error in $FILE:"
        echo "$OUT"
      fi
    fi
    ;;
esac

exit 0
