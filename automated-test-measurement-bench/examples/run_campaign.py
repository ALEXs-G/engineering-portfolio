"""Run a full test campaign and write CSV / JSON / Markdown / PNG results.

    python examples/run_campaign.py                         # simulation, default config
    python examples/run_campaign.py --out results/my_run
    python examples/run_campaign.py --config configs/hardware.json   # hardware mode (not validated)

Exit code: 0 if every test passed and every self-check detected its fault,
1 otherwise (usable as a CI gate).
"""

from __future__ import annotations

import argparse
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "src"))

from acquisition import build_hardware_bench, build_simulated_bench, load_config  # noqa: E402
from report import summary, write_all  # noqa: E402
from validation import run_campaign  # noqa: E402


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--config", default=str(ROOT / "configs" / "simulation.json"))
    ap.add_argument("--out", default=None, help="output folder (default: results/<UTC timestamp>)")
    ap.add_argument("--no-plots", action="store_true")
    args = ap.parse_args(argv)

    config = load_config(args.config)
    mode = config.get("mode", "simulation")
    if mode == "simulation":
        def factory(fault, fault_after):
            return build_simulated_bench(config, fault, fault_after)
        fault_injection = True
    else:
        bench = build_hardware_bench(config)

        def factory(fault, fault_after):  # one physical setup; faults cannot be injected in software
            return bench
        fault_injection = False

    campaign = run_campaign(factory, mode, Path(args.config).name, fault_injection_available=fault_injection)

    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    out = Path(args.out) if args.out else ROOT / "results" / f"{mode}_{stamp}"
    paths = write_all(campaign, out, plots=not args.no_plots)

    s = summary(campaign)
    print(f"Mode: {mode}  DUT: {campaign.dut_idn}")
    for r in campaign.results:
        print(f"  {r.test_id:9s} {r.verdict.value:8s} {r.title}")
    print(f"Verdicts: {s['verdicts']}")
    print(f"Self-check: {s['self_checks_detected']}/{s['self_checks_total']} faults detected as expected")
    for kind, p in paths.items():
        print(f"  {kind:9s} {p}")

    ok = s["verdicts"]["FAIL"] == 0 and s["verdicts"]["ERROR"] == 0 and s["self_checks_detected"] == s["self_checks_total"]
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
