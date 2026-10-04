"""Requirements, test cases, verdict logic and campaign execution.

Workflow per test case:
    Requirement -> Test case -> Stimulus -> Measurement -> Check vs. limits
    -> Verdict -> Log -> Result -> Report

Verdicts:
    PASS     all checks met
    FAIL     at least one check not met (the DUT does not meet the requirement)
    ERROR    the test could not be completed (e.g. link failure during a test
             that does not target communication); says nothing about the DUT
    NOT_RUN  not executable in the current mode (e.g. fault injection on hardware)
"""

from __future__ import annotations

import enum
import platform
import statistics
from collections.abc import Callable
from dataclasses import dataclass, field
from datetime import datetime, timezone

from acquisition import COMM_ERROR, LINK_FAILURES, TIMEOUT, Bench, Measurement
from dut import Fault, Status


class Verdict(str, enum.Enum):
    PASS = "PASS"
    FAIL = "FAIL"
    ERROR = "ERROR"
    NOT_RUN = "NOT_RUN"


class TestAborted(Exception):
    """Raised by a procedure when a measurement could not be obtained."""

    __test__ = False  # not a pytest test class


# --- Requirements ---------------------------------------------------------------


@dataclass(frozen=True)
class Requirement:
    id: str
    text: str
    category: str


_REQUIREMENT_TABLE = [
    ("REQ-001", "Function",
     "The DUT shall report temperature with status OK over 0 degC to 350 degC."),
    ("REQ-002", "Performance",
     "The reported temperature shall be within +/-1.0 degC of the applied temperature over 0-350 degC."),
    ("REQ-003", "Performance",
     "The analog output shall follow Vo = 2.5 V / 350 degC x T within +/-12.5 mV (0.5 % FS)."),
    ("REQ-004", "Performance",
     "The standard deviation of 20 consecutive readings at constant temperature shall be <= 0.2 degC."),
    ("REQ-005", "Diagnostics",
     "Readings more than 0.5 degC outside 0-350 degC shall be reported with status OUT_OF_RANGE."),
    ("REQ-006", "Diagnostics",
     "An open sensor shall be reported as SENSOR_OPEN with no numeric value, and the analog output shall go upscale (>= 2.55 V)."),
    ("REQ-007", "Interface",
     "The DUT shall answer a measurement query within 200 ms."),
    ("REQ-008", "Test system",
     "On loss of communication the test system shall record COMM_ERROR with no value and shall not reuse previous data."),
    ("REQ-009", "Test system",
     "Every measurement shall be logged with test ID, requirement IDs, stimulus, value, unit, status and time."),
]
REQUIREMENTS: dict[str, Requirement] = {i: Requirement(i, t, c) for i, c, t in _REQUIREMENT_TABLE}


# --- Test cases -------------------------------------------------------------------


@dataclass
class Check:
    description: str
    measured: str
    limit: str
    passed: bool


@dataclass(frozen=True)
class TestCase:
    id: str
    title: str
    requirement_ids: tuple[str, ...]
    category: str                       # nominal | boundary | fault | communication | test-system
    procedure: Callable[[Bench], list[Check]]
    stimulus: str
    dut_fault: Fault = Fault.NONE        # fault the DUT must have for this test (fault-handling tests)
    fault_after: int = 0

    __test__ = False


@dataclass
class TestResult:
    test_id: str
    title: str
    requirement_ids: tuple[str, ...]
    category: str
    injected_fault: str
    verdict: Verdict
    checks: list[Check]
    measurements: list[Measurement]
    note: str = ""

    __test__ = False


def _fmt(x: float | None, unit: str, nd: int = 3) -> str:
    return "none" if x is None else f"{x:.{nd}f} {unit}"


def _require(m: Measurement) -> Measurement:
    if m.status in LINK_FAILURES:
        raise TestAborted(f"{m.quantity}: {m.status} ({m.raw})")
    return m


def _check_temperature(bench: Bench, t_c: float, tol_c: float = 1.0) -> list[Check]:
    bench.apply_temperature(t_c)
    m = _require(bench.read_temperature())
    checks = [Check(f"status at {t_c:g} degC", m.status, Status.OK.value, m.status == Status.OK.value)]
    err = None if m.value is None else m.value - t_c
    checks.append(Check(f"error at {t_c:g} degC", _fmt(err, "degC"), f"|e| <= {tol_c} degC",
                        err is not None and abs(err) <= tol_c))
    return checks


def _check_status(bench: Bench, t_c: float, expected: Status) -> Check:
    bench.apply_temperature(t_c)
    m = _require(bench.read_temperature())
    return Check(f"status at {t_c:g} degC", m.status, expected.value, m.status == expected.value)


# Procedures ----------------------------------------------------------------------

NOMINAL_POINTS_C = (25.0, 100.0, 200.0, 300.0)


def proc_nominal_acquisition(bench: Bench) -> list[Check]:
    return [c for t in NOMINAL_POINTS_C for c in _check_temperature(bench, t)]


