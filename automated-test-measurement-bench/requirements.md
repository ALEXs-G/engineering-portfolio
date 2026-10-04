# Requirements — Temperature Transmitter and Test System

Scope: the simulated temperature transmitter (DUT) in [`src/dut.py`](src/dut.py) and the
automated test system around it.

**Origin of the numbers.** The range (0–350 °C) and the analog span (0–2.5 V) are the design
targets of the [thermocouple project](../thermocouple-temperature-system/). The tolerances
(±1.0 °C, ±12.5 mV, 0.2 °C, 200 ms) were **chosen for this baseline** to give a realistic
test structure. They do not come from a product datasheet or from measured hardware.

| ID | Requirement | Category | Verification method | Test(s) |
|---|---|---|---|---|
| REQ-001 | The DUT shall report temperature with status `OK` over 0 °C to 350 °C. | Function | Test | TEST-001, TEST-003 |
| REQ-002 | The reported temperature shall be within ±1.0 °C of the applied temperature over 0–350 °C. | Performance | Test | TEST-001, TEST-003 |
| REQ-003 | The analog output shall follow Vo = 2.5 V / 350 °C × T within ±12.5 mV (0.5 % FS). | Performance | Test | TEST-002 |
| REQ-004 | The standard deviation of 20 consecutive readings at constant temperature shall be ≤ 0.2 °C. | Performance | Test | TEST-005 |
| REQ-005 | Readings more than 0.5 °C outside 0–350 °C shall be reported with status `OUT_OF_RANGE`. | Diagnostics | Test | TEST-003, TEST-004, TEST-009 |
| REQ-006 | An open sensor shall be reported as `SENSOR_OPEN` with no numeric value, and the analog output shall go upscale (≥ 2.55 V). | Diagnostics | Test (fault injection) | TEST-006 |
| REQ-007 | The DUT shall answer a measurement query within 200 ms. | Interface | Test | TEST-007 |
| REQ-008 | On loss of communication the test system shall record `COMM_ERROR` with no value and shall not reuse previous data. | Test system | Test (fault injection) | TEST-008 |
| REQ-009 | Every measurement shall be logged with test ID, requirement IDs, stimulus, value, unit, status and time. | Test system | Test + inspection | TEST-010 |

The single source of truth in code is `REQUIREMENTS` in [`src/validation.py`](src/validation.py).
The generated reports reproduce this table, together with the verdicts.
