"""Acquisition layer: applies stimuli, takes measurements and logs every record.

Every reading becomes a Measurement record (REQ-009). Communication problems
are recorded as a status (TIMEOUT / COMM_ERROR) with no value, never as a
reused previous value (REQ-008).
"""

from __future__ import annotations

import json
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from pathlib import Path

from dut import DutConfig, Fault, SimulatedTemperatureTransmitter
from instruments import (
    CommunicationError,
    DutLink,
    SimClock,
    SimulatedDutLink,
    SimulatedTemperatureSource,
    SimulatedVoltmeter,
    TemperatureSource,
    Voltmeter,
)

COMM_ERROR = "COMM_ERROR"
TIMEOUT = "TIMEOUT"
PROTOCOL_ERROR = "PROTOCOL_ERROR"
LINK_FAILURES = {COMM_ERROR, TIMEOUT, PROTOCOL_ERROR}


@dataclass
class Measurement:
    test_id: str
    requirement_ids: str          # ";"-separated, kept flat for CSV
    injected_fault: str           # "none" for normal tests
    quantity: str                 # temperature | voltage | response_time
    stimulus: float | None
    stimulus_unit: str
    value: float | None
    unit: str
    status: str                   # DUT status, or COMM_ERROR / TIMEOUT / PROTOCOL_ERROR
    t_rel_s: float                # bench clock
    timestamp_utc: str
    raw: str = ""


@dataclass
class Bench:
    """A set of instruments plus the measurement log."""

    source: TemperatureSource
    voltmeter: Voltmeter
    link: DutLink
    clock: SimClock
    mode: str
    query_timeout_s: float = 0.2
    log: list[Measurement] = field(default_factory=list)
    _context: tuple[str, str, str] = ("", "", "none")

    def set_context(self, test_id: str, requirement_ids: tuple[str, ...], injected_fault: str = "none") -> None:
        self._context = (test_id, ";".join(requirement_ids), injected_fault)

    def _record(self, quantity, stimulus, stimulus_unit, value, unit, status, raw="") -> Measurement:
        m = Measurement(
            test_id=self._context[0],
            requirement_ids=self._context[1],
            injected_fault=self._context[2],
            quantity=quantity,
            stimulus=stimulus,
            stimulus_unit=stimulus_unit,
            value=value,
            unit=unit,
            status=status,
            t_rel_s=round(self.clock.now(), 6),
            timestamp_utc=datetime.now(timezone.utc).isoformat(timespec="milliseconds"),
            raw=raw,
        )
        self.log.append(m)
        return m

    # --- stimulus ------------------------------------------------------------

    def apply_temperature(self, t_c: float) -> None:
        self.source.set_temperature(t_c)
        self._stimulus_c = t_c

    @property
    def stimulus_c(self) -> float | None:
        return getattr(self, "_stimulus_c", None)

    # --- measurements --------------------------------------------------------

    def read_temperature(self) -> Measurement:
        """Query the DUT digital reading: returns value [degC] and DUT status."""
        start = self.clock.now()
        try:
            reply = self.link.query("MEAS:TEMP?", self.query_timeout_s)
        except TimeoutError as exc:
            return self._record("temperature", self.stimulus_c, "degC", None, "degC", TIMEOUT, str(exc))
        except CommunicationError as exc:
            return self._record("temperature", self.stimulus_c, "degC", None, "degC", COMM_ERROR, str(exc))
        finally:
            self._last_latency_s = self.clock.now() - start

        try:
            value_text, status = reply.split(",", 1)
            value = None if value_text.upper() == "NAN" else float(value_text)
        except ValueError:
            return self._record("temperature", self.stimulus_c, "degC", None, "degC", PROTOCOL_ERROR, reply)
        return self._record("temperature", self.stimulus_c, "degC", value, "degC", status.strip(), reply)

    def read_response_time(self) -> Measurement:
        """Time one measurement query; the reply itself is also logged."""
        m = self.read_temperature()
        if m.status in LINK_FAILURES:
            return self._record("response_time", self.stimulus_c, "degC", None, "s", m.status, m.raw)
        return self._record("response_time", self.stimulus_c, "degC", round(self._last_latency_s, 6), "s", "OK")

    def read_analog_output(self) -> Measurement:
        v = self.voltmeter.read_voltage()
        return self._record("voltage", self.stimulus_c, "degC", v, "V", "OK")

    def identify(self) -> str:
        return self.link.query("*IDN?", self.query_timeout_s)


# --- Bench construction -------------------------------------------------------


def load_config(path: str | Path) -> dict:
    return json.loads(Path(path).read_text(encoding="utf-8"))


def build_simulated_bench(config: dict, fault: Fault = Fault.NONE, fault_after: int = 0,
                          seed_offset: int = 0) -> Bench:
    """Fresh simulated DUT + instruments. Same config and seed give identical results."""
    dut_cfg = DutConfig(**config.get("dut", {}))
    seed = int(config.get("seed", 0)) + seed_offset
    dut = SimulatedTemperatureTransmitter(dut_cfg, seed=seed, fault=fault, fault_after=fault_after)
    clock = SimClock()
    inst = config.get("instruments", {})
    return Bench(
        source=SimulatedTemperatureSource(dut, clock, settle_s=inst.get("settle_s", 1.0)),
        voltmeter=SimulatedVoltmeter(dut, clock, resolution_v=inst.get("voltmeter_resolution_v", 1e-4)),
        link=SimulatedDutLink(dut, clock),
        clock=clock,
        mode="simulation",
        query_timeout_s=config.get("query_timeout_s", 0.2),
    )


def build_hardware_bench(config: dict) -> Bench:
    """Bench using real instruments (templates in instruments.py; not validated)."""
    from instruments import ManualTemperatureSource, ScpiVoltmeter, SerialDutLink

    hw = config["hardware"]

    class WallClock(SimClock):
        def __init__(self) -> None:
            import time

            self._time = time
            self._t0 = time.monotonic()

        def now(self) -> float:
            return self._time.monotonic() - self._t0

        def advance(self, dt_s: float) -> None:  # real time passes by itself
            pass

    return Bench(
        source=ManualTemperatureSource(uncertainty_c=hw.get("source_uncertainty_c")),
        voltmeter=ScpiVoltmeter(hw["visa_resource"]),
        link=SerialDutLink(hw["serial_port"], hw.get("baudrate", 115200)),
        clock=WallClock(),
        mode="hardware",
        query_timeout_s=config.get("query_timeout_s", 0.2),
    )


def measurement_rows(log: list[Measurement]) -> list[dict]:
    return [asdict(m) for m in log]