def proc_analog_transfer(bench: Bench) -> list[Check]:
    checks = []
    for t in NOMINAL_POINTS_C:
        bench.apply_temperature(t)
        m = _require(bench.read_analog_output())
        expected = 2.5 / 350.0 * t
        err = m.value - expected
        checks.append(Check(f"Vo error at {t:g} degC", _fmt(err * 1e3, "mV", 2), "|e| <= 12.5 mV", abs(err) <= 0.0125))
    return checks


def proc_boundaries(bench: Bench) -> list[Check]:
    checks = _check_temperature(bench, 0.0) + _check_temperature(bench, 350.0)
    checks.append(_check_status(bench, -1.0, Status.OUT_OF_RANGE))
    checks.append(_check_status(bench, 351.0, Status.OUT_OF_RANGE))
    return checks


def proc_out_of_range_stimulus(bench: Bench) -> list[Check]:
    return [_check_status(bench, t, Status.OUT_OF_RANGE) for t in (-10.0, 360.0, 500.0)]


def proc_repeatability(bench: Bench, n: int = 20, t_c: float = 150.0) -> list[Check]:
    bench.apply_temperature(t_c)
    values = []
    for _ in range(n):
        m = _require(bench.read_temperature())
        if m.value is None:
            return [Check("numeric reading", m.status, "value present", False)]
        values.append(m.value)
    sd = statistics.stdev(values)
    return [Check(f"std. dev. of {n} readings at {t_c:g} degC", _fmt(sd, "degC"), "<= 0.2 degC", sd <= 0.2)]


def proc_sensor_open(bench: Bench) -> list[Check]:
    bench.apply_temperature(100.0)
    m = _require(bench.read_temperature())
    v = _require(bench.read_analog_output())
    return [
        Check("status with open sensor", m.status, Status.SENSOR_OPEN.value, m.status == Status.SENSOR_OPEN.value),
        Check("numeric value with open sensor", _fmt(m.value, "degC"), "none", m.value is None),
        Check("analog output with open sensor", _fmt(v.value, "V"), ">= 2.55 V", v.value >= 2.55),
    ]


def proc_sensor_value_out_of_range(bench: Bench) -> list[Check]:
    return [_check_status(bench, 100.0, Status.OUT_OF_RANGE)]


def proc_response_time(bench: Bench, n: int = 10) -> list[Check]:
    bench.apply_temperature(25.0)
    times = []
    for _ in range(n):
        m = bench.read_response_time()
        if m.status == TIMEOUT:
            return [Check("response time", "no reply within timeout", "<= 0.200 s", False)]
        _require(m)
        times.append(m.value)
    worst = max(times)
    return [Check(f"max response time over {n} queries", _fmt(worst, "s"), "<= 0.200 s", worst <= 0.2)]


def proc_comm_loss_handling(bench: Bench) -> list[Check]:
    bench.apply_temperature(100.0)
    first = bench.read_temperature()
    second = bench.read_temperature()      # link is lost from the 2nd query onwards
    return [
        Check("first reading before link loss", first.status, Status.OK.value, first.status == Status.OK.value),
        Check("reading after link loss: status", second.status, COMM_ERROR, second.status == COMM_ERROR),
        Check("reading after link loss: value", _fmt(second.value, "degC"), "none (no stale data)", second.value is None),
    ]


LOG_FIELDS = ("test_id", "requirement_ids", "quantity", "unit", "status", "timestamp_utc")


def proc_log_completeness(bench: Bench) -> list[Check]:
    bench.apply_temperature(50.0)
    bench.read_temperature()
    bench.read_analog_output()
    bench.read_response_time()
    incomplete = [m for m in bench.log if any(getattr(m, f) in ("", None) for f in LOG_FIELDS) or m.stimulus is None]
    return [Check("log records with all mandatory fields", f"{len(bench.log) - len(incomplete)}/{len(bench.log)}",
                  "all", not incomplete and len(bench.log) > 0)]


TEST_CASES: list[TestCase] = [
    TestCase("TEST-001", "Nominal temperature acquisition", ("REQ-001", "REQ-002"), "nominal",
             proc_nominal_acquisition, "25, 100, 200, 300 degC"),
    TestCase("TEST-002", "Analog output transfer function", ("REQ-003",), "nominal",
             proc_analog_transfer, "25, 100, 200, 300 degC"),
    TestCase("TEST-003", "Range boundaries", ("REQ-001", "REQ-002", "REQ-005"), "boundary",
             proc_boundaries, "0, 350 degC (in); -1, 351 degC (out)"),
    TestCase("TEST-004", "Out-of-range stimulus", ("REQ-005",), "boundary",
             proc_out_of_range_stimulus, "-10, 360, 500 degC"),
    TestCase("TEST-005", "Noise / repeatability", ("REQ-004",), "nominal",
             proc_repeatability, "150 degC, 20 readings"),
    TestCase("TEST-006", "Open sensor detection", ("REQ-006",), "fault",
             proc_sensor_open, "100 degC, sensor disconnected", dut_fault=Fault.SENSOR_DISCONNECTED),
    TestCase("TEST-007", "Query response time", ("REQ-007",), "communication",
             proc_response_time, "25 degC, 10 queries"),
    TestCase("TEST-008", "Communication loss handling", ("REQ-008",), "communication",
             proc_comm_loss_handling, "100 degC, link lost after 1st query",
             dut_fault=Fault.COMMUNICATION_LOSS, fault_after=1),
    TestCase("TEST-009", "Sensor value out of range", ("REQ-005",), "fault",
             proc_sensor_value_out_of_range, "100 degC, sensor reports 500 degC",
             dut_fault=Fault.SENSOR_OUT_OF_RANGE),
    TestCase("TEST-010", "Measurement log completeness", ("REQ-009",), "test-system",
             proc_log_completeness, "50 degC, 3 measurement types"),
]
CASES_BY_ID = {c.id: c for c in TEST_CASES}


