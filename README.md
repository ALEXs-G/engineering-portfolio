# Alexandre Saraiva — Engineering Portfolio

**Junior Electrical / Electronics / Test Engineer**
Test & Measurement · Instrumentation · Embedded Systems · Validation

BSc Electrical and Computer Engineering (final stage), University of Beira Interior, Portugal ·
[LinkedIn](https://linkedin.com/in/alexandre-saraiva12) · [GitHub](https://github.com/ALEXs-G)

> **Reading guide.** Every project states its **status**, **context** (academic or personal),
> **my contribution**, and whether the evidence is hardware measurement, simulation or code only.
> Claims link to the report, data or code they come from. Gaps are stated, not hidden.
> The 2026 restructuring, re-analyses, code reviews and the test bench were developed with AI coding assistance (Claude Code); commits carry co-author trailers.
> One-page summary: [RECRUITER_GUIDE.md](RECRUITER_GUIDE.md) · all projects: [PROJECT_INDEX.md](PROJECT_INDEX.md) · skills mapped to evidence: [PORTFOLIO.md](PORTFOLIO.md)

---

## Engineering focus

The projects cover the work of a test and measurement engineer:

- **Measurement chains:** sensor → signal conditioning → acquisition, characterized from data (sensitivity, offset, linearity, residuals).
- **Embedded control with fault handling:** microcontroller firmware that reads sensors, drives actuators and handles failures.
- **Verification:** test cases traced to requirements, fault injection, PASS/FAIL/ERROR verdicts, generated reports.
- **Reviewing existing work:** a 2026 review of these projects, done with AI coding assistance, found errors in calculations, code and test methods. Examples: a resistor unit error, an aliased test signal, an energy-balance artefact, assembly code that does not assemble. All are documented in the project READMEs.

## Start here — three flagship projects

| # | Project | Domain | What was built | Test / validation evidence | Status |
|---|---|---|---|---|---|
| 1 | [**Type-K Thermocouple Measurement System**](thermocouple-temperature-system/) | Instrumentation | Thermocouple signal conditioning with LM335 cold-junction compensation; 0–350 °C → 0–2.5 V | 8 documented measurement points; derived sensitivity 7.04 mV/°C, offset +118 mV, R² = 0.99998; residuals match the Type K nonlinearity (r = 0.97); accuracy explicitly *not* claimed | Complete (academic, 2024) |
| 2 | [**Smart Self-Sustaining Irrigation System**](smart-irrigation-system/) | Embedded / IoT | ESP8266 node: 2 sensors via analog mux, optocoupled pump driver, ThingSpeak upload, deep sleep, solar + battery | Fault-handling table from source; 10-case test matrix with observed results only where documented; supply failure during demo reported | Partial (academic team, 2025) |
| 3 | [**Automated Test & Measurement Bench**](automated-test-measurement-bench/) | Test engineering | Python bench: 9 requirements → 10 test cases, fault injection, CSV/JSON/Markdown reports, CI | 43 pytest tests; 10/10 PASS and 6/6 injected faults detected — **on a simulated DUT** | Experimental (personal, 2026) |

## Supporting projects

| Project | Domain | Evidence type | Status | Key point |
|---|---|---|---|---|
| [Grid-tied hybrid energy system](grid-tied-hybrid-energy-system/) | Energy systems | MATLAB simulation | Complete (simulation); input data not in repo | Modular refactor with constraint checks; found a 7.16 kWh/yr SOC-clamp artefact in the published results |
| [Pool filtration & pH control](water-ph-control-system/) | Embedded (AVR Assembly) | Code + simulator test table | Historical | [Code review](water-ph-control-system/CODE_REVIEW.md): original does not assemble; reviewed copy assembles |
| [Traffic-light controller](traffic-light-controller/) | Embedded (AVR Assembly + GAL22V10) | Hardware demo + source | Partial | Interrupt re-arm defect documented |
| [4-bit datapath (TTL + GAL22V10)](microprocessor-architecture-lab/) | Digital hardware | Hardware test of ALU | Partial | ALU tested; controller not validated |
| [mBot2 Robot@Factory](robotics-factory/) | Robotics | Hardware demo, video | Partial (team) | A* abandoned for rule-based navigation; limits documented |
| [Analog band-pass filter](band-pass-filter/) | Analog electronics | PicoScope measurements | Complete | Phase measurement flagged as invalid |
| [FIR filter on ATmega2560](fir-filter-embedded-system/) | DSP / embedded | PicoScope measurements | Complete with discrepancies | Realized −3 dB ≈ 215 Hz vs. nominal 8.4 Hz (derived) |
| [Moving-average filter on mbed](digital-low-pass-filter/) | DSP / embedded | Plots | Complete (team) | 2 kHz test input aliased at fs = 1 kHz (review note) |
| [Erlang-B traffic dimensioning](cellular-traffic-simulation/) | Telecom / Python | Code, verified run | Complete | Matches published Erlang-B tables |

Archived: [`archive/incomplete/fire-detection-ai`](archive/incomplete/fire-detection-ai/). It was empty and is not portfolio evidence.

## Test & measurement competencies

Only competencies backed by evidence in this repository are listed. Details are in [PORTFOLIO.md](PORTFOLIO.md).

| Competency | Evidence |
|---|---|
| Static characterization of a sensor chain (regression, sensitivity, offset, residuals, error sources) | [Thermocouple analysis](thermocouple-temperature-system/results/characterization.md) |
| Bench measurements with DMM, thermocouple calibrator, oscilloscope (PicoScope 7), signal generator | Thermocouple, band-pass and FIR reports and setup photos |
| Frequency-response and square-wave testing of analog and digital filters | [Band-pass](band-pass-filter/), [FIR](fir-filter-embedded-system/) |
| Requirements-based test design, traceability, fault injection, automated reporting | [Test bench](automated-test-measurement-bench/) (simulation) |
| Test matrices separating implemented, tested and planned | [Irrigation verification](smart-irrigation-system/README.md#verification) |
| Finding invalid tests and data artefacts | Aliasing ([low-pass](digital-low-pass-filter/)), invalid phase data ([band-pass](band-pass-filter/)), energy-accounting check ([HRES](grid-tied-hybrid-energy-system/)) |

## Embedded systems

| Platform | Language / tool | Peripherals used | Project |
|---|---|---|---|
| ESP8266 (NodeMCU) | C++ (Arduino) | ADC + CD4053B mux, GPIO, Wi-Fi/HTTP, deep sleep | [Irrigation](smart-irrigation-system/) |
| ATmega2560 | AVR Assembly | ADC + interrupt, INT0/INT1, sleep modes, parallel DAC0832 | [pH](water-ph-control-system/), [traffic light](traffic-light-controller/), [FIR](fir-filter-embedded-system/) |
| mbed LPC1768 (Cortex-M3) | C (Keil Studio) | ADC, Ticker interrupt, USB serial → Node-RED | [Low-pass](digital-low-pass-filter/) |
| GAL22V10 | WinCUPL | Combinational logic and FSM | [Datapath](microprocessor-architecture-lab/), [traffic light](traffic-light-controller/) |

## Electrical / energy systems

- Analog signal conditioning: inverting summing amplifier with cold-junction and offset compensation ([thermocouple](thermocouple-temperature-system/)); 2nd-order Chebyshev op-amp stages ([band-pass](band-pass-filter/)).
- Power interface: optocoupler + transistor pump driver; solar panel + battery supply ([irrigation](smart-irrigation-system/)).
- System-level energy modelling: PV/wind/battery/grid hourly simulation with rule-based EMS, bus balance and SOC constraints ([HRES](grid-tied-hybrid-energy-system/)).

## Engineering tools

**Measurement:** digital multimeter, PicoScope 7, signal generator, thermocouple calibrator (in the thermocouple lab setup)
**Languages:** Python (pytest, matplotlib), MATLAB, C/C++, AVR Assembly, WinCUPL
**Design:** KiCad (PCB layout), SolidWorks (enclosures, mounts)
**Platforms:** Arduino IDE, Keil Studio, AVR Studio, Node-RED, ThingSpeak, mBlock
**Practice:** Git, GitHub Actions CI, LaTeX reports

## About

Electrical and Computer Engineering student at the University of Beira Interior, targeting
junior roles in test & measurement, validation, instrumentation and embedded systems in
Switzerland (Geneva / Lausanne region).

Languages: TODO (owner). Most original reports in this repository are written in Portuguese;
the portfolio documentation is in English.

---

[SECURITY.md](SECURITY.md) · [Repository conventions](docs/repository-conventions.md) · [Test templates](docs/templates/) · License: [MIT](LICENSE)
