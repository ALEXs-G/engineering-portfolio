function check_inputs(data, p)
%CHECK_INPUTS Validate the input data set and parameters; error on failure.

    fields = {'G', 'wind', 'load', 'temp', 'price'};
    for k = 1:numel(fields)
        f = fields{k};
        assert(isfield(data, f) || (istable(data) && any(strcmp(data.Properties.VariableNames, f))), ...
            'hres:input:missingField', 'Input data has no field "%s".', f);
    end

    n = numel(data.G);
    for k = 1:numel(fields)
        x = data.(fields{k});
        assert(isnumeric(x) && isvector(x), 'hres:input:type', '"%s" must be a numeric vector.', fields{k});
        assert(numel(x) == n, 'hres:input:length', ...
            'Array length mismatch: "%s" has %d samples, G has %d.', fields{k}, numel(x), n);
        assert(all(isfinite(x)), 'hres:input:nonFinite', '"%s" contains NaN or Inf.', fields{k});
    end

    assert(all(data.G >= 0), 'hres:input:negative', 'Irradiance G must be >= 0 W/m^2.');
    assert(all(data.wind >= 0), 'hres:input:negative', 'Wind speed must be >= 0 m/s.');
    assert(all(data.load >= 0), 'hres:input:negative', 'Load must be >= 0 W.');
    if any(data.price < 0)
        % Negative wholesale prices occur in real markets; allowed but reported.
        warning('hres:input:negativePrice', '%d samples have a negative price.', sum(data.price < 0));
    end
    assert(all(data.temp > -60 & data.temp < 60), 'hres:input:range', ...
        'Ambient temperature outside -60..60 degC; check units.');

    b = p.battery;
    assert(p.sim.dt_h == 1, 'hres:param:dt', 'The model equations assume a 1 h time step.');
    assert(p.sim.start_index >= 1 && p.sim.start_index <= n, 'hres:param:start', 'start_index out of range.');
    assert(0 <= b.SOC_min && b.SOC_min < b.SOC_max && b.SOC_max <= 100, 'hres:param:soc', ...
        'Require 0 <= SOC_min < SOC_max <= 100.');
    assert(b.SOC_min <= b.SOC_ini && b.SOC_ini <= b.SOC_max, 'hres:param:socIni', ...
        'SOC_ini must lie within [SOC_min, SOC_max].');
    assert(b.E_max > 0 && b.P_max > 0, 'hres:param:battery', 'Battery capacity and power must be > 0.');
    assert(b.eta_charge > 0 && b.eta_charge <= 1 && b.eta_discharge > 0 && b.eta_discharge <= 1, ...
        'hres:param:eta', 'Efficiencies must be in (0, 1].');
end
