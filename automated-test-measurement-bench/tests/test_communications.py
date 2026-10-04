"""Communication: TEST-007 response time, TEST-008 link loss, timeout and protocol errors."""

from acquisition import COMM_ERROR, PROTOCOL_ERROR, TIMEOUT
from dut import Fault
from validation import CASES_BY_ID, Verdict, run_test


def test_response_time_passes_on_healthy_dut(make_bench):
    assert run_test(CASES_BY_ID["TEST-007"], make_bench()).verdict is Verdict.PASS


def test_comm_loss_handling_passes(make_bench):
    case = CASES_BY_ID["TEST-008"]
    result = run_test(case, make_bench(case.dut_fault, case.fault_after))
    assert result.verdict is Verdict.PASS, [c for c in result.checks if not c.passed]


def test_comm_loss_never_returns_stale_value(make_bench):
    bench = make_bench(Fault.COMMUNICATION_LOSS, fault_after=1)
    bench.apply_temperature(123.0)
    first = bench.read_temperature()
    second = bench.read_temperature()
    assert first.value is not None
    assert second.status == COMM_ERROR and second.value is None


def test_slow_reply_is_recorded_as_timeout(make_bench):
    bench = make_bench(Fault.TIMEOUT)
    m = bench.read_temperature()
    assert m.status == TIMEOUT and m.value is None
    assert bench.clock.now() == bench.query_timeout_s  # waited exactly one timeout, no real sleep


def test_identification_and_unknown_command(make_bench):
    bench = make_bench()
    assert bench.identify().startswith("SIMULATED,")
    assert bench.link.query("FOO?", 0.2) == "ERR,UNKNOWN_COMMAND"


def test_malformed_reply_is_protocol_error(make_bench):
    bench = make_bench()

    class GarbledLink:
        def query(self, command, timeout_s):
            return "garbage"

    bench.link = GarbledLink()
    m = bench.read_temperature()
    assert m.status == PROTOCOL_ERROR and m.value is None
