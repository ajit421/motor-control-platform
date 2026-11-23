---
name: fab-export
description: Generate JLCPCB manufacturing outputs (Gerbers + drill zip, BOM, CPL) for a board revision into production/<board>/<rev>/ using kicad-cli. Use when the user wants to order boards, "export gerbers", "make the fab files", or release a revision.
---

# Fab export (JLCPCB)

## Steps
1. **Preconditions.** Ask for whatever is missing:
   - the design review is done (the `design-review` skill), with no FAIL items
   - `bom-check` has been run, and every assembled part has an `LCSC` field
   - the working tree is committed (`git status` clean), so the output can be traced to a commit
   - a revision name, e.g. `r1`, that has not been used in `production/<board>/`
2. **Export** from the repo root:
   ```bash
   scripts/fab-export.sh hardware/<board> <rev>
   ```
   The script refuses to run if ERC/DRC has errors or the revision folder exists. Don't work around either; fix the cause or use a new revision.
   It writes to `production/<board>/<rev>/`:
   - `<board>-<rev>-gerbers.zip`: copper, paste, silk, mask, Edge.Cuts, Excellon drill (mm, decimal, absolute origin), drill map, gbrjob. Uses Protel extensions; "subtract soldermask from silkscreen" and "check zones" are on, per JLCPCB's KiCad guide.
   - `<board>-<rev>-bom.csv`: columns Comment, Designator, Footprint, LCSC Part #. DNP parts are excluded.
   - `<board>-<rev>-cpl.csv`: columns Designator, Val, Package, Mid X, Mid Y, Rotation, Layer, in mm. DNP parts are excluded.
   - `SOURCE_COMMIT.txt`: the git commit the outputs came from. If it ends in `-dirty`, the export is not traceable; redo it from a clean commit.
3. **Check before upload:**
   - Open the zip in KiCad's GerbView, or JLCPCB's online viewer, and check the outline, drills, mask openings and silkscreen.
   - Upload the BOM and CPL in JLCPCB's assembly step and **check part rotations in their placement preview.** KiCad and JLCPCB rotation zero-points differ for some packages (SOT-23, some ICs, polarized parts). `fab-export.sh` does not apply rotation offsets, so fix them in JLCPCB's preview or in the CPL. Record every fix in `docs/design-notes/<board>-<rev>-fab-notes.md`.
   - JLCPCB's BOM page names the required columns (Comment, Designator, Footprint) but gives no exact header text for the LCSC column. If their importer doesn't auto-map "LCSC Part #", map it by hand.
4. **Commit and tag:** `git add production/<board>/<rev> docs/design-notes && git commit -m "Release <board> <rev>"`, then `git tag <board>-<rev>`. Do not push unless the user asks.

## Notes
- For 4+ layer boards, the script adds the inner layers (In1.Cu…) to the Gerbers automatically. Check the layer count in the zip.
- Outputs are never edited after release. Any change, even a fix, needs a new revision.
- `kicad-cli` path: `/Applications/KiCad/KiCad.app/Contents/MacOS/kicad-cli`, or set `KICAD_CLI`.
