# Repository Conventions

## Project folder layout

```
<project-name>/            lowercase-kebab-case
├── README.md              status header + case study
├── <report>.pdf           original report (unchanged)
├── src/ | firmware/       source code
├── data/                  input data + README describing provenance
├── analysis/              scripts that derive results from data/
├── results/               generated outputs (reproducible from analysis/)
├── tests/
└── images/
```

Every project README starts with the same header table: **Status**, **Context**,
**Team**, **My contribution** and **Evidence**.

| Status value | Meaning |
|---|---|
| Complete | Objectives met and documented |
| Partial | Some objectives met; the gaps are stated |
| Experimental | Work in progress |
| Historical academic exercise | Kept for record; limited evidence value |

## Naming changes applied (2026-10-04)

| Before | After | Reason |
|---|---|---|
| `Grid-Tied Hybrid Electric Power System/` | `grid-tied-hybrid-energy-system/` | Spaces and capitals |
| `digital low-pass filter (embedded systems)/` | `digital-low-pass-filter/` | Spaces and parentheses |
| `readme.md`, `Readme.md` | `README.md` | Consistent capitalization |
| `smart-irrigation-system/code.ino` | `smart-irrigation-system/firmware/irrigation_controller/irrigation_controller.ino` | Arduino requires the sketch folder to match the `.ino` name |
| `traffic-light-controller/codeWINCUPL_Peões.pld` | `codeWINCUPL_Peoes.pld` | Non-ASCII file name |
| `fire-detection-ai/` | `archive/incomplete/fire-detection-ai/` | Empty project |
| `cellular-traffic-simulation/README.md/erlang_b_simulation.py/requirements.txt` | `cellular-traffic-simulation/requirements.txt` | Impossible path on case-insensitive file systems |

All internal links were updated. **External links** (CV, LinkedIn, applications) that point to the old folder URLs will break, because GitHub does not redirect renamed folders.

## Proposed, not applied

These renames would change the names of original deliverables. They are left to the owner.

| Current | Proposed | Note |
|---|---|---|
| `thermocouple-temperature-system/` | `thermocouple-measurement-system/` | Optional; current name is acceptable |
| `REPORTKalexandreEEC.pdf` | `report-type-k-thermometer-2024-pt.pdf` | Report file names mix languages and conventions |
| `RelatorioSISTEMAIrrigacaoFinal.pdf` | `report-smart-irrigation-2025-pt.pdf` | |
| `RelatorioRoboticaADD.pdf` | `report-robotics-mbot2-2024-pt.pdf` | |
| `HRSsimulationREPORT.pdf`, `MICRO1lab25.pdf`, `MICRO2lab25.pdf`, `REPORT.pdf` | `report-<topic>-<year>-pt.pdf` | |
| `codeControler.asm` | (keep; original) | The reviewed copy uses the corrected spelling `codeController_reviewed.asm` |
| `SIgnal.png`, `termopar.png`, `robotADD.png` | `signals.png`, `setup.png`, `robot.png` | |
| `smart-irrigation-system/images/prototype.jpg` (13 MB, 8160×6120) | Re-export at ≤ 2000 px | Repository size and page load |

## Commit messages

Use the form `type: imperative summary`, with one logical change per commit.
Types: `security`, `docs`, `fix`, `refactor`, `test`, `ci`, `chore`.
