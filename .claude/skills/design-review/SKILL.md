---
name: design-review
description: Pre-release design review checklist for AirBuddy boards (ERC/DRC clean, decoupling, test points, programming header, reverse-polarity and fuse protection, connector pinouts, thermal). Use before fab-export, when the user asks for a review of a schematic/PCB, or before a revision bump.
---

# Design review

Work through the checklist with evidence. Do not tick an item without saying what you checked and where (sheet/ref/net, datasheet page). Unknown means **OPEN**, not pass.

## 0. Automated gate
- [ ] `scripts/kicad-check.sh`: 0 ERC errors, 0 DRC errors, 0 unconnected, 0 parity issues. Explain every warning, or exclude it in KiCad with a comment.
- [ ] MCP `kicad`: `kicad_set_project` → `validate_design`, `validate_footprints_vs_schematic`, `dfm_run_manufacturer_check`.
- [ ] Board rules match the `pcb-design-rules` skill and the net classes are assigned.

## 1. Power input and protection
- [ ] Reverse-polarity protection on the battery input. Note the method (ideal diode / P-FET / series diode) and the loss at max current.
- [ ] Fuse or electronic current limit, rated for max current and bus voltage, with an I²t suited to the inrush.
- [ ] TVS or clamp on the bus, sized for regen and inductive spikes up to max bus voltage including transients (TODO V).
- [ ] Inrush / pre-charge for the bulk caps (motor controller), or a written reason it's not needed.
- [ ] Remote: battery protection (over-discharge, over-current, short), a charging IC if it's rechargeable, and correct cell polarity in the footprint.

## 2. Decoupling and power integrity
- [ ] Each IC power pin has its datasheet-recommended decoupling, placed close to the pin, with a short return via.
- [ ] Bulk capacitance on each rail. Motor controller bus: ripple current calculated and capacitors rated for it.
- [ ] Each regulator: input/output caps per datasheet, stability (ESR) requirements met, thermal dissipation checked.

## 3. MCU, programming and debug
- [ ] SWD/programming header, with a pinout that matches the probe (e.g. Tag-Connect TC2030 or 10-pin Cortex) and is documented on the silkscreen.
- [ ] BOOT/reset circuitry per the reference manual. Reset has a pull-up and cap.
- [ ] Clock: crystal load caps calculated from the crystal datasheet's CL and stray capacitance.
- [ ] A UART or USB available for logs / VESC Tool.

## 4. Test and bring-up
- [ ] Test points on every rail, on the gate-drive supply, on phase and current-sense signals, and on the comms lines, with JLC-friendly pads and silkscreen labels.
- [ ] Ground test point / clip point near the power stage.
- [ ] Current-limited first power-up plan written in `docs/design-notes/`.

## 5. Connectors and pinouts
- [ ] Every connector pinout checked against the mating part's datasheet and against the cable or motor harness drawing. Pin 1 is marked on the silkscreen.
- [ ] Current rating per pin ≥ max current, with derating.
- [ ] Keyed or polarized where a wrong insertion could damage the board.
- [ ] Phase-wire and battery connections sized for current (lugs, pads or a connector).

## 6. Motor controller power stage (VESC-derived)
- [ ] Changes from the upstream VESC reference are listed, and each is justified.
- [ ] Gate resistors, bootstrap caps and dead-time are set per the gate-driver datasheet.
- [ ] Current-sense: shunt value, amplifier gain and ADC range cover the peak current with headroom. Kelvin routing used.
- [ ] MOSFET V_DS and current derated per the `bom-check` skill.

## 7. Thermal
- [ ] Power dissipation estimated for each MOSFET, regulator, shunt and diode at max load. Junction temperature is below the rating minus the TODO margin.
- [ ] Thermal vias under exposed pads. Heatsink or enclosure contact surface defined.
- [ ] A thermistor near the power stage, wired to the firmware.

## 8. Wireless (remote)
- [ ] The antenna layout follows the module or chip vendor's guidance: keep-out area, ground clearance, matching network footprint.
- [ ] Regulatory plan noted (module with existing certification vs own design). TODO: target markets.

## 9. Manufacturing
- [ ] Every assembled part has an LCSC field. `bom-check` has been run.
- [ ] Fiducials, board outline, mounting holes and tooling edge where needed.
- [ ] Silkscreen readable: refs not under parts, polarity marks visible.
- [ ] Revision, board name and date on the silkscreen.

## Output
Give a table: section / item / PASS / FAIL / OPEN / evidence. Then list the top 5 risks in priority order. Never mark the board release-ready while any FAIL or BLOCKER is open.
