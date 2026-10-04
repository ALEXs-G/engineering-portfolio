"""Result export: CSV (raw measurements), JSON (structured results), Markdown
report with traceability matrix, and optional plots (matplotlib)."""

from __future__ import annotations

import csv
import json
from dataclasses import asdict
from pathlib import Path

from acquisition import measurement_rows
from validation import REQUIREMENTS, Campaign, TestResult, Verdict, traceability

SIM_BANNER = (
    "> **Simulation mode.** The DUT and all instruments are software models. "
    "These results demonstrate the test workflow; they are not measurements of physical hardware."
)


def write_all(campaign: Campaign, out_dir: Path, plots: bool = True) -> dict[str, Path]:
    out_dir.mkdir(parents=True, exist_ok=True)
    paths = {
        "csv": write_csv(campaign, out_dir / "measurements.csv"),
        "json": write_json(campaign, out_dir / "results.json"),
        "markdown": write_markdown(campaign, out_dir / "report.md"),
    }
    if plots:
        png = write_plots(campaign, out_dir / "nominal_errors.png")
        if png:
            paths["plot"] = png
    return paths


def write_csv(campaign: Campaign, path: Path) -> Path:
    rows = measurement_rows(campaign.all_measurements)
    fields = list(rows[0].keys()) if rows else []
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)
    return path


def _result_dict(r: TestResult) -> dict:
    return {
        "test_id": r.test_id,
        "title": r.title,
        "requirements": list(r.requirement_ids),
        "category": r.category,
        "injected_fault": r.injected_fault,
        "verdict": r.verdict.value,
        "note": r.note,
        "checks": [asdict(c) for c in r.checks],
        "n_measurements": len(r.measurements),
    }


def summary(campaign: Campaign) -> dict:
    counts = {v.value: sum(r.verdict is v for r in campaign.results) for v in Verdict}
    sc_ok = sum(r.verdict is sc.expected for sc, r in campaign.self_checks)
    return {"verdicts": counts, "self_checks_detected": sc_ok, "self_checks_total": len(campaign.self_checks)}


def write_json(campaign: Campaign, path: Path) -> Path:
    doc = {
        "mode": campaign.mode,
        "config": campaign.config_name,
        "started_utc": campaign.started_utc,
        "python": campaign.python,
        "dut_idn": campaign.dut_idn,
        "summary": summary(campaign),
        "requirements": [asdict(r) for r in REQUIREMENTS.values()],
        "traceability": traceability(campaign),
        "results": [_result_dict(r) for r in campaign.results],
        "self_checks": [
            {"test_id": sc.test_id, "fault": sc.fault.value, "expected": sc.expected.value,
             "observed": r.verdict.value, "detected": r.verdict is sc.expected, "rationale": sc.rationale}
            for sc, r in campaign.self_checks
        ],
    }
    path.write_text(json.dumps(doc, indent=2), encoding="utf-8")
    return path


