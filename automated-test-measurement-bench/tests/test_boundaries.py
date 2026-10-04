"""Range boundaries and out-of-range detection: TEST-003, TEST-004, REQ-005 edges."""

import pytest

from dut import DutConfig, SimulatedTemperatureTransmitter, Status
from validation import CASES_BY_ID, Verdict, run_test


@pytest.mark.parametrize("test_id", ["TEST-003", "TEST-004"])
def test_boundary_cases_pass(make_bench, test_id):
    result = run_test(CASES_BY_ID[test_id], make_bench())
    assert result.verdict is Verdict.PASS, [c for c in result.checks if not c.passed]


@pytest.mark.parametrize(
    "reading, expected",
    [
        (0.0, Status.OK),
        (-0.5, Status.OK),            # inside tolerance band
        (-0.51, Status.OUT_OF_RANGE),
        (350.0, Status.OK),
        (350.5, Status.OK),
        (350.51, Status.OUT_OF_RANGE),
        (None, Status.SENSOR_OPEN),
    ],
)
def test_status_classification_at_edges(reading, expected):
    assert SimulatedTemperatureTransmitter(DutConfig()).status_for(reading) is expected


def test_boundary_test_detects_missing_range_check(make_bench):
    """If the DUT accepted readings far outside the range, TEST-004 must fail."""
    bench = make_bench()
    bench.link._dut.config = DutConfig(range_tolerance_c=1000.0)  # simulate a DUT with no range check
    assert run_test(CASES_BY_ID["TEST-004"], bench).verdict is Verdict.FAIL
