# Tooling audit — MCP servers, plugins, skills, marketplaces

Date: 2026-11-23 · Claude Code 2.1.322 (VS Code extension) · macOS 27.2.1
Method: `claude mcp list`, `claude plugin list`, `claude plugin marketplace list`, plugin cache and marketplace manifests on disk, and one read-only tool call per server.
**"Working" means a tool call succeeded in this session.** The two project servers are pending approval in Claude Code, so I called their tools directly over MCP stdio with the same command and env as `.mcp.json`.

## 1. MCP servers

Scope key: **claude.ai** = a connector on the claude.ai account, synced into every Claude Code session; **plugin** = comes with a user-scope plugin; **project** = `.mcp.json` in this repo.

| Name | Type / scope | Tools | Status | Tested? (call → result) | Useful here? | Recommendation |
|---|---|---|---|---|---|---|
| kicad (kicad-mcp-pro 4.16.0) | project | 25 | Pending approval | ✅ `validate_design` on remote-v1 → ran; `run_drc` matched the baseline | **Yes, core** | **Keep.** Approve in Claude Code. Pin transitive deps (§5) |
| jlcpcb-search (1.2.1) | project | 4 | Pending approval | ✅ `search_components "10k 0603 resistor"` → 10 parts; ⚠ `get_component_details C25804` → **stock 0** and no Basic/Extended flag | **Yes, core** | **Keep, but cross-check stock and Basic flags on jlcpcb.com.** Pin transitive deps (§5) |
| plugin:context7 | plugin (user) | 2 | Connected | ✅ `resolve-library-id KiCad` → 5 libraries | Yes (KiCad, ESP-IDF, STM32 HAL, web docs) | **Keep** |
| claude.ai Context7 | claude.ai | 2 | Connected | ✅ `resolve-library-id ESP-IDF` → 5 libraries | Duplicate | **Disable for this project** (exact duplicate of the plugin) |
| plugin:github | plugin (user) | ? | ✘ HTTP 400 | ❌ not callable | Yes, once a GitHub remote exists | **Fix** (§4) |
| plugin:boardrepo | plugin (user) | 15 (per README) | Needs auth | ❌ not callable | Some: reference VESC-class boards, DRC against fab limits | **Review security, then fix** (§4) |
| plugin:pdf-viewer (`pdf`) | plugin (synced) | 3 | Connected | ✅ `list_pdfs` → allowed dir = this repo | Yes (datasheets, annotate) | **Keep.** Its install command is unpinned (§5) |
| claude.ai PDF Viewer | claude.ai | 2 | Connected | ✅ `list_pdfs` → empty | Duplicate | **Remove.** Hosted at `example-server.modelcontextprotocol.io`, a public *demo* server: PDFs you open go to a third party. The plugin version runs locally |
| plugin:chrome-devtools | plugin (user) | 32 | Connected | ✅ `list_pages` → about:blank | Yes, later (web-app debugging and Lighthouse) | **Keep** |
| plugin:firebase | plugin (user) | 19 | Connected | ✅ `firebase_get_environment` → logged in, no Firebase project here | No (no Firebase in this repo) | **Disable for this project.** Unpinned `firebase-tools@latest`, signed-in Google identity, can deploy and create projects |
| plugin:cloudflare | plugin (user) | 5 | Connected | ✅ `search` → 2,354 API paths | Maybe (if the web app is hosted on Cloudflare) | **Disable for this project** until the hosting is chosen |
| claude.ai Google Drive | claude.ai | 15 | Connected | ✅ `search_files` (title has kicad/vesc) → 2 KiCad Python scripts and the 18 Nov motor/controller staff-meeting minutes. **No KiCad projects in Drive** | Yes (specs, meeting minutes, datasheets) | **Keep** |
| claude.ai Google Docs | claude.ai | 2 | Connected | ✅ `read_doc` on the 18 Nov minutes → returned (298 k chars; content not reviewed) | Yes (minutes likely hold controller specs for the CLAUDE.md TODOs) | **Keep** |
| claude.ai Google Sheets | claude.ai | 9 | Connected | ✅ `get_spreadsheet` (title only) → OK | Low (BOM costing later) | **Keep**; low risk |
| claude.ai Google Slides | claude.ai | 4 | Connected | ✅ `read_presentation` (title only) → OK | Low | **Disable for this project** |
| claude.ai Gmail | claude.ai | 31 | Connected | ✅ `list_labels` → OK | No | **Disable for this project.** Has send, forward and trash tools |
| claude.ai Google Calendar | claude.ai | 9 | Connected | ✅ `list_calendars` → 2 calendars | No | **Disable for this project** |
| claude.ai AirBuddy WorkSpace | claude.ai | 41 | Connected | ✅ `whoami` → admin role with HR, finance, roadmap-edit and inventory permissions | Some (logging hardware milestones) | **Review security.** Admin-level HR and finance write access is reachable from a hardware repo. It's also signed in as a different company account than the Google connectors. Keep, but use only on request |
| claude.ai Claude Docs | claude.ai | 8 | Connected | ✅ `guide topic.index` → OK | Some (shareable design notes) | Keep |
| claude.ai Claude Data | claude.ai | 11 | Connected | ✅ `list_certified_queries` → none | No | **Disable for this project** |
| claude.ai Meetings | claude.ai | 5 | Connected, but unusable | ❌ `list_meetings` → "lacks project access (user:projects:read)… public releases of Claude Code don't [ask for it]" | No | **Disable for this project.** It can't work in Claude Code |
| claude.ai Fireflies | claude.ai | 22 | Connected | ✅ `fireflies_get_user` → OK | Low | **Disable for this project** |
| claude.ai Excalidraw | claude.ai | 2 | Connected | ✅ `read_me` → OK | Some (block diagrams, power-tree sketches) | Keep |
| claude.ai Canva | claude.ai | 45 | Connected | ✅ `help` → OK | No | **Disable for this project** |
| easel (`chart`) | plugin tool | 1 | Loaded | ⏭ not tested: render-only, no read-only call | Low | Keep (harmless) |
| claude.ai Slack, Notion, monday.com, Linear, Intercom, HubSpot, Figma, Box, Atlassian, Asana, Fathom, Vercel, Wix, Attention | claude.ai | — | Needs auth | ⏭ not tested: no sign-in held; a reconnect via tool search returned no tools | No, for this repo | **Leave signed out.** Remove unused ones at claude.ai → Settings → Connectors |