def write_markdown(campaign: Campaign, path: Path) -> Path:
    s = summary(campaign)
    v = s["verdicts"]
    lines = [
        "# Automated Test Report — Temperature Transmitter",
        "",
    ]
    if campaign.mode == "simulation":
        lines += [SIM_BANNER, ""]
    lines += [
        "| Item | Value |",
        "|---|---|",
        f"| Mode | {campaign.mode} |",
        f"| Configuration | `{campaign.config_name}` |",
        f"| DUT identification | `{campaign.dut_idn}` |",
        f"| Started (UTC) | {campaign.started_utc} |",
        f"| Python | {campaign.python} |",
        f"| Verdicts | PASS {v['PASS']} · FAIL {v['FAIL']} · ERROR {v['ERROR']} · NOT_RUN {v['NOT_RUN']} |",
        f"| Bench self-check | {s['self_checks_detected']}/{s['self_checks_total']} injected faults detected as expected |",
        "",
        "## Requirements traceability",
        "",
        "| Requirement | Tests | Verdicts | Status |",
        "|---|---|---|---|",
    ]
    for row in traceability(campaign):
        lines.append(f"| **{row['requirement']}** {row['text']} | {row['tests'] or '—'} | {row['verdicts'] or '—'} | {row['status']} |")

    lines += ["", "## Test results", "", "| Test | Title | Requirements | Fault | Verdict |", "|---|---|---|---|---|"]
    for r in campaign.results:
        lines.append(f"| {r.test_id} | {r.title} | {', '.join(r.requirement_ids)} | {r.injected_fault} | **{r.verdict.value}** |")

    for r in campaign.results:
        lines += ["", f"### {r.test_id} — {r.title}", ""]
        if r.note:
            lines += [f"_{r.note}_", ""]
        if r.checks:
            lines += ["| Check | Measured | Limit | Result |", "|---|---|---|---|"]
            lines += [f"| {c.description} | {c.measured} | {c.limit} | {'pass' if c.passed else 'FAIL'} |" for c in r.checks]

    if campaign.self_checks:
        lines += [
            "",
            "## Bench self-check (fault injection)",
            "",
            "Each row runs a nominal test against a deliberately faulty simulated DUT. "
            "The row passes if the test reaches the expected verdict, i.e. the test can detect the defect.",
            "",
            "| Test | Injected fault | Expected | Observed | Detected | Rationale |",
            "|---|---|---|---|---|---|",
        ]
        for sc, r in campaign.self_checks:
            lines.append(f"| {sc.test_id} | {sc.fault.value} | {sc.expected.value} | {r.verdict.value} | "
                         f"{'yes' if r.verdict is sc.expected else '**NO**'} | {sc.rationale} |")

    lines += ["", "Raw data: `measurements.csv` · structured results: `results.json`", ""]
    path.write_text("\n".join(lines), encoding="utf-8")
    return path


def write_plots(campaign: Campaign, path: Path) -> Path | None:
    """Error of nominal readings vs. temperature. Skipped if matplotlib is absent."""
    try:
        import matplotlib

        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except ImportError:
        return None

    temp = [(m.stimulus, m.value - m.stimulus) for r in campaign.results if r.test_id in ("TEST-001", "TEST-003")
            for m in r.measurements if m.quantity == "temperature" and m.value is not None and m.status == "OK"]
    volt = [(m.stimulus, (m.value - 2.5 / 350 * m.stimulus) * 1e3) for r in campaign.results if r.test_id == "TEST-002"
            for m in r.measurements if m.quantity == "voltage"]
    if not temp and not volt:
        return None

    surface, ink, ink2, grid, s1, limit = "#fcfcfb", "#0b0b0b", "#52514e", "#e4e3df", "#2a78d6", "#52514e"
    fig, axes = plt.subplots(1, 2, figsize=(10, 3.8), facecolor=surface)
    for ax, data, lim, ylabel, title in (
        (axes[0], temp, 1.0, "Reading error (°C)", "Digital reading error (REQ-002, ±1.0 °C)"),
        (axes[1], volt, 12.5, "Output error (mV)", "Analog output error (REQ-003, ±12.5 mV)"),
    ):
        ax.set_facecolor(surface)
        for y in (lim, -lim):
            ax.axhline(y, color=limit, lw=1.2, ls="--")
        ax.axhline(0, color=grid, lw=1)
        if data:
            x, y = zip(*sorted(data), strict=True)
            ax.plot(x, y, "o", color=s1, ms=7, mec=surface, mew=2)
        ax.set_ylim(-1.6 * lim, 1.6 * lim)
        ax.set_xlabel("Applied temperature (°C)", color=ink)
        ax.set_ylabel(ylabel, color=ink)
        ax.set_title(title, fontsize=10, color=ink, loc="left")
        ax.tick_params(colors=ink2)
        ax.grid(True, color=grid, lw=0.8)
        for side in ("top", "right"):
            ax.spines[side].set_visible(False)
    if campaign.mode == "simulation":
        fig.text(0.01, 0.01, "SIMULATED DUT and instruments — workflow demonstration, not hardware data.",
                 fontsize=8, color=ink2)
    fig.tight_layout(rect=(0, 0.05, 1, 1))
    fig.savefig(path, dpi=130, facecolor=surface)
    plt.close(fig)
    return path
