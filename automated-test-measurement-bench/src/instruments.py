"""Instrument abstraction layer.

Each instrument role is defined by a small Protocol. The bench only uses
these interfaces, so a simulated implementation can be swapped for a
hardware one without changing the test cases.

Simulated implementations (used by the tests and CI):
    SimulatedTemperatureSource, SimulatedVoltmeter, SimulatedDutLink

Hardware templates (NOT validated against real instruments; optional
dependencies imported lazily):
    ScpiVoltmeter      - SCPI DMM over PyVISA
    SerialDutLink      - DUT text protocol over a serial port (pyserial)
    ManualTemperatureSource - operator sets a calibrator by hand
"""

from __future__ import annotations

from collections.abc import Callable
from typing import Protocol

from dut import SimulatedTemperatureTransmitter


class CommunicationError(Exception):
    """The DUT did not answer at all (link down)."""


class SimClock:
    """Simulated time base: advances only when instruments 'spend' time."""

    def __init__(self) -> None:
        self._t = 0.0

    def now(self) -> float:
        return self._t

    def advance(self, dt_s: float) -> None:
        self._t += dt_s


# --- Interfaces ---------------------------------------------------------------


class TemperatureSource(Protocol):
    uncertainty_c: float | None

    def set_temperature(self, t_c: float) -> None: ...


class Voltmeter(Protocol):
    def read_voltage(self) -> float: ...


class DutLink(Protocol):
    def query(self, command: str, timeout_s: float) -> str: ...


# --- Simulated instruments ----------------------------------------------------


class SimulatedTemperatureSource:
    """Ideal temperature stimulus (stands in for a calibrator or dry block)."""

    uncertainty_c = None  # simulated: no reference uncertainty is claimed

    def __init__(self, dut: SimulatedTemperatureTransmitter, clock: SimClock, settle_s: float = 1.0):
        self._dut = dut
        self._clock = clock
        self._settle_s = settle_s

    def set_temperature(self, t_c: float) -> None:
        self._dut.apply_temperature(t_c)
        self._clock.advance(self._settle_s)


class SimulatedVoltmeter:
    """Voltmeter with finite resolution reading the DUT analog output."""

    def __init__(self, dut: SimulatedTemperatureTransmitter, clock: SimClock,
                 resolution_v: float = 1e-4, read_time_s: float = 0.05):
        self._dut = dut
        self._clock = clock
        self._res = resolution_v
        self._read_time_s = read_time_s

    def read_voltage(self) -> float:
        self._clock.advance(self._read_time_s)
        return round(self._dut.analog_output_v() / self._res) * self._res


class SimulatedDutLink:
    """Text-protocol link to the simulated DUT with timeout semantics."""

    def __init__(self, dut: SimulatedTemperatureTransmitter, clock: SimClock):
        self._dut = dut
        self._clock = clock

    def query(self, command: str, timeout_s: float) -> str:
        reply, latency = self._dut.handle(command)
        if reply is None:
            self._clock.advance(timeout_s)
            raise CommunicationError(f"no reply to {command!r} within {timeout_s} s (link down)")
        if latency > timeout_s:
            self._clock.advance(timeout_s)
            raise TimeoutError(f"reply to {command!r} took {latency} s > timeout {timeout_s} s")
        self._clock.advance(latency)
        return reply


# --- Hardware templates (not validated) ---------------------------------------


class ScpiVoltmeter:
    """DC voltmeter controlled with SCPI over PyVISA (template, not validated)."""

    def __init__(self, resource: str, timeout_ms: int = 5000):
        import pyvisa  # optional dependency: pip install -r requirements-hw.txt

        self._inst = pyvisa.ResourceManager().open_resource(resource)
        self._inst.timeout = timeout_ms
        self.idn = self._inst.query("*IDN?").strip()
        self._inst.write("CONF:VOLT:DC AUTO")

    def read_voltage(self) -> float:
        return float(self._inst.query("READ?"))


class SerialDutLink:
    """DUT text protocol over a serial port (template, not validated)."""

    def __init__(self, port: str, baudrate: int = 115200):
        import serial  # optional dependency: pip install -r requirements-hw.txt

        self._ser = serial.Serial(port, baudrate=baudrate, timeout=1.0)

    def query(self, command: str, timeout_s: float) -> str:
        self._ser.reset_input_buffer()          # never read a stale (late) reply
        self._ser.timeout = timeout_s
        self._ser.write((command + "\n").encode("ascii"))
        line = self._ser.readline()
        if not line:
            raise TimeoutError(f"no reply to {command!r} within {timeout_s} s")
        return line.decode("ascii", errors="replace").strip()


class ManualTemperatureSource:
    """Operator-driven stimulus, e.g. a hand-set thermocouple calibrator."""

    def __init__(self, uncertainty_c: float | None = None, prompt: Callable[[str], str] = input):
        self.uncertainty_c = uncertainty_c
        self._prompt = prompt

    def set_temperature(self, t_c: float) -> None:
        self._prompt(f"Set the temperature source to {t_c:.2f} degC, wait for it to settle, then press Enter.")
