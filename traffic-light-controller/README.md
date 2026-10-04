# Traffic Light Control System (ATmega2560)

Embedded systems project implementing a **traffic light controller with pedestrian support**, using the **ATmega2560 microcontroller**, **Assembly programming** and a **GAL22V10** logic device.

| | |
|---|---|
| **Status** | Partial — Parts 1 and 2 work; Part 3 does not accept repeated requests (see [Results](#results)) |
| **Context** | Academic — Microprocessors, University of Beira Interior, 2026 |
| **Team** | Individual report |
| **My contribution** | Assembly and WinCUPL code, prototype and report |
| **Evidence** | [Report (PT, PDF)](report.pdf) · source files listed below · prototype photo |

---

## System Prototype

![Traffic Light System](setup.jpg)

---

## Overview

This project implements a **real-time traffic light control system** with:

- Multiple traffic lanes (A, B, C)
- Pedestrian crossing requests
- External interrupt handling (INT0 and INT1)
- Time-controlled state transitions

---

## System Features

### Traffic Light Cycle
- Green → Yellow → Red sequence
- Timed using software counters (~500 ms resolution)

### Pedestrian Request (INT0)
- Triggered by external button
- Forces safe transition:
  - Vehicles → Red
  - Pedestrians → Green

### Independent Crossing (INT1)
- Separate pedestrian crossing
- Does not interrupt main traffic flow
- Includes minimum delay between activations (30 s)

---

## Source Files

| File | Content |
|---|---|
| [codeAssembly_Parte1.asm](codeAssembly_Parte1.asm) | Part 1 — basic light cycle |
| [codeASM_parte2_INT.asm](codeASM_parte2_INT.asm), [codeAsm_p2_3.asm](codeAsm_p2_3.asm) | Part 2 — pedestrian request on INT0 |
| [code_p3_INtIn.asm](code_p3_INtIn.asm) | Part 3 — independent crossing on INT1 |
| [codeWINCUPL_Parte1.pld](codeWINCUPL_Parte1.pld), [codeWINCUPL_Peoes.pld](codeWINCUPL_Peoes.pld) | GAL22V10 logic (WinCUPL) |

---

## Architecture

- **ATmega2560 (AVR)**
- GPIO control via PORTA, PORTB, PORTC
- External interrupts (INT0, INT1)
- Software timing loops

---

## Hardware Components

- ATmega2560 (Arduino Mega)
- LEDs (traffic lights simulation)
- Push buttons (interrupt triggers)
- Breadboard + wiring
- Logic device (GAL22V10)

---

## Results

The system demonstrated:

- Correct traffic sequencing
- Real-time response to interrupts
- Concurrent operation of independent subsystems

Limitation:
- After the first interrupt, the system does not handle new requests
  (requires improvement in flag reset / control flow)

---

## Future Improvements

- Replace delay loops with hardware timers
- Improve interrupt reactivation logic
- Modularize code for scalability
- Add PCB design instead of breadboard
