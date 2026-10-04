# Input data

## Status of the original data set

The report simulation (`HRSsimulationREPORT.pdf`, section 4.1) used an hourly data
set stored in `Data_T.mat`. **That file is not in this repository and never was**:
no commit in the git history contains a `.mat` file. Its origin (measured site
data, a public database, or course-provided data) is not documented.

Consequences:
- The published results (report Table 5.1, README) cannot be reproduced from this repository.
- `examples/run_example.m` runs the code on **synthetic** data from
  `examples/generate_example_data.m`. Those results are for demonstrating the code
  and must not be compared with or presented as the report's results.

To reproduce the report, place the original file at `data/Data_T.mat` and run
`examples/run_original_dataset.m`, or run `legacy/Matlab_see_code.m` from this folder.

## Expected format

`Data_T` is a struct (a table also works) with equal-length numeric vectors, one sample per hour:

| Field | Quantity | Unit | Constraints checked by `check_inputs.m` |
|---|---|---|---|
| `G` | Global irradiance on the module plane | W/m² | finite, ≥ 0 |
| `wind` | Wind speed at hub height | m/s | finite, ≥ 0 |
| `load` | Electrical load | W | finite, ≥ 0 |
| `temp` | Ambient temperature | °C | finite, −60 … 60 |
| `price` | Electricity price | EUR/MWh expected (see note) | finite; negative values allowed, with a warning |

At least 8760 samples are needed for a full year. Shorter series are simulated up to their length.

**Price unit note.** The code divides `price` by 1000, which assumes EUR/MWh.
The report itself says the unit is "EUR/MWh or the original unit of the file". It
prints a last moving-average price of 6.6×10⁻⁶ EUR/kWh, which is not plausible for
EUR/MWh input. The price unit of the original data is therefore **unverified**.
The EMS only compares the price with its own moving average, so the dispatch does
not depend on the unit. No cost indicators are computed.
