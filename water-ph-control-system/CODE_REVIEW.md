# Code Review — `codeControler.asm` (ATmega2560, AVR Assembly)

| | |
|---|---|
| Reviewed file | [`codeControler.asm`](codeControler.asm) (original, unchanged) |
| Reviewed copy | [`codeController_reviewed.asm`](codeController_reviewed.asm) |
| Specification | [REPORT.pdf](REPORT.pdf), section 3 ("Problema") |
| Review date | 2026-10-04 |
| Reviewer | AI-assisted review (Claude Code), commissioned by the repository owner |
| Tools | AVRA 1.4.2 with `m2560def.inc`; manual review against the ATmega2560 datasheet register map |
| Hardware / simulator run | **None.** No AVR simulator was available for this review, and the reviewed copy has not been run anywhere. |

## Summary

- **The original does not assemble:** `Error: Found no label/variable/constant named PINFILTER` (line 52).
  It therefore cannot be the exact source that was simulated in AVR Studio, as described in the report's conclusion.
- The report's conclusion says the author "used code provided by colleagues to complete the project".
  This file should not be read as entirely individual work.
- The interrupt vector placement is correct. Several defects would prevent correct operation
  even after the assembler error is fixed. The most serious: outputs are written to `PINx` registers,
  the shutdown path falls into `RETI` with an empty stack, and the end-of-cycle input is read from a pin configured as an output.

## Confirmed behaviour

These were checked against the register definitions in `m2560def.inc`.

| Item | Code | Assessment |
|---|---|---|
| Reset vector | `jmp START` at 0x0000 | Correct |
| INT0 vector | `jmp RINT0` at 0x0002 (`jmp` is 2 words) | Correct: `INT0addr = 0x0002` |
| ADC vector | `.org 0x003A` / `jmp LERADC` | Correct: `ADCCaddr = 0x003A` |
| Stack | SPL/SPH ← RAMEND | Correct |
| Sleep mode | `SMCR = $01` | SE = 1, SM = 000 (Idle). The ADC and INT0 can both wake the CPU. |
| External interrupt | `EICRA = $03`, `EIMSK = $01` | INT0 on rising edge, enabled. The ISR is a bare `RETI`, used only to wake the CPU. |
| ADC setup | `ADMUX = $20`, `ADCSRA = $CF` | ADC0, left-adjusted (8-bit result in ADCH), external AREF, single conversion, interrupt enabled, clk/128 |
| Comparison logic | sensor vs. ref + 3 / ref | Matches spec 4.6–4.7: PhA if sensor > ref + 3, PhB if sensor < ref, otherwise no action |

## Potential issues

Severity scale: **High** prevents correct operation · **Medium** wrong in some conditions · **Low** quality or clarity.

