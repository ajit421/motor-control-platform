#!/usr/bin/env bash
# Generate JLCPCB fab + assembly outputs (Gerbers zip, BOM, CPL) for one board revision.
# Usage: scripts/fab-export.sh <board-dir> <rev> [out-dir]
#   e.g. scripts/fab-export.sh hardware/motor-controller r1   -> production/motor-controller/r1/
# Refuses to run if ERC/DRC has errors or the output folder already exists (released outputs are immutable).
# Settings follow JLCPCB's KiCad guide (Protel extensions, subtract mask from silk, check zones,
# Excellon mm / decimal / absolute origin / alternate oval mode, drill map) — checked 2026-11-23.
set -euo pipefail
K="${KICAD_CLI:-$(command -v kicad-cli || echo /Applications/KiCad/KiCad.app/Contents/MacOS/kicad-cli)}"
src="${1:?board dir, e.g. hardware/motor-controller}"; rev="${2:?revision, e.g. r1}"
b=$(basename "$src"); pcb="$src/$b.kicad_pcb"; sch="$src/$b.kicad_sch"
[ -f "$pcb" ] && [ -f "$sch" ] || { echo "missing $pcb or $sch" >&2; exit 2; }
root="$(cd "$(dirname "$0")/.." && pwd)"
out="${3:-$root/production/$b/$rev}"
[ -e "$out" ] && { echo "$out already exists; use a new revision" >&2; exit 2; }

"$K" sch erc --severity-error --exit-code-violations -o /dev/null "$sch" >/dev/null 2>&1 || { echo "ERC has errors; fix before export" >&2; exit 1; }
"$K" pcb drc --severity-error --schematic-parity --exit-code-violations -o /dev/null "$pcb" >/dev/null 2>&1 || { echo "DRC has errors; fix before export" >&2; exit 1; }

mkdir -p "$out/gerbers"
# Copper layers actually present in this board (F.Cu, B.Cu + any In*.Cu).
inner=$(grep -oE '"In[0-9]+\.Cu"' "$pcb" | tr -d '"' | sort -uV | paste -sd, - || true)
layers="F.Cu,B.Cu${inner:+,$inner},F.Paste,B.Paste,F.Silkscreen,B.Silkscreen,F.Mask,B.Mask,Edge.Cuts"
"$K" pcb export gerbers --layers "$layers" --subtract-soldermask --check-zones -o "$out/gerbers" "$pcb" 2>/dev/null
"$K" pcb export drill --format excellon --drill-origin absolute --excellon-units mm \
  --excellon-zeros-format decimal --excellon-oval-format alternate --generate-map --map-format gerberx2 \
  -o "$out/gerbers" "$pcb" 2>/dev/null
(cd "$out/gerbers" && zip -q "../$b-$rev-gerbers.zip" ./*)

# BOM: symbols carry their LCSC part number in a field named "LCSC" (see CLAUDE.md).
"$K" sch export bom --fields 'Value,Reference,Footprint,LCSC' --labels 'Comment,Designator,Footprint,LCSC Part #' \
  --group-by 'Value,Footprint,LCSC' --ref-range-delimiter '' --exclude-dnp \
  -o "$out/$b-$rev-bom.csv" "$sch" 2>/dev/null

# CPL: KiCad's CSV with headers renamed to JLCPCB's (Designator, Mid X, Mid Y, Rotation, Layer; mm).
tmp="$out/.pos.csv"
"$K" pcb export pos --format csv --units mm --side both --exclude-dnp -o "$tmp" "$pcb" 2>/dev/null
hdr='Ref,Val,Package,PosX,PosY,Rot,Side'
[ "$(head -1 "$tmp" | tr -d '"')" = "$hdr" ] || { echo "unexpected pos header: $(head -1 "$tmp")" >&2; exit 1; }
{ echo 'Designator,Val,Package,Mid X,Mid Y,Rotation,Layer'; tail -n +2 "$tmp"; } > "$out/$b-$rev-cpl.csv"
mv "$tmp" "$out/gerbers/kicad-pos-raw.csv.txt"  # keep the raw file for traceability, outside the upload zip

git -C "$root" describe --always --dirty > "$out/SOURCE_COMMIT.txt" 2>/dev/null || true
echo "Wrote $out:"; ls -1 "$out"
