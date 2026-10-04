# Cellular Traffic Simulation using Erlang-B

This project models the **blocking probability** and **supported traffic** in cellular communication systems using the **Erlang-B formula**.

| | |
|---|---|
| **Status** | Complete — the script runs and reproduces standard Erlang-B values |
| **Context** | Academic laboratory assignment (Mobile Communications), University of Beira Interior |
| **Team** | Individual |
| **My contribution** | Python implementation and notebook |
| **Evidence** | [erlang_b_simulation.py](erlang_b_simulation.py) · [erlang_b_simulation.ipynb](erlang_b_simulation.ipynb) |

## Overview

In a cellular system with a limited number of channels, new calls may be blocked when all channels are occupied. This project evaluates that effect by computing:

- Blocking probability as a function of the number of channels
- Blocking probability as a function of offered traffic
- Maximum supported traffic for a target blocking probability

## Topics Covered

- Erlang-B traffic model
- Blocking probability
- Supported traffic analysis
- Cellular systems dimensioning

## Technologies Used

- Python
- NumPy
- Matplotlib

## Files

- `erlang_b_simulation.py` — main simulation script
- `erlang_b_simulation.ipynb` — notebook version
- `requirements.txt` — Python dependencies

## How to Run

Install dependencies:

```bash
pip install -r requirements.txt
```

Run the simulation:

```bash
python erlang_b_simulation.py
```

## Example Analyses

The script generates:

1. Blocking probability vs number of channels
2. Blocking probability vs offered traffic
3. Supported traffic for a maximum blocking probability target
