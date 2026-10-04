"""Simulated device under test (DUT): a temperature transmitter.

The behavioural model uses the design targets of the thermocouple project in
this portfolio (../thermocouple-temperature-system): 0-350 degC range and a
0-2.5 V analog output. It is NOT a model fitted to that hardware. It exists so
the test workflow can run without laboratory equipment.

The DUT exposes two interfaces, as a real transmitter would:
  * an analog output voltage, read by a voltmeter;
  * a line-based text protocol (SCPI-like) for digital readings.

Faults are injected deterministically: a fault becomes active after a given
number of measurement queries, and all randomness comes from a seeded RNG.
"""

from __future__ import annotations

import enum
import random
from dataclasses import dataclass


class Fault(str, enum.Enum):
    NONE = "none"
    SENSOR_OUT_OF_RANGE = "sensor_out_of_range"  # sensor element reports an impossible value
    SENSOR_DISCONNECTED = "sensor_disconnected"  # open thermocouple
    EXCESSIVE_NOISE = "excessive_noise"          # noise far above specification
    TIMEOUT = "timeout"                          # DUT answers, but too late
    COMMUNICATION_LOSS = "communication_loss"    # DUT never answers


class Status(str, enum.Enum):
    OK = "OK"
    OUT_OF_RANGE = "OUT_OF_RANGE"
    SENSOR_OPEN = "SENSOR_OPEN"


@dataclass(frozen=True)
class DutConfig:
    """Parameters of the simulated transmitter (defaults = healthy unit)."""

    range_min_c: float = 0.0
    range_max_c: float = 350.0
    range_tolerance_c: float = 0.5      # readings within this band outside the range are still OK
    span_v: float = 2.5                 # analog output at range_max_c
    gain_error: float = 0.001           # fractional gain error of the analog output
    offset_v: float = 0.002             # analog output offset
    noise_c: float = 0.05               # 1-sigma noise of the temperature channel
    noise_v: float = 0.0003             # 1-sigma noise of the analog output
    v_min: float = -0.05                # output stage saturation limits
    v_max: float = 2.6
    burnout_v: float = 2.6              # upscale burnout on open sensor
    response_time_s: float = 0.02       # nominal reply latency
    timeout_response_s: float = 0.5     # reply latency under Fault.TIMEOUT
    noise_fault_factor: float = 50.0    # noise multiplier under Fault.EXCESSIVE_NOISE
    out_of_range_sensor_c: float = 500.0  # sensor value under Fault.SENSOR_OUT_OF_RANGE

    @property
    def sensitivity_v_per_c(self) -> float:
        return self.span_v / (self.range_max_c - self.range_min_c)


class SimulatedTemperatureTransmitter:
    """Behavioural model of a temperature transmitter with fault injection."""

    IDN = "SIMULATED,TEMP-TX,SN0001,1.0"

    def __init__(
        self,
        config: DutConfig | None = None,
        seed: int = 0,
        fault: Fault = Fault.NONE,
        fault_after: int = 0,
    ) -> None:
        self.config = config or DutConfig()
        self._rng = random.Random(seed)
        self.fault = Fault(fault)
        self.fault_after = fault_after
        self._applied_c = 25.0
        self._measurements_served = 0

    # --- physical side -----------------------------------------------------

    def apply_temperature(self, t_c: float) -> None:
        """Set the temperature seen by the sensor (called by the stimulus)."""
        self._applied_c = float(t_c)

    def _fault_active(self) -> bool:
        return self.fault is not Fault.NONE and self._measurements_served >= self.fault_after

    def _sensed_temperature(self) -> float | None:
        c = self.config
        if self._fault_active():
            if self.fault is Fault.SENSOR_DISCONNECTED:
                return None
            if self.fault is Fault.SENSOR_OUT_OF_RANGE:
                return c.out_of_range_sensor_c + self._rng.gauss(0.0, c.noise_c)
        sigma = c.noise_c
        if self._fault_active() and self.fault is Fault.EXCESSIVE_NOISE:
            sigma *= c.noise_fault_factor
        return self._applied_c + self._rng.gauss(0.0, sigma)

    def analog_output_v(self) -> float:
        """Analog output voltage, including saturation and burnout."""
        c = self.config
        t = self._sensed_temperature()
        if t is None:
            return c.burnout_v
        sigma = c.noise_v
        if self._fault_active() and self.fault is Fault.EXCESSIVE_NOISE:
            sigma *= c.noise_fault_factor
        v = (t - c.range_min_c) * c.sensitivity_v_per_c * (1.0 + c.gain_error) + c.offset_v
        v += self._rng.gauss(0.0, sigma)
        return min(max(v, c.v_min), c.v_max)

    def status_for(self, t: float | None) -> Status:
        c = self.config
        if t is None:
            return Status.SENSOR_OPEN
        if t < c.range_min_c - c.range_tolerance_c or t > c.range_max_c + c.range_tolerance_c:
            return Status.OUT_OF_RANGE
        return Status.OK

    # --- digital side ------------------------------------------------------

    def handle(self, command: str) -> tuple[str | None, float]:
        """Process one command. Returns (reply or None if no reply, latency in s)."""
        cmd = command.strip().upper()
        latency = self.config.response_time_s

        if cmd == "MEAS:TEMP?":
            active = self._fault_active()
            if active and self.fault is Fault.COMMUNICATION_LOSS:
                self._measurements_served += 1
                return None, float("inf")
            if active and self.fault is Fault.TIMEOUT:
                latency = self.config.timeout_response_s
            t = self._sensed_temperature()   # evaluated before the counter moves on
            self._measurements_served += 1
            status = self.status_for(t)
            value = "NAN" if t is None else f"{t:.3f}"
            return f"{value},{status.value}", latency

        if self._fault_active() and self.fault is Fault.COMMUNICATION_LOSS:
            return None, float("inf")
        if cmd == "*IDN?":
            return self.IDN, latency
        return "ERR,UNKNOWN_COMMAND", latency
