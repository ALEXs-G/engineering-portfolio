function k = summarize_results(r, p)
%SUMMARIZE_RESULTS Annual indicators, as printed by the legacy script.
%   Energies in kWh (1 h step: sum of W / 1000).

    Ptotal = r.Ppv + r.Pwind;
    [~, idx_max] = max(Ptotal);
    [~, idx_price_max] = max(r.price);

    k.pv_installed_kW = p.pv.P_ref * p.pv.Ns * p.pv.Np / 1000;
    k.wind_installed_kW = p.wind.P_rated * p.wind.N / 1000;
    k.renewable_installed_kW = k.pv_installed_kW + k.wind_installed_kW;
    k.day_max_production = floor((r.t(idx_max) - 1) / 24) + 1;
    k.energy_generated_kWh = sum(Ptotal) / 1000;
    k.energy_load_kWh = sum(r.load) / 1000;
    k.energy_bought_kWh = sum(r.Pbuy) / 1000;
    k.energy_sold_kWh = sum(r.Psell) / 1000;
    k.energy_batt_charge_kWh = sum(abs(r.Pbatt(r.Pbatt < 0))) / 1000;
    k.energy_batt_discharge_kWh = sum(r.Pbatt(r.Pbatt > 0)) / 1000;
    k.energy_balance_kWh = k.energy_generated_kWh - k.energy_load_kWh;
    k.hour_price_max = r.t(idx_price_max);
    k.hours_battery_used = numel(find(r.Pbatt ~= 0));
    k.mean_generation_W = mean(Ptotal);
    k.SOC_final = r.SOC(end);
    k.price_avg_last = r.price_avg_last;
    k.battery_usable_kWh = p.battery.E_max * (p.battery.SOC_max - p.battery.SOC_min) / 100 / 1000;
end
