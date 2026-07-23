## Hybrid Renewable Energy System Simulation

This project was developed as part of the **Power Systems** course at the **University of Beira Interior (UBI)**. It presents the modeling and simulation of a **grid-connected Hybrid Renewable Energy System (HRES)** for the municipality of **Trancoso, Portugal**, integrating photovoltaic generation, wind power, battery energy storage, and the electrical grid. SEE_Alexandre_S.pdf

The simulation was implemented entirely in **MATLAB**, using hourly meteorological and electrical demand data, including solar irradiance, wind speed, ambient temperature, electricity demand, and dynamic electricity market prices. A rule-based Energy Management System (EMS) was developed to optimize energy flows between renewable generation, battery storage, and the utility grid. SEE_Alexandre_S.pdf

### Project Objectives

- Model a photovoltaic power generation system.
- Model a wind power generation system using a commercial wind turbine.
- Implement a Battery Energy Storage System (BESS).
- Develop a rule-based Energy Management Strategy (EMS).
- Simulate energy exchange with the electrical grid.
- Evaluate the technical performance of the hybrid system through weekly and annual simulations. SEE_Alexandre_S.pdf

### System Configuration

- **Photovoltaic Plant:** 6 MWp (24,000 Sharp ND-R250A5 modules)
- **Wind Farm:** 3.6 MW (2 × Vestas V80-1800 wind turbines)
- **Battery Storage:** 15.664 MWh (4 × Tesla Megapack 2 XL)
- **Average Electrical Load:** 3.13 MW (Municipality of Trancoso)
- **Simulation Environment:** MATLAB SEE_Alexandre_S.pdf

### Energy Management Strategy

The implemented Energy Management System follows a rule-based control algorithm:

- Renewable generation is always used to supply the load first.
- Excess renewable energy is stored in the battery whenever storage capacity is available.
- Surplus energy is exported to the grid when battery storage is full or electricity prices are high.
- During energy deficits, the battery is discharged whenever economically advantageous.
- The electrical grid supplies any remaining demand, ensuring uninterrupted power delivery.
- When electricity prices are low, the battery may be charged directly from the grid to reduce future operating costs. SEE_Alexandre_S.pdf

### Main Results

The developed hybrid energy system achieved:

- **Annual electrical demand:** 27.45 GWh
- **Renewable energy generation:** 16.06 GWh
- **Grid energy imported:** 13.07 GWh
- **Grid energy exported:** 1.54 GWh
- **Renewable fraction:** 58.52%
- **Energy self-sufficiency:** 52.38%
- **Loss of Power Supply Probability (LPSP):** 0%, thanks to the grid connection. SEE_Alexandre_S.pdf

### Technologies Used

- MATLAB
- Renewable Energy Modeling
- Battery Energy Storage Systems (BESS)
- Energy Management Systems (EMS)
- Smart Grid Simulation
- Power System Analysis

This project demonstrates the design and simulation of a modern hybrid renewable energy system, highlighting the integration of renewable generation, battery storage, and intelligent energy management strategies to improve energy sustainability, operational flexibility, and economic performance.