| ID | Line(s) | Issue | Severity | Fixed in reviewed copy? |
|---|---|---|---|---|
| C1 | 52 | `PINFILTER` is undefined, so assembly fails. The spec calls this port `PINFILTR`. | High | Yes. Defined as `PINB` (an assumption; the wiring is not documented). |
| C2 | 8, 54, 59 | `.equ POUTCTR = PINA`: writing 1s to a `PINx` register **toggles** the corresponding `PORTx` bits on the ATmega2560. It does not set them. | High | Yes → `PORTA` |
| C3 | 91, 96, 103 | `out PINREF, R20` writes the computed thresholds into `PINC`. This toggles `PORTC` outputs, which drive the LEDs. | High | Yes. The writes are removed; the thresholds stay in R20. |
| C4 | 90 | `adc R20, R22` adds the carry left over from a previous instruction, so the threshold is `ref + 3` or `ref + 4` at random. | Medium | Yes → `add` |
| C5 | 94, 98, 105 | `brpl` / `brmi` after `cp` test the sign of the 8-bit difference. For unsigned values whose difference exceeds 127 the decision is inverted. | Medium | Yes → `brsh` / `brlo` |
| C8 | 58, 135 | `R18` is used before initialization (`sbr R18, $80`). `R17` is never written but is output at line 135. Registers are not cleared at reset. | Medium | Yes. Both cleared at START. |
| C9 | 131–138 | `CLKTmpFilt` has no jump at its end and falls into `RINT0: reti`. `RETI` outside an interrupt pops an undefined return address from an empty stack. | High | Yes → `rjmp ModoSleep` |
| C14 | 33 | `sei` runs before the port and ADC configuration. | Low | Yes. Moved after configuration. |
| C15 | 15 | `START` is placed right after the ADC vector (0x003C), on top of unused vector slots. This is harmless while those interrupts are disabled, but fragile. | Low | Yes → `.org INT_VECTORS_SIZE` |
| D1 | 116–117 | The end of the filtration cycle is read from `PINA` bit 4, but `DDRA = $B3` configures PA4 as an **output**. Every write to PORTA in the loop leaves bit 4 at 0, so the `Verif` loop never reaches `CLKTmpFilt`. The spec (§3.3) says the end signal is the MSB of `PINFILTR`. | High | **No.** The correct input depends on the intended wiring. |
| D2 | 37, 63–67 | `DDRA` makes PA3 (PhS) an input, but the spec (§4.2) says the program starts a reading by *setting* PhS to 1, which makes it an output. The code waits for an external PhS instead. The DDRA comment also lists 7 bit fields for an 8-bit port. | Medium | **No** (needs the intended pin map) |
| D3 | 80–83 | The comment says "shift 4 times"; the code shifts 3 times. With `DDRC = $F0`, only PC4–PC7 are outputs, so after 3 right shifts only ADCH bit 7 reaches an LED. | Medium | **No**. Only a NOTE comment added. |
| D4 | 79, 92 | `R19` (ADCH >> 3, range 0–31) is compared with the raw 8-bit reference port, so the two scales differ. `R30` holds the unshifted value but is never used. | Medium | **No** (needs the intended reference scaling) |
| D5 | 45 | `ADMUX = $20` selects the external AREF. On an Arduino Mega the AREF pin is unconnected unless wired. `$60` (AVcc reference) may have been intended. | Medium | **No** (hardware-dependent) |
| D6 | 84–85 | `ADCSRA = $07` clears ADEN, which disables the ADC; the comment says "restart". This is functionally acceptable because STARTADC re-enables it, but the first conversion after enabling takes 25 ADC cycles. | Low | No (comment noted) |
| D7 | 68–70 | After `sbrs R18, 3` has confirmed bit 3 = 1, `andi $0C` / `breq` can only branch if PA3 changes between the two reads. The branch is practically unreachable. | Low | No |
| D8 | 10 | `.equ PINph = ADCH` is never used. The spec defines PINPH as an 8-bit port; the implementation uses the ADC instead, which deviates from the spec. | Low | No |
| D9 | 89 | `ref + 3` overflows for reference values ≥ 253 (8-bit wrap). | Low | No (noted) |

## Unverified assumptions

- Physical pin map (sensor, PhS, PhA/PhB, Mon, PINFILTR, LEDs). The report does not include a wiring table.
- Which simulator configuration produced the test table in the report (4 cases: equal, low, high, low).
  The test inputs (PINREF, ADC value) appear to have been set by hand in AVR Studio.
- That the hardware photo/schematic in the report ([ArduinoCircuit.png](ArduinoCircuit.png)) corresponds to this exact source file.

## Suggested corrections beyond the reviewed copy

1. Decide the I/O map from the specification, then fix D1 (read `PINFILTR` bit 7 for end-of-cycle) and D2 (make PhS an output and set it to start a reading).
2. Compare at a consistent scale: use `ADCH` directly (R30) against the 8-bit reference (D4).
3. Choose the ADC reference to match the hardware (D5) and map the 8-bit value to the four LEDs with `swap`/`andi $F0` (D3).
4. Saturate `ref + 3` at 255 (D9).
5. Add test cases for the boundary conditions: sensor = ref, ref + 3, ref + 4, ref − 1, ref = 0, ref = 255. Then run them in a simulator (e.g. simavr or Microchip Studio) and record the results.

## Assembler output

Original:

```
codeControler.asm(52) : Error   : Found no label/variable/constant named PINFILTER
Assembly aborted with 1 errors and 0 warnings.
```

Reviewed copy:

```
Assembly complete with no errors.
Segment usage:
   Code      :       107 words (214 bytes)
```

Command: `avra -I <avra>/include/avr codeController_reviewed.asm`
