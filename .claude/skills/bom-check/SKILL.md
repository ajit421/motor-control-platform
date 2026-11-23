---
name: bom-check
description: Check a board's BOM for JLCPCB assembly — Basic vs Extended parts, stock, single-source risk, component derating. Use before ordering, after BOM changes, or when the user asks "is this BOM OK / cheap / buildable".
---

# BOM check

## Inputs
1. Export the BOM: `scripts/fab-export.sh` writes `production/<board>/<rev>/<board>-<rev>-bom.csv`. For a quick look without releasing, use `kicad-cli sch export bom` with the same `--fields` as in that script.
2. For each line, look up its LCSC code with MCP `jlcpcb-search` → `get_component_details {"query":{"lcsc":"Cxxxx"}}`.
   This gives Basic/Extended, stock, price breaks and a datasheet link. It returns Manufacturer and Package as `None` for many parts, so take those from the datasheet or jlcpcb.com.
3. Optional: MCP `kicad` → `lib_get_bom_with_pricing` for an overall cost.

## Thresholds (company decisions; ask the user if these are still TODO)

| Rule | Value |
|---|---|
| Build quantity for the stock check | TODO units |
| Minimum JLC stock per part | TODO × (qty per board × build qty) |
| Max Extended parts per board | TODO. Each Extended part adds a setup fee; the amount is TODO (not stated on the JLC pages checked 2026-11-23) |
| Capacitor voltage derating (MLCC: also check DC-bias capacitance loss) | rated ≥ TODO × working voltage |
| Electrolytic / polymer capacitor | rated ≥ TODO × working voltage; ripple current ≥ calculated ripple + TODO % |
| MOSFET V_DS | ≥ TODO × max bus voltage including transients |
| MOSFET / power part current | ≤ TODO % of rating at max case temperature |
| Resistor power | ≤ TODO % of rating |
| Operating temperature range | parts rated for TODO °C to TODO °C |

## Checks, per line — report as a table

| Check | Flag when |
|---|---|
| Missing LCSC field | blank or not found → **BLOCKER** |
| Basic vs Extended | Extended → say whether a Basic part could do the job |
| Stock | below the threshold → **RISK** |
| Single source | only one LCSC code or manufacturer fits, with no drop-in alternative → **SINGLE-SOURCE**; suggest a second source |
| Lifecycle | NRND / EOL / obsolete on the datasheet or the manufacturer's site → **RISK** |
| Derating | against the table above, using actual working values from the schematic → **FAIL** with the numbers shown |
| Footprint match | the BOM footprint vs the LCSC package (from the datasheet) differ → **BLOCKER** |
| Value sanity | the Comment/Value doesn't match the LCSC part (e.g. 100nF vs 1µF) → **BLOCKER** |

## Output
End the table with a summary: counts of BLOCKER / FAIL / RISK / SINGLE-SOURCE, the number of Extended parts, and the estimated BOM cost at build quantity. List every assumption.
Reminder: AI output is a draft. Every substitution must be checked against its datasheet before it goes in the schematic.
