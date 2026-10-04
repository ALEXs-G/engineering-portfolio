function r = simulate_system(data, p)
%SIMULATE_SYSTEM Hourly simulation of the grid-tied PV + wind + battery system.
%   r = SIMULATE_SYSTEM(data, p)
%   data: struct with equal-length vectors (see data/README.md)
%         G [W/m^2], wind [m/s], load [W], temp [degC], price [source unit]
%   p:    parameters from HRES_DEFAULT_PARAMS
%   r:    struct of 1xN time series (W, %, Wh) and metadata.
%
%   Reproduces the control flow of legacy/Matlab_see_code.m. The price is
%   divided by 1000 as in the original (EUR/MWh -> EUR/kWh if the source is
%   in EUR/MWh; the EMS only compares prices, so the scale does not affect
%   the dispatch).

    check_inputs(data, p);

    i0 = p.sim.start_index;
    i1 = min(i0 + p.sim.n_hours - 1, numel(data.G));
    idx = i0:i1;
    N = numel(idx);

    r.t = idx;
    r.G = row(data.G(idx));
    r.wind = row(data.wind(idx));
    r.load = row(data.load(idx));
    r.temp = row(data.temp(idx));
    r.price = row(data.price(idx)) / 1000;

    r.Ppv = pv_model(r.G, r.temp, p);
    r.Pwind = wind_model(r.wind, p);
    r.P_net = r.load - r.Ppv - r.Pwind;

    r.Pbuy = zeros(1, N);
    r.Psell = zeros(1, N);
    r.Pbatt = zeros(1, N);
    r.SOC = zeros(1, N);
    r.E_clamp = zeros(1, N);

    b = p.battery;
    Ebat = b.E_max * b.SOC_ini / 100;
    r.E_initial = Ebat;
    window = p.ems.price_window_h;
    price_avg = NaN;

    for h = 1:N
        % Moving-average price (same window definition as the original script)
        if h > window
            price_avg = mean(r.price(h - window:h));
        else
            price_avg = mean(r.price(1:h));
        end

        [r.Pbuy(h), r.Psell(h), r.Pbatt(h)] = ems_controller(r.P_net(h), r.price(h), price_avg, Ebat, p);
        [Ebat, r.E_clamp(h)] = battery_model(Ebat, r.Pbatt(h), p);
        r.SOC(h) = 100 * Ebat / b.E_max;
    end

    r.E_final = Ebat;
    r.price_avg_last = price_avg;
end

function v = row(v)
    v = reshape(v, 1, []);
end
