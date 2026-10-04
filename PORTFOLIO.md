# Competency Evidence Map

Each competency is linked to the artefact that supports it, with the type of evidence and the
known gaps. Evidence levels:

- **A:** measured on hardware or executed code with recorded results
- **B:** demonstrated on hardware without a recorded data set, or simulation with tests
- **C:** documented design or code review only

## Test & measurement

| Competency | Evidence | Level | Gap / next step |
|---|---|---|---|
| Static characterization (sensitivity, offset, linear fit, residuals) | [thermocouple results](thermocouple-temperature-system/results/characterization.md), [script](thermocouple-temperature-system/analysis/characterize.py) | A | Single reading per point; no uncertainty budget |
| Separating sensor nonlinearity from circuit error | Residuals vs. NIST ITS-90 Type K function, r = 0.97 ([thermocouple](thermocouple-temperature-system/README.md#calibration--characterization)) | A | — |
| Stating the limits of a measurement ("accuracy cannot be established") | [thermocouple](thermocouple-temperature-system/README.md#calibration--characterization) | A | Calibrate against a traceable reference |
| Oscilloscope frequency-response measurement | [band-pass report](band-pass-filter/Report_Alexandre_TLB1_PSI.pdf), [FIR report](fir-filter-embedded-system/Report_Alexandre_TLB2_PSI.pdf) | A | Phase method was invalid in the band-pass lab ([note](band-pass-filter/README.md#limitations-and-lessons)) |
| Requirements → test cases → traceability | [bench requirements](automated-test-measurement-bench/requirements.md), [test plan](automated-test-measurement-bench/test-plan.md) | B (simulation) | Apply to real hardware |
| Fault injection and checking that the bench detects faults | [bench self-check](automated-test-measurement-bench/results/example/report.md#bench-self-check-fault-injection) | B (simulation) | — |
| Automated reports (CSV/JSON/Markdown) and CI | [bench](automated-test-measurement-bench/), [workflow](.github/workflows/test-bench.yml) | B | — |
| Test matrix separating implemented, tested and planned | [irrigation verification](smart-irrigation-system/README.md#verification) | C | Run the untested cases on the prototype |
| Test documentation templates | [docs/templates](docs/templates/) | C | Use them on a real test |

## Embedded systems

| Competency | Evidence | Level | Gap |
|---|---|---|---|
| ESP8266 firmware: sensors, actuator, Wi-Fi, deep sleep, timeouts | [irrigation firmware](smart-irrigation-system/firmware/irrigation_controller/irrigation_controller.ino) | B | Repo revision not run on hardware; no power measurements |
| Fault handling in firmware (low-water lockout, watering timeout, Wi-Fi timeout) | [fault table](smart-irrigation-system/README.md#fault-handling) | C (source review) | Formal fault tests |
| AVR Assembly: vectors, INT0/INT1, sleep, ADC interrupt | [traffic light](traffic-light-controller/), [pH](water-ph-control-system/), [FIR](fir-filter-embedded-system/) | B | Traffic Part 3 re-arm defect |
| Reviewing assembly code against the datasheet register map | [CODE_REVIEW.md](water-ph-control-system/CODE_REVIEW.md) | C | Simulate the reviewed copy |
| Programmable logic (GAL22V10 / WinCUPL) | [traffic light .pld](traffic-light-controller/), [datapath](microprocessor-architecture-lab/) | B | Controller FSM not validated |

## Electronics & electrical

| Competency | Evidence | Level | Gap |
|---|---|---|---|
| Op-amp signal conditioning with CJC / offset compensation | [thermocouple](thermocouple-temperature-system/) | A | — |
| Active filter design and build (Chebyshev, TL081) | [band-pass](band-pass-filter/) | A | Tolerance analysis |
| DAC + I→V output stage (DAC0832 + LF356) | [FIR](fir-filter-embedded-system/) | A | — |
| PCB layout (KiCad) | [irrigation PCB image](smart-irrigation-system/images/PCB.jpeg) | C | Board fabrication not documented |
| Hybrid PV/wind/battery modelling with constraint checks | [HRES](grid-tied-hybrid-energy-system/) | B (simulation) | MATLAB tests not yet executed; original data missing |

## Data & software

| Competency | Evidence | Level |
|---|---|---|
| Python for analysis and test automation | [thermocouple analysis](thermocouple-temperature-system/analysis/), [bench](automated-test-measurement-bench/), [Erlang-B](cellular-traffic-simulation/) | A |
| MATLAB modelling and refactoring | [HRES](grid-tied-hybrid-energy-system/) | B |
| Reproducibility (seeded runs, regenerated results checked in CI) | [workflow](.github/workflows/test-bench.yml) | B |

## Not claimed

Production test experience, ISO/IEC 17025 calibration, LabVIEW/TestStand, high-voltage or
power electronics hardware, and professional/industrial experience. None of these is
evidenced in this repository.
