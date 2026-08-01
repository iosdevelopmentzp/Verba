#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/Verba"
fail=0

report() {
  local label="$1" hits="$2"
  if [ -n "$hits" ]; then
    echo "check-layers: $label"
    echo "$hits"
    fail=1
  fi
}

if [ -d "$ROOT/Domain" ]; then
  hits=$(grep -rEn '^\s*import\s+\w+' "$ROOT/Domain" --include='*.swift' 2>/dev/null \
    | grep -Ev 'import\s+Foundation\s*$' || true)
  report "Domain must only import Foundation" "$hits"
fi

if [ -d "$ROOT/Presentation" ]; then
  hits=$(grep -rEln 'URLSession|NSPasteboard|SecItem' "$ROOT/Presentation" --include='*.swift' 2>/dev/null || true)
  report "Presentation must not use Data-layer APIs directly" "$hits"
fi

if [ -d "$ROOT/Data" ]; then
  hits=$(grep -rEln '^\s*import\s+SwiftUI' "$ROOT/Data" --include='*.swift' 2>/dev/null || true)
  report "Data must not import SwiftUI" "$hits"
fi

if [ "$fail" -ne 0 ]; then
  echo "check-layers: layer boundary violation(s) found."
  exit 1
fi

echo "check-layers: OK"
