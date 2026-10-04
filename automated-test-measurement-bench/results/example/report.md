# Automated Test Report — Temperature Transmitter

> **Simulation mode.** The DUT and all instruments are software models. These results demonstrate the test workflow; they are not measurements of physical hardware.

| Item | Value |
|---|---|
| Mode | simulation |
| Configuration | `simulation.json` |
| DUT identification | `SIMULATED,TEMP-TX,SN0001,1.0` |
| Started (UTC) | 2026-10-04T22:13:58+00:00 |
| Python | 3.14.4 |
| Verdicts | PASS 10 · FAIL 0 · ERROR 0 · NOT_RUN 0 |
| Bench self-check | 6/6 injected faults detected as expected |

## Requirements traceability

| Requirement | Tests | Verdicts | Status |
|---|---|---|---|
| **REQ-001** The DUT shall report temperature with status OK over 0 degC to 350 degC. | TEST-001, TEST-003 | TEST-001:PASS, TEST-003:PASS | VERIFIED |
| **REQ-002** The reported temperature shall be within +/-1.0 degC of the applied temperature over 0-350 degC. | TEST-001, TEST-003 | TEST-001:PASS, TEST-003:PASS | VERIFIED |
| **REQ-003** The analog output shall follow Vo = 2.5 V / 350 degC x T within +/-12.5 mV (0.5 % FS). | TEST-002 | TEST-002:PASS | VERIFIED |
| **REQ-004** The standard deviation of 20 consecutive readings at constant temperature shall be <= 0.2 degC. | TEST-005 | TEST-005:PASS | VERIFIED |
| **REQ-005** Readings more than 0.5 degC outside 0-350 degC shall be reported with status OUT_OF_RANGE. | TEST-003, TEST-004, TEST-009 | TEST-003:PASS, TEST-004:PASS, TEST-009:PASS | VERIFIED |
| **REQ-006** An open sensor shall be reported as SENSOR_OPEN with no numeric value, and the analog output shall go upscale (>= 2.55 V). | TEST-006 | TEST-006:PASS | VERIFIED |
| **REQ-007** The DUT shall answer a measurement query within 200 ms. | TEST-007 | TEST-007:PASS | VERIFIED |
| **REQ-008** On loss of communication the test system shall record COMM_ERROR with no value and shall not reuse previous data. | TEST-008 | TEST-008:PASS | VERIFIED |
| **REQ-009** Every measurement shall be logged with test ID, requirement IDs, stimulus, value, unit, status and time. | TEST-010 | TEST-010:PASS | VERIFIED |

## Test results

| Test | Title | Requirements | Fault | Verdict |
|---|---|---|---|---|
| TEST-001 | Nominal temperature acquisition | REQ-001, REQ-002 | none | **PASS** |
| TEST-002 | Analog output transfer function | REQ-003 | none | **PASS** |
| TEST-003 | Range boundaries | REQ-001, REQ-002, REQ-005 | none | **PASS** |
| TEST-004 | Out-of-range stimulus | REQ-005 | none | **PASS** |
| TEST-005 | Noise / repeatability | REQ-004 | none | **PASS** |
| TEST-006 | Open sensor detection | REQ-006 | sensor_disconnected | **PASS** |
| TEST-007 | Query response time | REQ-007 | none | **PASS** |
| TEST-008 | Communication loss handling | REQ-008 | communication_loss | **PASS** |
| TEST-009 | Sensor value out of range | REQ-005 | sensor_out_of_range | **PASS** |
| TEST-010 | Measurement log completeness | REQ-009 | none | **PASS** |

### TEST-001 — Nominal temperature acquisition

| Check | Measured | Limit | Result |
|---|---|---|---|
| status at 25 degC | OK | OK | pass |
| error at 25 degC | 0.053 degC | |e| <= 1.0 degC | pass |
| status at 100 degC | OK | OK | pass |
| error at 100 degC | -0.011 degC | |e| <= 1.0 degC | pass |
| status at 200 degC | OK | OK | pass |
| error at 200 degC | 0.110 degC | |e| <= 1.0 degC | pass |
| status at 300 degC | OK | OK | pass |
| error at 300 degC | 0.005 degC | |e| <= 1.0 degC | pass |