## 2. Plugins (all user scope, all enabled)

| Plugin | Source | Useful here? | Recommendation |
|---|---|---|---|
| boardrepo 1.0.0 | Anthropic Directory (Flintt, Inc., MIT; directory review state **"none"**) | Some | See §4 |
| context7 | official | Yes | Keep |
| github | official | Yes, once there's a remote | Fix (§4) |
| clangd-lsp | official | Yes (STM32/ESP32 C firmware) | Keep |
| typescript-lsp | official | Yes (web app) | Keep |
| pyright-lsp | official | Some (Python scripts) | Keep |
| chrome-devtools-mcp 1.11.0 | official | Later (web app) | Keep. The install warned that package.json `overrides` weren't applied |
| frontend-design | official | Yes (web app UI) | Keep |
| code-review, pr-review-toolkit, commit-commands, claude-md-management | official | Yes | Keep. code-review and pr-review-toolkit overlap; pick one per review |
| claude-security, security-guidance | official | Yes (the web app will hold device control) | Keep. Note: security-guidance writes `sg-*` hook state files inside `.git/` |
| firebase | official | No | Disable for this project |
| cloudflare 1.0.4 | cloudflare marketplace (Cloudflare) | Maybe | Disable for this project until hosting is chosen |
| ponytail 5.3.3 | `DietrichGebert/ponytail` (third party) | Style preference | **Review security.** It's a third-party plugin that injects instructions through a SessionStart hook in every session. Keep only if you want that style |
| pdf-viewer 0.2.0, modern-web-guidance 0.0.194 | synced from claude.ai | Yes / later | Keep |

## 3. Skills

