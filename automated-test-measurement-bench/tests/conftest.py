"""Shared fixtures: every test gets a fresh, seeded, simulated bench."""

from pathlib import Path

import pytest

from acquisition import build_simulated_bench, load_config
from dut import Fault

CONFIG_PATH = Path(__file__).resolve().parent.parent / "configs" / "simulation.json"


@pytest.fixture
def config() -> dict:
    return load_config(CONFIG_PATH)


@pytest.fixture
def make_bench(config):
    def _make(fault: Fault = Fault.NONE, fault_after: int = 0, seed_offset: int = 0):
        return build_simulated_bench(config, fault, fault_after, seed_offset)

    return _make
