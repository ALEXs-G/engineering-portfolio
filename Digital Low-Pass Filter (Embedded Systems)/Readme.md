# 🔧 Digital Low-Pass Filter (Embedded Systems)

## 📌 Overview

This project consists of the implementation of a **digital low-pass filter** using an embedded system based on the **ARM Cortex-M3 (mbed LPC1768)**.

The system acquires an analog signal, processes it in real-time using a filtering algorithm, and visualizes the results through **Node-RED**.

---

## 🎯 Objectives

- Acquire analog signals using ADC  
- Implement a digital low-pass filter  
- Analyze signal behavior before and after filtering  
- Validate theoretical concepts with real-world implementation  

---

## 🧠 Technical Concept

A low-pass filter allows **low-frequency signals** to pass while attenuating high-frequency components.

In this project, a **moving average filter** was implemented to simulate the filtering effect.

---

## ⚙️ System Architecture

- 📥 Signal Generator → Input Signal  
- ⚡ mbed LPC1768 → Signal Processing  
- 🧠 C/C++ Algorithm → Filtering (Moving Average)  
- 📊 Node-RED → Data Visualization  

---

## 🛠️ Technologies Used

- C / C++  
- ARM Cortex-M3 (mbed LPC1768)  
- Keil Studio  
- Node-RED  
- Embedded Systems  
- Signal Processing  

---

## 💻 Implementation

The filter was implemented using a **moving average window**:

```c
#define JANELA 10
#define FREQ_CORTE 1000.0
```

The system samples the signal and applies filtering in real-time.

👉 As described in the report, the signal is acquired, processed, and filtered using a moving average approach  [oai_citation:0‡Relatório Filtro passa-baixo Alexandre Furckan Gelson.pdf](sediment://file_00000000d12c71fdb4eb34ab7ac1b798)  

---

## 📊 Results

### ✔ High Frequency (2kHz)
- Signal is attenuated  
- Noise reduced  

### ✔ Low Frequency (20Hz)
- Signal preserved  
- Minimal distortion  

This confirms correct filter behavior according to theory.

---

## 📸 Experimental Setup

![Setup](setup_sig.png)

---

## 📈 Output Signals

- Original Signal  
- Filtered Signal  

![Signals](SIgnal.png)

---

## 📄 Full Report

📎 [Download Full Report](Report_Low_FILTER.pdf)

---

## 🚀 Key Learnings

- Embedded signal processing  
- Real-time data acquisition  
- Practical implementation of digital filters  
- Integration between hardware and software  

---

## 👨‍💻 Author

**Alexandre Saraiva**  
Electrical and Computer Engineering Student  

🔗 LinkedIn: https://linkedin.com/in/alexandre-saraiva12  
💻 GitHub: https://github.com/ALEXs-G  

---