| Location | Skills | Note |
|---|---|---|
| Project `.claude/skills/` | pcb-design-rules, bom-check, design-review, fab-export | Core. 39 TODO values still open |
| User `~/.claude/skills/` | banner-design, brand, design, design-system, security-audit, slides, ui-styling, ui-ux-pro-max (+2 synced) | Not for hardware. security-audit overlaps claude-security |
| Plugins | boardrepo, claude-security (+scan), claude-md-management ×2, frontend-design, ponytail ×5, cloudflare ×20+, chrome-devtools ×7, modern-web-guidance ×2, pdf-viewer ×5, code-review, commit-commands ×3, pr-review-toolkit | The cloudflare skills add a lot of noise to the skill list for a hardware repo. Disabling the plugin for this project removes them |

## 4. Fix steps for failing items (run these yourself; never paste tokens into chat)

**github plugin: HTTP 400 "Authorization header is badly formatted".**
Root cause: the plugin's `.mcp.json` sends `Authorization: Bearer ${GITHUB_PERSONAL_ACCESS_TOKEN}`. That variable is **not set**, so it sends an empty `Bearer` header. `gh` is installed but **not logged in**. This repo also has **no git remote**.
Steps: see the "github fix" row in §7.

**boardrepo: needs auth.**
- **Publisher:** Flintt, Inc. (boardrepo.com), MIT licence, from github.com/flintt-dev/boardrepo-plugin. Anthropic Directory review state is "none".
- **What it does:** 15 hosted tools, all documented as read-only. They search public PCB projects, and read schematic connectivity, BOMs and files. They run KiCad DRC/ERC and fab-limit checks on boards **hosted on boardrepo.com**.
- **Access requested:** BoardRepo OAuth. Public boards need no extra grant. Reading your own or private boards needs an explicit grant during sign-in.
- **Risk:** to check *your* boards it has to host them, which means uploading unreleased designs to a third party. Our local kicad MCP and `scripts/kicad-check.sh` already cover your own boards.
- **Recommendation:** authenticate for **public reference boards only**, and don't grant own-board access. Run `/mcp` in Claude Code, select `plugin:boardrepo:boardrepo`, then Authenticate.

**claude.ai Meetings:** this is a platform limit in Claude Code, so there's nothing to fix. Use it from claude.ai.

## 5. Security flags

| Item | Concern | Suggested action |
|---|---|---|
| jlcpcb-search, kicad (uvx) | Only the top package is pinned. **Observed in this session:** `fastmcp` moved from 4.2.4 to 4.2.5 between two runs with no change to the config | Add a constraints file, or move both into a locked `uv` tool environment (§7) |
| kicad-mcp-pro | One maintainer; 86 releases since June 2026 | Upgrade only deliberately, after reading the changelog |
| claude.ai PDF Viewer | Hosted on a public MCP *example* server | Remove |
| firebase plugin | `npx -y firebase-tools@latest` is unpinned; holds a Google login; can deploy | Disable here |
| pdf-viewer plugin | `npx -y @modelcontextprotocol/server-pdf` is unpinned | Accept (official MCP org) or pin |
| ponytail | Third-party hooks run every session | Review the hook source; keep or uninstall |
| AirBuddy WorkSpace | Admin HR and finance write scope in every session | Disable here, or use only on explicit request |
| Directory plugins (BoardRepo, PartsPlan, ESP32-AI-Agent-Skill) | Directory review state "none" | Read the source before installing or granting access |
| `ui-ux-pro-max-skill` marketplace | Third-party marketplace configured, but no plugin installed from it | Remove the marketplace |

## 6. Marketplaces and relevant plugins

| Marketplace | Source | Plugins |
|---|---|---|
| claude-plugins-official | anthropics/claude-plugins-official | 317 |
| anthropic-plugin-directory | built-in (Anthropic Directory) | 3,779 listings |
| cloudflare | cloudflare/skills | 1 (cloudflare) |
| googlechrome | GoogleChrome/modern-web-guidance | 1 (modern-web-guidance) |
| ponytail | DietrichGebert/ponytail | 1 (ponytail) |
| ui-ux-pro-max-skill | nextlevelbuilder/ui-ux-pro-max-skill | 1 (ui-ux-pro-max): not installed as a plugin |

