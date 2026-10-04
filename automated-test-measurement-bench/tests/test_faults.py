"""Fault handling (TEST-006, TEST-009) and bench self-verification by fault injection."""

import pytest

from acquisition import COMM_ERROR
from dut import Fault, Status
from validation import CASES_BY_ID, SELF_CHECKS, Verdict, run_test


@pytest.mark.parametrize("test_id", ["TEST-006", "TEST-009"])
def test_fault_handling_cases_pass(make_bench, test_id):
    case = CASES_BY_ID[test_id]
    result = run_test(case, make_bench(case.dut_fault, case.fault_after))
    assert result.verdict is Verdict.PASS, [c for c in result.checks if not c.passed]


@pytest.mark.parametrize("sc", SELF_CHECKS, ids=lambda sc: f"{sc.test_id}-{sc.fault.value}")
def test_bench_detects_injected_fault(make_bench, sc):
    """A nominal test run on a faulty DUT must reach the expected non-PASS verdict."""
    result = run_test(CASES_BY_ID[sc.test_id], make_bench(sc.fault))
    assert result.verdict is sc.expected


def test_open_sensor_reports_no_value_and_burnout(make_bench):
    bench = make_bench(Fault.SENSOR_DISCONNECTED)
    bench.apply_temperature(200.0)
    m = bench.read_temperature()
    assert m.status == Status.SENSOR_OPEN.value and m.value is None
    assert bench.read_analog_output().value >= 2.55


def test_fault_activates_after_configured_query_count(make_bench):
    bench = make_bench(Fault.SENSOR_DISCONNECTED, fault_after=2)
    bench.apply_temperature(100.0)
    statuses = [bench.read_temperature().status for _ in range(4)]
    assert statuses == ["OK", "OK", "SENSOR_OPEN", "SENSOR_OPEN"]


def test_link_loss_during_nominal_test_is_error_not_fail(make_bench):
    """A link failure says nothing about DUT performance: verdict ERROR, with a note."""
    result = run_test(CASES_BY_ID["TEST-001"], make_bench(Fault.COMMUNICATION_LOSS))
    assert result.verdict is Verdict.ERROR
    assert COMM_ERROR in result.note
