#!/usr/bin/env bash

set -euo pipefail

LCOV_FILE="coverage/lcov.info"
THRESHOLD_PERCENT="100.00"

if [[ ! -f "$LCOV_FILE" ]]; then
  echo "Coverage file not found: $LCOV_FILE"
  echo "Run 'flutter test --coverage' before running this check."
  exit 1
fi

# Scope: framework package code only.
is_in_scope() {
  local path="$1"
  [[ "$path" =~ (^|/)lib/src/ ]] || [[ "$path" =~ (^|/)lib/arcane_framework\.dart$ ]]
}

total_lines=0
covered_lines=0
in_scope_files=0

while IFS= read -r line; do
  if [[ "$line" == SF:* ]]; then
    current_file="${line#SF:}"
    current_in_scope=0
    if is_in_scope "$current_file"; then
      current_in_scope=1
      ((in_scope_files += 1))
    fi
    continue
  fi

  if [[ "$line" == DA:* ]] && [[ "${current_in_scope:-0}" -eq 1 ]]; then
    payload="${line#DA:}"
    line_number="${payload%%,*}"
    rest="${payload#*,}"
    hits="${rest%%,*}"

    if [[ "$line_number" =~ ^[0-9]+$ ]] && [[ "$hits" =~ ^[0-9]+$ ]]; then
      ((total_lines += 1))
      if [[ "$hits" -gt 0 ]]; then
        ((covered_lines += 1))
      fi
    fi
  fi
done < "$LCOV_FILE"

if [[ "$in_scope_files" -eq 0 ]]; then
  echo "No in-scope files were found in $LCOV_FILE."
  exit 1
fi

if [[ "$total_lines" -eq 0 ]]; then
  echo "No in-scope executable lines were found in $LCOV_FILE."
  exit 1
fi

coverage_percent=$(awk -v covered="$covered_lines" -v total="$total_lines" 'BEGIN { printf "%.2f", (covered / total) * 100 }')

echo "Scoped line coverage: $coverage_percent% ($covered_lines/$total_lines)"
echo "Scope: lib/src/** and lib/arcane_framework.dart"

if awk -v actual="$coverage_percent" -v required="$THRESHOLD_PERCENT" 'BEGIN { exit (actual + 0.0 >= required + 0.0 ? 0 : 1) }'; then
  echo "Coverage gate passed (>= $THRESHOLD_PERCENT%)."
else
  echo "Coverage gate failed: required $THRESHOLD_PERCENT%, got $coverage_percent%."
  exit 1
fi