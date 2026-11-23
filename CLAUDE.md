# AirBuddy Aerospace — IoT_Communication

PCB-based axial-flux motors, sold B2B. This repo holds the electronics around them: the motor controller, a wireless remote, their firmware, and a browser control app.

> **AI output is a draft; every footprint, pinout and net must be checked against the datasheet.**
> This applies to anything Claude, an MCP server, or a library generator produces. Note the datasheet (file in `docs/datasheets/` or URL) next to each check.

## Boards

| Board | Folder | Status | Key specs |
|---|---|---|---|
| Motor controller | `hardware/motor-controller/` | Blank KiCad 10 project | Based on open-source VESC hardware. Low-voltage DC input, 12–60 V. TODO: continuous and peak phase current, max bus voltage including regen, MCU, gate driver, layer count, copper weight, board size |
| Wireless remote V1 | `hardware/remote-v1/` | Blank KiCad 10 project | Simple, battery powered. TODO: radio and protocol, battery chemistry and capacity, charging, MCU, enclosure |

Control software V1 is a web app for phone and laptop browsers, in `software/web-app/`. TODO: framework, and the link to the controller (BLE / Wi-Fi / via the remote).

Fab and assembly: **JLCPCB**. VESC hardware is CC-BY-SA. Keep its attribution in any derived design, and check the license before shipping.

## Folder map

```
hardware/<board>/        KiCad project; keep its files together. Project-local sym-lib-table/fp-lib-table.
hardware/libraries/      Shared libs: symbols/AirBuddy.kicad_sym, footprints/AirBuddy.pretty, 3dmodels/AirBuddy.3dshapes
firmware/<board>/        Firmware per board (motor controller: VESC bldc fork, ChibiOS + arm-none-eabi-gcc)
software/web-app/        Browser control app
docs/datasheets/         Datasheet PDFs, named <MPN>.pdf
docs/design-notes/       Calculations, decisions, bring-up logs
docs/reports/            Audit reports; kicad-check/ output is gitignored
production/<board>/<rev>/  Released Gerbers, BOM and CPL. Written only by scripts/fab-export.sh; never edited by hand
scripts/                 kicad-check.sh (ERC/DRC counts), fab-export.sh (JLCPCB outputs)
```

## Conventions

- **Library paths:** always `${KIPRJMOD}`-relative, e.g. `${KIPRJMOD}/../libraries/...`. Never absolute paths, never the global KiCad tables for custom parts. 3D model paths in footprints use `${KIPRJMOD}/../libraries/3dmodels/AirBuddy.3dshapes/<file>.step`.
- **Part numbers:** every assembled symbol has an `LCSC` field (e.g. `C1525`). `fab-export.sh` puts it in the BOM. Also fill `MPN` and `Manufacturer`.
- **Revisions:** `r1`, `r2`, … Each release goes to a new `production/<board>/<rev>/` folder. Tag the commit `<board>-<rev>`.
- **Before every commit touching hardware:** run `scripts/kicad-check.sh`. The counts must not get worse without a written reason.
- **KiCad files** are edited in KiCad. Claude reads them (MCP `kicad`, readonly) and does not hand-edit `.kicad_sch`/`.kicad_pcb` unless asked.
- **kicad-cli** is not on PATH: `/Applications/KiCad/KiCad.app/Contents/MacOS/kicad-cli`. The scripts find it automatically, or you can set `KICAD_CLI`. The `Fontconfig warning` lines it prints come from a Homebrew fontconfig and are harmless.
- **Firmware safety:** never flash or command a motor controller over serial or USB from Claude without a current-limited bench supply and the user's explicit go-ahead.

## Tools for Claude

- MCP `kicad` (kicad-mcp-pro 4.16.0, **readonly** profile): `kicad_set_project`, `run_erc`, `run_drc`, `validate_design`, `dfm_run_manufacturer_check`, `sch_get_connectivity_graph`, `lib_verify_component_contract`, … It writes reports to `hardware/<board>/output/` (gitignored). For exports, use `scripts/fab-export.sh`, not the MCP.
- MCP `jlcpcb-search` (jlcpcb-search-mcp 1.2.1): `search_components` (search by MPN; plain-text searches like "100nF 0402" often return nothing), `get_component_details` (by LCSC code). Manufacturer and Package often come back `None`, so confirm on jlcpcb.com.
- Skills: `pcb-design-rules`, `bom-check`, `design-review`, `fab-export` in `.claude/skills/`.