### TEST-002 — Analog output transfer function

| Check | Measured | Limit | Result |
|---|---|---|---|
| Vo error at 25 degC | 2.53 mV | |e| <= 12.5 mV | pass |
| Vo error at 100 degC | 3.51 mV | |e| <= 12.5 mV | pass |
| Vo error at 200 degC | 3.73 mV | |e| <= 12.5 mV | pass |
| Vo error at 300 degC | 3.94 mV | |e| <= 12.5 mV | pass |

### TEST-003 — Range boundaries

| Check | Measured | Limit | Result |
|---|---|---|---|
| status at 0 degC | OK | OK | pass |
| error at 0 degC | 0.053 degC | |e| <= 1.0 degC | pass |
| status at 350 degC | OK | OK | pass |
| error at 350 degC | -0.011 degC | |e| <= 1.0 degC | pass |
| status at -1 degC | OUT_OF_RANGE | OUT_OF_RANGE | pass |
| status at 351 degC | OUT_OF_RANGE | OUT_OF_RANGE | pass |

### TEST-004 — Out-of-range stimulus

| Check | Measured | Limit | Result |
|---|---|---|---|
| status at -10 degC | OUT_OF_RANGE | OUT_OF_RANGE | pass |
| status at 360 degC | OUT_OF_RANGE | OUT_OF_RANGE | pass |
| status at 500 degC | OUT_OF_RANGE | OUT_OF_RANGE | pass |

### TEST-005 — Noise / repeatability

| Check | Measured | Limit | Result |
|---|---|---|---|
| std. dev. of 20 readings at 150 degC | 0.042 degC | <= 0.2 degC | pass |

### TEST-006 — Open sensor detection

| Check | Measured | Limit | Result |
|---|---|---|---|
| status with open sensor | SENSOR_OPEN | SENSOR_OPEN | pass |
| numeric value with open sensor | none | none | pass |
| analog output with open sensor | 2.600 V | >= 2.55 V | pass |

### TEST-007 — Query response time

| Check | Measured | Limit | Result |
|---|---|---|---|
| max response time over 10 queries | 0.020 s | <= 0.200 s | pass |

### TEST-008 — Communication loss handling

| Check | Measured | Limit | Result |
|---|---|---|---|
| first reading before link loss | OK | OK | pass |
| reading after link loss: status | COMM_ERROR | COMM_ERROR | pass |
| reading after link loss: value | none | none (no stale data) | pass |

### TEST-009 — Sensor value out of range

| Check | Measured | Limit | Result |
|---|---|---|---|
| status at 100 degC | OUT_OF_RANGE | OUT_OF_RANGE | pass |

### TEST-010 — Measurement log completeness

| Check | Measured | Limit | Result |
|---|---|---|---|
| log records with all mandatory fields | 4/4 | all | pass |

## Bench self-check (fault injection)

Each row runs a nominal test against a deliberately faulty simulated DUT. The row passes if the test reaches the expected verdict, i.e. the test can detect the defect.

| Test | Injected fault | Expected | Observed | Detected | Rationale |
|---|---|---|---|---|---|
| TEST-001 | sensor_out_of_range | FAIL | FAIL | yes | corrupted sensor value must fail accuracy/status |
| TEST-001 | sensor_disconnected | FAIL | FAIL | yes | open sensor must fail nominal acquisition |
| TEST-002 | sensor_disconnected | FAIL | FAIL | yes | burnout voltage must fail transfer check |
| TEST-005 | excessive_noise | FAIL | FAIL | yes | noise x50 must fail repeatability limit |
| TEST-007 | timeout | FAIL | FAIL | yes | 500 ms reply must fail 200 ms requirement |
| TEST-001 | communication_loss | ERROR | ERROR | yes | link loss must abort the test, not pass or fail it |

Raw data: `measurements.csv` · structured results: `results.json`
