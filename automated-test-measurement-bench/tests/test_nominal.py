"""Nominal behaviour: TEST-001, TEST-002, TEST-005 on a healthy DUT, plus DUT model checks."""

import pytest

from dut import DutConfig, SimulatedTemperatureTransmitter
from validation import CASES_BY_ID, Verdict, run_test


@pytest.mark.parametrize("test_id", ["TEST-001", "TEST-002", "TEST-005"])
def test_nominal_cases_pass_on_healthy_dut(make_bench, test_id):
    result = run_test(CASES_BY_ID[test_id], make_bench())
    assert result.verdict is Verdict.PASS, [c for c in result.checks if not c.passed]


@pytest.mark.parametrize("seed_offset", range(5))
def test_nominal_acquisition_is_robust_to_seed(make_bench, seed_offset):
    """The healthy DUT has margin to the limits: the verdict must not depend on the noise realisation."""
    assert run_test(CASES_BY_ID["TEST-001"], make_bench(seed_offset=seed_offset)).verdict is Verdict.PASS


def test_noiseless_dut_follows_design_transfer():
    cfg = DutConfig(gain_error=0.0, offset_v=0.0, noise_c=0.0, noise_v=0.0)
    dut = SimulatedTemperatureTransmitter(cfg)
    for t, v in [(0.0, 0.0), (175.0, 1.25), (350.0, 2.5)]:
        dut.apply_temperature(t)
        assert dut.analog_output_v() == pytest.approx(v, abs=1e-12)


def test_analog_output_saturates():
    dut = SimulatedTemperatureTransmitter(DutConfig(noise_v=0.0, noise_c=0.0))
    dut.apply_temperature(1000.0)
    assert dut.analog_output_v() == DutConfig().v_max
    dut.apply_temperature(-200.0)
    assert dut.analog_output_v() == DutConfig().v_min


def test_identical_seed_gives_identical_measurements(make_bench):
    """Determinism: two runs with the same seed must log identical values."""
    a, b = make_bench(), make_bench()
    run_test(CASES_BY_ID["TEST-005"], a)
    run_test(CASES_BY_ID["TEST-005"], b)
    assert [m.value for m in a.log] == [m.value for m in b.log]
