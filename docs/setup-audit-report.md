# Setup audit report — KiCad tooling and repo structure

Date: 2026-11-23 · Branch: `chore/kicad-setup-and-reorg` · Machine: macOS 27.2.1 (arm64)

## 1. Audit findings (Phase 1)

**The repo was empty.** `~/Code/IoT_Communication` had no files and was not a git repository. A search of the home folder 8 levels deep found no `.kicad_pro`/`.kicad_sch`/`.kicad_pcb`, no `sym-lib-table`, and no VESC files. The brief's path `D:\Code\IoT_Communication` is a Windows path, so the real design files may be on another machine.
On the owner's instruction ("install and set up everything"), the work went ahead as a **greenfield setup**. With nothing to move, there was no reorganization, no old→new path mapping, and no pre-existing design to baseline.

### Tool versions
| Tool | Version | Note |
|---|---|---|
| KiCad / kicad-cli | 10.0.8 | `kicad-cli` is **not on PATH**: `/Applications/KiCad/KiCad.app/Contents/MacOS/kicad-cli` |
| Python | 3.15.2 (Homebrew), 3.15.1 (python.org), 3.9.6 (system) | uv-managed 3.14 added for the MCP servers |
| uv / uvx | 0.13.6 | |
| Node / npm | 24.22.1 / 11.19.1 | |
| git | 2.54.0 | |
| Claude Code | 2.1.322 | |

### Existing Claude setup
- No global or project `CLAUDE.md`. User skills are design and UI only. Nothing for KiCad or JLCPCB was installed.
- User plugins include boardrepo (**needs authentication**), clangd-lsp, context7, pdf-viewer, code-review and claude-security.
- The `github` plugin MCP **fails to connect** ("Authorization header is badly formatted"). Fix it before using Claude for PRs.
- KiCad 10 global `sym-lib-table`/`fp-lib-table` hold only the stock KiCad libraries, with no custom global libraries.

### Problems found
- `kicad-cli` is not on PATH. The scripts find it automatically.
- On every `kicad-cli` run, a Homebrew `fontconfig` config at `/opt/homebrew/etc/fonts/conf.d/` prints about 50 `Fontconfig warning` lines. The warnings are harmless, but they hide real output. Fixing that Homebrew install (or `brew reinstall fontconfig`) is optional.
- KiCad 10 creates a `.history/` folder containing a **nested `.git`** in each project when the project is opened. It's now gitignored. It must never be committed.
- No secrets, binaries, generated files or duplicates, since there were no files at all.

### Baseline ERC/DRC (blank projects, `scripts/kicad-check.sh`)
| Project | ERC err | ERC warn | DRC err | DRC warn | Unconnected | Parity |
|---|---|---|---|---|---|---|
| motor-controller | 0 | 0 | 1 | 0 | 0 | 0 |
| remote-v1 | 0 | 0 | 1 | 0 | 0 | 0 |

The DRC error is `invalid_outline` (no Edge.Cuts outline yet). It's expected and clears once a board outline is drawn.

## 2. Tooling evaluation (Phase 2) — sources read 2026-11-23

### KiCad MCP — **chosen: kicad-mcp-pro 4.16.0** (oaslananka, AGPL-3.0, PyPI)
| Candidate | Verdict | Why |
|---|---|---|
| **kicad-mcp-pro** | ✅ Installed | KiCad 10 is its primary target. **Read-only by default** (verified: 25 tools in readonly mode, no edit or export tools). Sandboxed to a workspace root. Runs headless through kicad-cli, with no running KiCad needed. Installs from PyPI, pinned. |
| mixelpixx/KiCAD-MCP-Server | ❌ | Most popular (MIT), but it installs through an unpinned git clone, npm build and pip. It downloads a Freerouting jar with curl and a 3–5 GB parts DB. With no mode set, it defaults to **write** mode. |
| ProductOfAmerica/mcp-server-kicad | ❌ | In maintenance mode since Oct 2026. No read-only mode. Its author's own benchmark found plain Claude Code more accurate than with the plugin. |

The version is pinned to **4.16.0, not the latest (4.22.0).** The project shipped 86 releases since June 2026, about 1–3 per day lately, from a single maintainer. 4.22.0 was hours old at the time of the check. 4.16.0 (2026-11-15) needed no follow-up patch. Upgrade deliberately, after reading the changelog.
AGPL applies to the tool itself, not to your designs, because you run it unmodified on your own machine.

### JLCPCB/LCSC parts MCP — **chosen: jlcpcb-search-mcp 1.2.1** (peterb154, MIT, PyPI)
| Candidate | Verdict | Why |
|---|---|---|
| **jlcpcb-search-mcp** | ✅ Installed | Read-only search with Basic/Extended flag, stock, price breaks and datasheet links (verified: searched `STM32F405`). Data comes from the public yaqwsx/jlcparts dataset. No API keys, no install scripts. |
| @jlcpcb/mcp ("jlc-mcp") | ❌ **Rejected: suspicious install instructions** | Not affiliated with JLCPCB, despite the `@jlcpcb` npm scope. Its README's install command, `npx -y jlc-mcp@latest`, names an **unregistered** npm package that anyone could claim. It links to a repo that returns 404. It writes libraries to disk and documents only KiCad 9. |

The two parts tools don't overlap: kicad-mcp-pro only prices a finished BOM, while jlcpcb-search finds parts.
Caveats: last release was 2026-04-29, with an unpinned `fastmcp` dependency that could break on a future fastmcp release. It needs a 1.5 GB local DB in `~/Library/Application Support/jlcpcb-mcp/` (an 8-minute one-time download). Manufacturer and Package often come back `None`. Plain-text searches ("100nF 0402") returned nothing, so search by MPN or LCSC code.

