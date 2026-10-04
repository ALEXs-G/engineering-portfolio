function report = check_results(r, p)
%CHECK_RESULTS Verify physical and logical constraints of a simulation run.
%   Errors on a hard constraint violation. Returns a struct with the energy
%   accounting so the battery clamp artefact can be quantified.

    b = p.battery;
    tol = 1e-6;

    % SOC window
    assert(all(r.SOC >= b.SOC_min - tol & r.SOC <= b.SOC_max + tol), 'hres:check:soc', ...
        'SOC outside [%g, %g] %%.', b.SOC_min, b.SOC_max);

    % Power limits and signs
    assert(all(abs(r.Pbatt) <= b.P_max + tol), 'hres:check:pbatt', 'Battery power exceeds P_max.');
    assert(all(r.Pbuy >= -tol) && all(r.Psell >= -tol), 'hres:check:grid', 'Negative grid import/export.');
    assert(all(r.Ppv >= 0) && all(r.Pwind >= 0), 'hres:check:gen', 'Negative generation.');
    assert(~any(r.Pbuy > tol & r.Psell > tol), 'hres:check:buySell', 'Simultaneous grid import and export.');
    assert(~any(r.Pbatt < -tol & r.Pbuy > tol), 'hres:check:gridCharge', 'Battery charged from the grid.');

    % AC bus power balance: load = PV + wind + import - export + battery
    bus = r.Ppv + r.Pwind + r.Pbuy - r.Psell + r.Pbatt - r.load;
    assert(max(abs(bus)) < 1e-6 * max(1, max(r.load)), 'hres:check:bus', ...
        'AC bus power balance violated (max residual %g W).', max(abs(bus)));

    % Battery internal energy accounting (1 h step: W == Wh per step)
    E_in = sum(-r.Pbatt(r.Pbatt < 0)) * b.eta_charge;
    E_out = sum(r.Pbatt(r.Pbatt > 0)) / b.eta_discharge;
    report.bus_residual_max_W = max(abs(bus));
    report.battery_stored_Wh = E_in;
    report.battery_withdrawn_Wh = E_out;
    report.battery_delta_Wh = r.E_final - r.E_initial;
    report.clamp_energy_Wh = sum(r.E_clamp);
    report.accounting_error_Wh = report.battery_delta_Wh - (E_in - E_out) - report.clamp_energy_Wh;

    assert(abs(report.accounting_error_Wh) < 1e-3, 'hres:check:accounting', ...
        'Battery energy accounting does not close (%g Wh).', report.accounting_error_Wh);

    if abs(report.clamp_energy_Wh) > 1e-6
        warning('hres:check:clamp', ...
            ['SOC clamp added %.1f Wh not supplied by any source. Set ', ...
             'p.ems.efficiency_aware_discharge_limit = true to remove it.'], report.clamp_energy_Wh);
    end
end
