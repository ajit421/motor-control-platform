---
name: pcb-design-rules
description: AirBuddy PCB layout rules — trace width vs current, clearance vs voltage, JLCPCB fab limits, preferred packages. Use when setting KiCad design rules/net classes, sizing power traces, or checking a layout for the motor controller or remote.
---

# PCB design rules

Values marked **TODO** are company decisions that have not been made yet. Do not fill them in on your own; ask the user. When a TODO blocks a calculation, say so and show the formula with the missing input.

## 1. Fab limits — JLCPCB (from jlcpcb.com/capabilities/pcb-capabilities, checked 2026-11-23)

Use these as hard minimums only. Design to the "AirBuddy default" column. Re-check the page before each new board, because limits change.

| Item | JLCPCB min (2-layer, 1 oz) | JLCPCB min (4-layer, 1 oz outer) | 2 oz outer | AirBuddy default |
|---|---|---|---|---|
| Track / space | 0.10 / 0.10 mm | 0.09 / 0.09 mm | 0.16/0.16 (2L), 0.15/0.15 (4L) | TODO |
| Via drill / diameter | 0.15 / 0.25 mm (preferred min drill 0.2) | same | — | TODO. Drill < 0.3 mm or pad < 0.45 mm costs more; JLC says "0.2mm or 0.25mm hole size with via diameter less than 0.45mm, will cost more" |
| PTH annular ring | 0.18 abs / 0.25 recommended | 0.15 abs / 0.20 recommended | 0.254 | TODO |
| Via hole-to-hole | 0.2 mm | | | |
| Pad hole-to-hole | 0.45 mm | | | |
| Copper to routed edge | 0.2 mm (V-cut 0.4 mm) | | | TODO |
| Solder mask bridge | 0.10 mm (green); 0.13 black/white; 0.20 for 2 oz | | | |
| Silkscreen | line ≥ 0.15 mm, text height ≥ 1.0 mm, pad-to-silk 0.15 mm | | | |
| Min NPTH | 0.50 mm | | | |
| Copper weights | outer 1/2/2.5/3.5/4.5 oz (2L); 1/2 oz (multilayer); inner 0.5/1/2 oz (default 0.5) | | | TODO per board |
| Thickness | 0.4–2.0 mm standard FR-4 | | | TODO |

## 2. Trace width vs current

Use IPC-2221 (conservative) or IPC-2152 (more accurate; preferred for the motor controller's power stage):

- IPC-2221: `I = k · ΔT^0.44 · A^0.725`, where A is the cross-section in mil², ΔT is in °C, k = 0.048 for external layers and 0.024 for internal. Width = A / (thickness_mil), with 1 oz ≈ 1.378 mil (35 µm).
- Phase and bus currents on the motor controller will exceed what traces alone can carry sensibly. Plan for polygons on several layers, stitched with via arrays, and check via current too.

| Input | Value |
|---|---|
| Allowed temperature rise ΔT | TODO (°C) |
| Max ambient | TODO (°C) |
| Motor controller continuous / peak phase current | TODO (A) / TODO (A) for TODO s |
| Battery input current | TODO (A) |
| Copper weight, power layers | TODO (oz) |
| Remote max supply current | TODO (mA) |

Always show the calculation (inputs → width) in `docs/design-notes/`.

## 3. Clearance vs voltage

The motor controller bus is 12–60 V nominal. Regen and switching spikes go higher, so size clearance for **max bus voltage including transients = TODO V**, not for 60 V.

IPC-2221B Table 6-1, conductor spacing in mm. **UNVERIFIED: these values were transcribed from memory. Check them against the standard before relying on them.**

| Voltage (DC or AC peak) | B1 internal | B2 external, uncoated, sea level | B4 external, coated |
|---|---|---|---|
| 0–15 V | 0.05 | 0.1 | 0.05 |
| 16–30 V | 0.05 | 0.1 | 0.05 |
| 31–50 V | 0.1 | 0.6 | 0.13 |
| 51–100 V | 0.1 | 0.6 | 0.13 |
| 101–150 V | 0.2 | 0.6 | 0.4 |

- Conformal coating used? TODO (yes/no). This decides whether the B2 or B4 column applies.
- Company minimum for HV-to-logic spacing: TODO mm.
- Altitude rating: TODO. Above 3050 m, the B3 column applies and clearances grow a lot. Check this, since the product is aerospace.

## 4. Net classes (create in KiCad Board Setup → Net Classes)

| Class | Nets | Track | Clearance | Via |
|---|---|---|---|---|
| Default | signals | TODO | TODO | TODO |
| Power_HV | VBUS, phase A/B/C, battery | TODO (from §2) | TODO (from §3) | TODO (via arrays) |
| Gate | gate drive loops | TODO | TODO | TODO |
| Analog_Sense | current shunt and voltage sense, Kelvin-routed | TODO | TODO | TODO |
| RF | remote antenna feed, 50 Ω | TODO (from the stackup calculator) | TODO | — |

## 5. Preferred packages

| Part type | Preferred | Notes |
|---|---|---|
| R / C passives | TODO (e.g. decide between 0402 and 0603) | Prefer whichever size most of the JLCPCB Basic parts come in |
| Power MOSFETs | TODO | Check thermal pad, current and avalanche ratings |
| MCU | TODO | Avoid BGA unless a 4+ layer board is planned |
| Connectors | TODO | Must be in JLC's assembly library or hand-solderable |

## 6. Layout must-dos (motor controller)

- Keep the gate-driver loop and the power commutation loop as small as possible, with the bulk and ceramic bus caps right at the half-bridges.
- Kelvin-connect the current shunts. Route sense pairs differentially, away from switch nodes.
- Use one solid ground reference under the logic. Join power ground and signal ground at one deliberate point.
- Thermal: power parts need a heatsink path, thermal vias under exposed pads, and a documented estimate of junction temperature.