### Other plugins and skills — **nothing extra installed**
- The official plugin marketplace has no embedded, STM32, PlatformIO, serial or datasheet plugin.
- Datasheets: Claude reads PDFs natively, and pdf-viewer is installed.
- Firmware: VESC is ChibiOS + make, and the clangd-lsp and context7 you already have cover it.
- Not installed: `pyserial-mcp` (serial monitor). It can *write* to a powered 12–60 V controller. Revisit it during remote bring-up, on a current-limited bench supply.
- Not installed: embedded-debugger-mcp. It has no releases and is build-from-source only.

### Exact install commands used
```bash
claude mcp add kicad --scope project \
  -e KICAD_MCP_KICAD_CLI=/Applications/KiCad/KiCad.app/Contents/MacOS/kicad-cli \
  -e KICAD_MCP_PROFILE=default -e KICAD_MCP_OPERATING_MODE=readonly -e KICAD_MCP_WORKSPACE_ROOT=. \
  -- uvx --python 3.14 kicad-mcp-pro==4.16.0 --transport stdio
claude mcp add jlcpcb-search --scope project -- uvx --python 3.14 --from jlcpcb-search-mcp==1.2.1 jlcpcb-mcp
```
Config lives in `.mcp.json` at the repo root, committed and shared. Python 3.14 is used because kicad-mcp-pro lists only 3.13 and 3.14 as supported. uv downloaded it to `~/.local/share/uv/python/`.

### Verification performed
- Each server was started with a stdio MCP client, and its tools listed and called.
- kicad: `kicad_get_version` returned CLI 10.0.8. `kicad_set_project` was pointed at motor-controller. `run_erc` gave 0 violations and `run_drc` gave 1 (`invalid_outline`), matching the baseline.
- jlcpcb-search: `database_status`, then `search_components` (STM32F405) returned 9 parts, with Extended flag, stock and pricing.
- `claude mcp list` shows both as **"Pending approval"**. Claude Code asks you to approve project-scoped servers the first time you run `claude` in this repo. Approve both.

## 3. Folder structure (greenfield)

```
.
├── CLAUDE.md
├── .mcp.json
├── .claude/skills/{pcb-design-rules,bom-check,design-review,fab-export}/SKILL.md
├── hardware/
│   ├── motor-controller/   motor-controller.kicad_{pro,sch,pcb}, sym-lib-table, fp-lib-table
│   ├── remote-v1/          remote-v1.kicad_{pro,sch,pcb}, sym-lib-table, fp-lib-table
│   └── libraries/          symbols/AirBuddy.kicad_sym, footprints/AirBuddy.pretty/, 3dmodels/AirBuddy.3dshapes/
├── firmware/{motor-controller,remote-v1}/
├── software/web-app/
├── docs/{datasheets,design-notes,reports}/   + this report
├── production/             <board>/<rev>/ written by scripts/fab-export.sh
└── scripts/                kicad-check.sh, fab-export.sh
```

Changes from the suggested layout: `scripts/` was added for the check and export tools.
Both project lib tables use `${KIPRJMOD}/../libraries/...`. A resolution check confirmed all 4 paths point at existing files.
Old→new mapping: none, since there were no existing files.

## 4. Risks

1. **Importing the existing VESC-based design** (wherever it lives) is the real migration still to do. VESC hardware repos often reference libraries by absolute or global paths. When you import:
   - copy the project into `hardware/motor-controller/`
   - move custom symbols and footprints into `hardware/libraries/`
   - rewrite the lib tables to `${KIPRJMOD}`
   - run `scripts/kicad-check.sh` before and after, and compare
   Missing libraries show up as "?" symbols or missing footprints, and as new ERC/DRC/parity counts.
2. **Embedded 3D model paths.** Footprints often hard-code model paths like `${KICAD8_3DMODEL_DIR}` or absolute paths, and these break silently (no DRC error, just missing 3D). Grep for `(model ` after importing.
3. **kicad-mcp-pro churn.** It releases daily. The pinned version may fall behind KiCad patches; latest verified upstream is 10.0.7 and you run 10.0.8.
4. **jlcpcb-search staleness.** The project is 7 months old with an unpinned dependency. If it breaks, pin `fastmcp` with `uvx --with fastmcp==<ver>`.
5. **Absolute kicad-cli path** in `.mcp.json` assumes macOS with KiCad in `/Applications`. Windows teammates need a local override (`claude mcp add --scope local …`).
6. **VESC license.** VESC hardware is CC-BY-SA, so derived boards must keep attribution and share-alike. Check this before selling B2B.

## 5. Suggestions

- **CI:** a GitHub Action that installs KiCad 10 and runs `scripts/kicad-check.sh` on every PR touching `hardware/`. The script already exits non-zero on errors.
- **Pre-commit hook** running `kicad-check.sh` when `.kicad_*` files change.
- **Git LFS** for `docs/datasheets/*.pdf` and `hardware/libraries/3dmodels/**/*.step` before they grow.
- **Templates:** `docs/design-notes/TEMPLATE-bringup.md` (power-up sequence, current limits, measurements), and a part-qualification record per new part (datasheet, footprint check, LCSC code, second source).
- **KiCad design rules:** fill the TODOs in the `pcb-design-rules` skill, then encode them as net classes plus a custom `.kicad_dru` file, so DRC enforces them.
- **Stackup:** decide the motor controller's layer count and copper weight early, since the trace and clearance numbers depend on them.
- **Fix** the github plugin auth and authenticate boardrepo (useful for comparing against published VESC-class boards).
