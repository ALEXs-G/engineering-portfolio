# FIR Low-Pass Filter on ATmega2560 (AVR Assembly) with DAC0832 Output

| | |
|---|---|
| **Status** | Complete, with documented discrepancies between theory and measurement (historical academic lab, January 2025) |
| **Context** | Academic — *Processamento de Sinal e Imagem* (Signal and Image Processing), University of Beira Interior |
| **My contribution** | Individual lab work: Assembly implementation, DAC/op-amp circuit, measurements, report |
| **Evidence** | [Report (PT, PDF)](Report_Alexandre_TLB2_PSI.pdf) · [circuit photo](setup_circuit.png) · [response plot](PSI-FIR.png) |
| **Source code** | Not included in the repository. The Assembly and MATLAB listings are in the report only. |

---

![Circuit](setup_circuit.png)

## Signal chain

```
Signal generator → ADC (ATmega2560) → FIR in AVR Assembly → PORTA → DAC0832 → LF356 (I→V) → PicoScope 7
```

## Design

- MATLAB `fir1(25, 0.002)`: 26 taps, Hamming window. Coefficients scaled by 256 and rounded to integers for 8-bit `mul`.
- Difference equation `y[n] = Σ b[k] · x[n−k]`, with a delay line in memory and an interrupt-driven ADC.
- Sampling frequency reported: **8362 Hz**.

**Design note (derived in 2026, not in the report).** With fs = 8362 Hz, a normalized cut-off of
0.002 is nominally 8.4 Hz, which is far below what 26 taps can resolve. Re-computing the `fir1`
response with fs = 8362 Hz gives a realized **−3 dB point at ≈ 215 Hz** (−6 dB at ≈ 300 Hz).
The integer coefficients from this re-computation (2, 2, 3, 4, 6, 7, 10, …) match the ones in the
report's Assembly listing. Measurements over 10–1000 Hz should therefore be compared with the
realized response, not with the nominal cut-off.

## Test & measurement

| Step | Result (from report) |
|---|---|
| Pass-through test (y[n] = x[n]) to verify the ADC → DAC → op-amp chain | Worked as intended |
| Hardware fault | ADC0 (PA0) on the board did not work; the input was moved to ADC1 (PA1) after debugging |
| Frequency sweep 10 Hz – 1000 Hz (log steps), gain and phase | Low-pass behaviour observed. Measured attenuation was **greater than predicted** at higher frequencies, and the phase showed unexpected variation. |

The report attributes the discrepancies to data-extraction errors, noise and component
tolerances. These causes were not isolated experimentally.

## Limitations and next steps

- Quantization: 8-bit coefficients (×256) and 8-bit samples. The MATLAB comparison should use
  the quantized coefficients rather than the floating-point `fir1` output.
- Model the DAC0832 zero-order hold (sinc roll-off) and any reconstruction filtering. This could
  explain extra attenuation at higher frequencies. Hypothesis, not tested.
- Verify the effective sampling rate by toggling a pin in the ISR and measuring it on the scope.