The official marketplace has **no** KiCad, PCB, parts-sourcing, STM32 or ESP32 plugin. The only embedded entry is cwc-makers (Cardputer onboarding), which doesn't apply here.

Plugins that would help:

| Plugin | Where | Area | Why (one line) |
|---|---|---|---|
| **PartsPlan** 1.3.0 | Directory (bboinzg-dev; review "none") | Datasheets, PCB, firmware | Finds the manufacturer datasheet page (pinout, register map, electrical table) behind each answer, which fits the "check against the datasheet" rule. Review the source first |
| **ESP32-AI-Agent-Skill** 1.0.0 | Directory (ezrover; review "none") | Firmware (remote) | ESP32 chip selection and GPIO-strapping checks, worth having only if the remote uses an ESP32. Review the source first |
| BoardRepo (installed) | Directory | PCB reference | See §4 |
| skill-creator | official | Process | Helps refine the 4 project skills and write new ones (e.g. bring-up) |
| playwright | official | Web app | E2E tests for the phone and laptop control UI. Overlaps chrome-devtools, so pick one when the app exists |
| typescript-lsp, clangd-lsp, frontend-design, github, context7 | official (installed) | Web app, firmware | Already covered |

## 7. Exact commands

Sources: code.claude.com docs (mcp, plugins/cli-reference, plugins/loading, env-vars, settings), checked 2026-11-23, plus `--help` on CLI 2.1.322.

| Action | Command | Notes |
|---|---|---|
| Approve the project servers | Run `claude` in this repo and accept `kicad` and `jlcpcb-search` | Team-wide alternative: `enabledMcpjsonServers` in `.claude/settings.json`. It's ignored until the folder is trusted. Undo with `claude mcp reset-project-choices` |
| Disable a claude.ai connector **for this project only** | In Claude Code: `/mcp`, select the connector, then disable it | Stored per project in `~/.claude.json` under `disabledMcpServers`, so it isn't committed. There's no per-connector key for a committed file. `disableClaudeAiConnectors` / `ENABLE_CLAUDEAI_MCP_SERVERS=false` turn off **all** connectors |
| Remove a claude.ai connector everywhere | claude.ai → Settings → Connectors | Use for the claude.ai PDF Viewer (demo server) |
| Disable a plugin for this project (team-wide) | `claude plugin disable firebase@claude-plugins-official --scope project` | Writes `false` to `.claude/settings.json`; a project `false` beats a user `true` |
| Disable a plugin for this project (just you) | same with `--scope local` | Writes `.claude/settings.local.json` (gitignored) |
| Uninstall a plugin | `claude plugin uninstall <name>@<marketplace>` | Default scope is user |
| Remove a marketplace | `claude plugin marketplace remove ui-ux-pro-max-skill` | This CLI version has no `--scope` option. Removing a marketplace also uninstalls its plugins |
| **github fix** | 1. Create a fine-grained PAT at github.com → Settings → Developer settings, limited to this repo (Contents, Pull requests, Issues: read/write). 2. Add `"env": {"GITHUB_PERSONAL_ACCESS_TOKEN": "<token>"}` to **`~/.claude/settings.json`** (user-level, never committed) by editing it yourself. 3. Restart VS Code. 4. Separately, for the `gh` CLI: `gh auth login` | The docs say settings `env` is applied however Claude Code launches, which matters for VS Code started from the Dock. A shell-profile `export` may not reach it. **Never** put the token in the project `.claude/settings.json`. It also needs a GitHub remote to be useful: `git remote add origin <url>` |
| boardrepo auth (public boards only) | `/mcp`, select `plugin:boardrepo:boardrepo`, then Authenticate, and decline own-board access | Interactive OAuth in the browser |
| Pin uvx transitive deps | Add `--with fastmcp==4.2.5` to the jlcpcb-search args in `.mcp.json` | UNVERIFIED that this holds the version; re-test after the change |