# Bench self-verification: a nominal test run against a deliberately faulty DUT
# must NOT pass. This shows that each test can detect the defect it targets.
@dataclass(frozen=True)
class SelfCheck:
    test_id: str
    fault: Fault
    expected: Verdict
    rationale: str


SELF_CHECKS: list[SelfCheck] = [
    SelfCheck("TEST-001", Fault.SENSOR_OUT_OF_RANGE, Verdict.FAIL, "corrupted sensor value must fail accuracy/status"),
    SelfCheck("TEST-001", Fault.SENSOR_DISCONNECTED, Verdict.FAIL, "open sensor must fail nominal acquisition"),
    SelfCheck("TEST-002", Fault.SENSOR_DISCONNECTED, Verdict.FAIL, "burnout voltage must fail transfer check"),
    SelfCheck("TEST-005", Fault.EXCESSIVE_NOISE, Verdict.FAIL, "noise x50 must fail repeatability limit"),
    SelfCheck("TEST-007", Fault.TIMEOUT, Verdict.FAIL, "500 ms reply must fail 200 ms requirement"),
    SelfCheck("TEST-001", Fault.COMMUNICATION_LOSS, Verdict.ERROR, "link loss must abort the test, not pass or fail it"),
]


# --- Execution ----------------------------------------------------------------------

BenchFactory = Callable[[Fault, int], Bench]


def run_test(case: TestCase, bench: Bench, fault_label: str | None = None) -> TestResult:
    fault = fault_label or case.dut_fault.value
    bench.set_context(case.id, case.requirement_ids, fault)
    start = len(bench.log)
    note = ""
    try:
        checks = case.procedure(bench)
        verdict = Verdict.PASS if checks and all(c.passed for c in checks) else Verdict.FAIL
    except TestAborted as exc:
        checks, verdict, note = [], Verdict.ERROR, f"aborted: {exc}"
    return TestResult(case.id, case.title, case.requirement_ids, case.category,
                      fault, verdict, checks, bench.log[start:], note)


@dataclass
class Campaign:
    mode: str
    config_name: str
    started_utc: str
    python: str
    results: list[TestResult] = field(default_factory=list)
    self_checks: list[tuple[SelfCheck, TestResult]] = field(default_factory=list)
    dut_idn: str = ""

    @property
    def all_measurements(self) -> list[Measurement]:
        out = [m for r in self.results for m in r.measurements]
        return out + [m for _, r in self.self_checks for m in r.measurements]


def run_campaign(factory: BenchFactory, mode: str, config_name: str,
                 cases: list[TestCase] | None = None, include_self_checks: bool = True,
                 fault_injection_available: bool = True) -> Campaign:
    campaign = Campaign(mode, config_name, datetime.now(timezone.utc).isoformat(timespec="seconds"),
                        platform.python_version())
    campaign.dut_idn = factory(Fault.NONE, 0).identify()

    for case in cases or TEST_CASES:
        if case.dut_fault is not Fault.NONE and not fault_injection_available:
            campaign.results.append(TestResult(case.id, case.title, case.requirement_ids, case.category,
                                               case.dut_fault.value, Verdict.NOT_RUN, [], [],
                                               "requires fault injection; not available in this mode"))
            continue
        campaign.results.append(run_test(case, factory(case.dut_fault, case.fault_after)))

    if include_self_checks and fault_injection_available:
        for sc in SELF_CHECKS:
            result = run_test(CASES_BY_ID[sc.test_id], factory(sc.fault, 0), fault_label=sc.fault.value)
            campaign.self_checks.append((sc, result))
    return campaign


def traceability(campaign: Campaign) -> list[dict]:
    """Requirement -> tests -> verdicts. A requirement passes only if all its tests pass."""
    rows = []
    for req in REQUIREMENTS.values():
        linked = [r for r in campaign.results if req.id in r.requirement_ids]
        verdicts = {r.verdict for r in linked}
        if not linked:
            status = "NOT COVERED"
        elif verdicts == {Verdict.PASS}:
            status = "VERIFIED"
        elif Verdict.FAIL in verdicts:
            status = "FAILED"
        else:
            status = "INCOMPLETE"
        rows.append({
            "requirement": req.id,
            "text": req.text,
            "tests": ", ".join(r.test_id for r in linked),
            "verdicts": ", ".join(f"{r.test_id}:{r.verdict.value}" for r in linked),
            "status": status,
        })
    return rows
