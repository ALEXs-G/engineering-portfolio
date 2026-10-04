# Water Filtration & pH Control System (ATmega2560)

Embedded systems exercise implementing an **automated water filtration and pH regulation system** on the **ATmega2560 microcontroller**, programmed in **Assembly**.

| | |
|---|---|
| **Status** | Historical academic exercise — tested in simulation only (AVR Studio) |
| **Context** | Academic — Microprocessors, University of Beira Interior, June 2024 |
| **Team** | Individual report |
| **My contribution** | Report and program. As stated in the report, the program was completed with code shared by colleagues. |
| **Evidence** | [Report (PT, PDF)](report.pdf) · [Assembly source](controller.asm) |

> **Note:** the committed source does not assemble as-is (`PINFILTER` is not defined).

---

## System Concept

![System Architecture](ArduinoCircuit.png)

---

## Overview

This project simulates a **pool water management system** capable of:

- Activating filtration cycles automatically
- Measuring water pH levels using sensors
- Comparing real-time values with a reference
- Automatically correcting pH levels

The system uses **interrupt-driven logic** and low-level hardware control.

---

## System Functionality

### 1. Filtration Control
- Triggered by external clock signal
- System starts in **sleep mode**
- Activates filtration cycle when triggered

### 2. pH Measurement
- Sensor reading initiated via control signal
- ADC used to capture pH value

### 3. pH Comparison Logic
- Compares sensor value with reference value
- Applies tolerance margin (+3)

### 4. Automatic Regulation
- If pH too high → activates **pH decrease (PhA)**
- If pH too low → activates **pH increase (PhB)**
- Runs continuously during filtration cycle

---

## Architecture

The system is composed of:

- ATmega2560 (Arduino)
- ADC module (analog to digital conversion)
- Input ports (sensor + reference)
- Output ports (control signals)
- Interrupt-based control logic

The system uses:
- Sleep mode
- External interrupts
- ADC conversion with interrupt

---

## Example Logic

| Sensor pH | Reference | Action |
|----------|----------|--------|
| Equal | Within tolerance | Maintain |
| Higher | Above +3 | Decrease pH |
| Lower | Below reference | Increase pH |

---

## Technologies Used

- Assembly (AVR)
- ADC (Analog-to-Digital Conversion)
- Interrupt handling
- AVR Studio (simulation)
