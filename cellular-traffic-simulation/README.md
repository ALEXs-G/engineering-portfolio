# Cellular Traffic Dimensioning with Erlang-B (Python)

| | |
|---|---|
| **Status** | Complete. Script runs and reproduces standard Erlang-B values. |
| **Context** | Academic laboratory assignment (mobile/cellular communications), University of Beira Interior. Python re-implementation by the author. |
| **My contribution** | Python implementation and notebook |
| **Evidence** | [`erlang_b_simulation.py`](erlang_b_simulation.py) · [`erlang_b_simulation.ipynb`](erlang_b_simulation.ipynb) |
| **Report** | Not included in the repository. The previous README referenced `docs/Trabalho Laboratorial 3.pdf`, which was never committed. |

---

## What it computes

Erlang-B blocking probability, using the numerically stable recursion
`B(0) = 1`, `B(k) = ρ·B(k−1) / (k + ρ·B(k−1))`:

1. Blocking probability against the number of channels N = 4…15, for ρ = 0.5…8 Erlang
2. Blocking probability against offered traffic ρ = 1…3 Erlang, for N = 10, 11, 15
3. Maximum supported traffic for a target blocking probability (2 %, and 0.1 % for N = 11), found by a 0.01 Erlang search

## Output (verified run)

```
=== Supported traffic for Pb_max = 2% ===
N=10: rho ≈ 5.08, Pb ≈ 0.019921
N=11: rho ≈ 5.84, Pb ≈ 0.019972
N=15: rho ≈ 9.00, Pb ≈ 0.019868

=== Supported traffic for N = 11 and Phf_max = 0.1% ===
N=11: rho ≈ 3.65, Pb ≈ 0.000998
```

These agree with published Erlang-B tables (e.g. N = 10 at 2 % ≈ 5.08 E; N = 15 at 2 % ≈ 9.01 E).
The 9.00 E result is a consequence of the 0.01 E search step.

## Run

```bash
pip install -r requirements.txt
python erlang_b_simulation.py      # prints tables, writes results.txt and two PNG plots
```
