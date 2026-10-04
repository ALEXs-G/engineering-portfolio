# Engineering Portfolio — Quick Technical Overview

**Alexandre Saraiva** · BSc Electrical and Computer Engineering (final stage), University of Beira Interior
[LinkedIn](https://linkedin.com/in/alexandre-saraiva12) · [GitHub](https://github.com/ALEXs-G)

## Target roles

Junior Test & Measurement Engineer · Junior Electronics Test / Validation Engineer ·
Instrumentation Engineer · Embedded Systems Test Engineer · Junior Commissioning / Integration Engineer

## Core technical areas

Measurement chains and sensor characterization · Analog signal conditioning ·
Microcontroller firmware (ESP8266, ATmega2560) · Requirements-based test automation (Python) ·
Energy-system modelling (MATLAB)

## Top 3 projects

1. **[Type-K thermocouple measurement system](thermocouple-temperature-system/).** Hardware,
   measured. Signal conditioning with cold-junction compensation, characterized from 8 points:
   S = 7.04 mV/°C, offset +118 mV, residuals traced to the sensor's own nonlinearity. Absolute
   accuracy is explicitly not claimed, because no reference uncertainty was documented.
2. **[Smart irrigation node](smart-irrigation-system/).** Hardware, team of 3. ESP8266, sensor mux,
   optocoupled pump driver, solar supply, IoT upload. Fault-handling table and test matrix; the
   power failure seen during the demo is reported.
3. **[Automated test & measurement bench](automated-test-measurement-bench/).** Personal, **simulation**.
   9 requirements → 10 test cases, fault injection, traceability, CSV/JSON/Markdown reports, 43 tests in CI.

## Test & measurement evidence

- Bench instruments in lab work: DMM, PicoScope 7, signal generator, thermocouple calibrator in the setup.
- Frequency-response and square-wave tests of analog and digital filters.
- 2026 review of my past projects (AI-assisted) found an aliased test signal, an invalid phase method,
  a resistor unit error and an energy-accounting artefact in a published simulation. All are documented in the project READMEs.

## Embedded systems evidence

- ESP8266 C++: sensor acquisition with averaging, actuator safety cut-offs, Wi-Fi timeout, deep sleep.
- ATmega2560 AVR Assembly: interrupt vectors, INT0/INT1, sleep modes, ADC interrupt, DAC output.
- A written [code review](water-ph-control-system/CODE_REVIEW.md) of an AVR program against the datasheet register map.

## Engineering tools

Python (pytest, matplotlib) · MATLAB · C/C++ · AVR Assembly · WinCUPL · KiCad · SolidWorks ·
Arduino IDE · Keil Studio · Git / GitHub Actions

## Read the evidence levels

Every project README states whether results are **measured on hardware**, **demonstrated**,
**simulated** or **code only**. See [PROJECT_INDEX.md](PROJECT_INDEX.md) and [PORTFOLIO.md](PORTFOLIO.md).

## Languages

TODO (owner): spoken languages and levels.
