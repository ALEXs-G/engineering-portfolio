"""Campaign execution, traceability (REQ -> TEST -> verdict) and report files (TEST-010 / REQ-009)."""

import csv
import json

from acquisition import build_simulated_bench
from report import write_all
from validation import REQUIREMENTS, TEST_CASES, Verdict, run_campaign, traceability


def _campaign(config):
    return run_campaign(lambda f, n: build_simulated_bench(config, f, n), "simulation", "simulation.json")


def test_full_campaign_passes_and_detects_all_faults(config):
    c = _campaign(config)
    assert all(r.verdict is Verdict.PASS for r in c.results)
    assert all(r.verdict is sc.expected for sc, r in c.self_checks)


def test_every_requirement_is_covered_and_verified(config):
    rows = traceability(_campaign(config))
    assert {r["requirement"] for r in rows} == set(REQUIREMENTS)
    assert all(r["status"] == "VERIFIED" for r in rows), rows


def test_every_test_traces_to_known_requirements():
    for case in TEST_CASES:
        assert case.requirement_ids and set(case.requirement_ids) <= set(REQUIREMENTS)


def test_report_files_are_complete(config, tmp_path):
    paths = write_all(_campaign(config), tmp_path, plots=False)

    with paths["csv"].open(encoding="utf-8") as f:
        rows = list(csv.DictReader(f))
    assert rows and all(r["test_id"] and r["requirement_ids"] and r["timestamp_utc"] for r in rows)
    assert {"none", "excessive_noise"} <= {r["injected_fault"] for r in rows}

    doc = json.loads(paths["json"].read_text(encoding="utf-8"))
    assert doc["mode"] == "simulation"
    assert len(doc["results"]) == len(TEST_CASES)

    md = paths["markdown"].read_text(encoding="utf-8")
    assert "Simulation mode" in md and "Requirements traceability" in md


def test_hardware_mode_marks_fault_tests_not_run(config):
    c = run_campaign(lambda f, n: build_simulated_bench(config), "hardware", "x.json",
                     fault_injection_available=False)
    not_run = {r.test_id for r in c.results if r.verdict is Verdict.NOT_RUN}
    assert not_run == {case.id for case in TEST_CASES if case.dut_fault.value != "none"}
    assert c.self_checks == []
