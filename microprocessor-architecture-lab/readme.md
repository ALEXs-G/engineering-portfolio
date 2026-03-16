# Microprocessor Architecture and Controller Implementation

Hardware implementation of a simplified microprocessor architecture developed during the **Microprocessors** course at the **University of Beira Interior**.

This project includes the design and implementation of:

- Arithmetic Logic Unit (ALU)
- Data registers
- Register memory
- Flags register
- Sequential controller

---

## Overview

The goal of this laboratory project was to implement and test a digital architecture capable of performing basic arithmetic operations in hardware.

The system was built using TTL integrated circuits and programmable logic devices, namely:

- 74LS173
- 74LS670
- GAL22V10

The architecture supports arithmetic operations such as:

- Addition
- Subtraction
- Increment
- Decrement

It also updates status flags such as:

- Zero
- Carry
- Sign
- Overflow

---

## Architecture Diagram and Hardware Prototype

![Architecture Diagram](images/architecture-diagram.png)

---

## Main Components

- **74LS173** — used as input register, accumulator and flags register
- **74LS670** — used as 4x4 register memory
- **GAL22V10** — used to implement both the ALU and the control unit

---

## Control Unit

The controller was implemented as a **finite state machine (FSM)** programmed in **WinCupl** for the GAL22V10.

It generates the control signals required for:

- register writes
- memory access
- ALU operation selection
- result storage
- flag updates

---

## Results

The ALU was successfully tested and validated in hardware.

The controller was implemented, although full hardware validation of the complete system remained unfinished due to time constraints.

---

## Technical Skills Demonstrated

- Digital systems design
- Microprocessor architecture
- Boolean logic
- FSM design
- Hardware prototyping
- WinCupl / GAL programming
- TTL logic integration

---

## Project Report

[Download full report (PDF)](report.pdf)

---

## Academic Context

**Course:** Microprocessors  
**University:** University of Beira Interior  
**Degree:** Electrical and Computer Engineering

---

## Author

**Alexandre Saraiva**

LinkedIn:  
https://linkedin.com/in/alexandre-saraiva12

GitHub:  
https://github.com/ALEXs-G
