# Digital Low-Pass Filter (Embedded Systems)

| | |
|---|---|
| **Status** | Complete as a lab exercise — see the note on the 2 kHz test in [Results](#results) |
| **Context** | Academic — Signal Analysis, University of Beira Interior, January 2024 |
| **Team** | Alexandre Saraiva, Furkan Ocak, Gelson José |
| **My contribution** | Co-author (3-person lab). The acquisition code was provided by the professor; the team added the filter. |
| **Evidence** | [Report (PT, PDF)](report.pdf) (includes the C code) · setup and signal images below |

## Overview

This project implements a **digital low-pass filter** on an embedded system based on the **ARM Cortex-M3 (mbed LPC1768)**.

The system acquires an analog signal, processes it in real time using a filtering algorithm, and visualizes the results through **Node-RED**.

## Objectives

- Acquire analog signals using ADC
- Implement a digital low-pass filter
- Analyze signal behavior before and after filtering
- Validate theoretical concepts through real-world implementation

## Technical Concept

A low-pass filter allows **low-frequency signals** to pass while attenuating high-frequency components.

In this project, a **moving average filter** was implemented.

## System Architecture

- Signal Generator → Input Signal
- mbed LPC1768 → Signal Processing
- C/C++ Algorithm → Moving Average Filtering
- Node-RED → Data Visualization

## Technologies Used

- C / C++
- ARM Cortex-M3 (mbed LPC1768)
- Keil Studio
- Node-RED

## Implementation

The filter was implemented using a **moving average window**:

```c
#define JANELA 10
#define FREQ_CORTE 1000.0
```

`FREQ_CORTE` sets the sampling interval (`tic.attach(&flip, 1.0 / FREQ_CORTE)`), so the signal is sampled at **1 kHz** and filtered with a 10-sample moving average.

## Results

### High Frequency (2 kHz)
- Output signal appeared attenuated

### Low Frequency (20 Hz)
- Signal is preserved
- Minimal distortion observed

**Note:** with a 1 kHz sampling rate, signals above 500 Hz are aliased. The 2 kHz test therefore does not demonstrate the filter's attenuation. A valid test would use input frequencies below 500 Hz. The 20 Hz result is consistent with the expected response of a 10-sample moving average at 1 kHz.

## Experimental Setup

![Setup](setup_sig.png)

## Output Signals

- Original Signal
- Filtered Signal

![Signals](signals.png)
