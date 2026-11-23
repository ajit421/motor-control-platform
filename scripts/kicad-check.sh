#!/usr/bin/env bash
# Run ERC + DRC (with schematic parity) on every KiCad project under hardware/ and print counts.
# Usage: scripts/kicad-check.sh [report-dir]   (default: docs/reports/kicad-check)
# Exits 1 if any error-severity violation exists, so it can gate CI.
set -euo pipefail
cd "$(dirname "$0")/.."
K="${KICAD_CLI:-$(command -v kicad-cli || echo /Applications/KiCad/KiCad.app/Contents/MacOS/kicad-cli)}"
out="${1:-docs/reports/kicad-check}"
mkdir -p "$out"

shopt -s nullglob
pros=(hardware/*/*.kicad_pro)
[ ${#pros[@]} -gt 0 ] || { echo "no KiCad projects under hardware/" >&2; exit 2; }

errors=0
printf '%-20s %8s %8s %8s %8s %10s %8s\n' project erc_err erc_warn drc_err drc_warn unconnect parity
for pro in "${pros[@]}"; do
  d=$(dirname "$pro"); b=$(basename "$pro" .kicad_pro)
  rm -f "$out/$b-erc.json" "$out/$b-drc.json"  # never read a stale report from a previous run
  # 2>/dev/null hides Homebrew fontconfig noise; a failed run still fails via missing JSON below.
  "$K" sch erc --format json --severity-all -o "$out/$b-erc.json" "$d/$b.kicad_sch" >/dev/null 2>&1 || true
  "$K" pcb drc --format json --severity-all --schematic-parity -o "$out/$b-drc.json" "$d/$b.kicad_pcb" >/dev/null 2>&1 || true
  row=$(python3 -I - "$out/$b-erc.json" "$out/$b-drc.json" <<'PY'
import json, sys
erc, drc = (json.load(open(p)) for p in sys.argv[1:3])
ev = [v for s in erc["sheets"] for v in s["violations"]]
sev = lambda vs, s: sum(v["severity"] == s for v in vs)
dv = drc["violations"]
print(sev(ev, "error"), sev(ev, "warning"), sev(dv, "error"), sev(dv, "warning"),
      len(drc.get("unconnected_items", [])), len(drc.get("schematic_parity", [])))
PY
  ) || { echo "$b: ERC/DRC did not produce a report (library or file load failure?)" >&2; exit 2; }
  read -r ee ew de dw un pa <<<"$row"
  printf '%-20s %8s %8s %8s %8s %10s %8s\n' "$b" "$ee" "$ew" "$de" "$dw" "$un" "$pa"
  errors=$((errors + ee + de + un + pa))
done
[ "$errors" -eq 0 ]
