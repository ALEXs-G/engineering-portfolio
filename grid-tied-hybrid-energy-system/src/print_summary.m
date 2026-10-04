function print_summary(k, label)
%PRINT_SUMMARY Print the indicators returned by SUMMARIZE_RESULTS.
    if nargin < 2
        label = 'Annual simulation results';
    end
    fprintf('============================================================\n');
    fprintf('%s\n', upper(label));
    fprintf('============================================================\n');
    fprintf('PV installed:                 %10.2f kW\n', k.pv_installed_kW);
    fprintf('Wind installed:               %10.2f kW\n', k.wind_installed_kW);
    fprintf('Renewable installed:          %10.2f kW\n', k.renewable_installed_kW);
    fprintf('Day of max production:        %10d\n', k.day_max_production);
    fprintf('Energy generated:             %10.1f kWh\n', k.energy_generated_kWh);
    fprintf('Energy consumed by load:      %10.1f kWh\n', k.energy_load_kWh);
    fprintf('Energy bought from grid:      %10.1f kWh\n', k.energy_bought_kWh);
    fprintf('Energy sold to grid:          %10.1f kWh\n', k.energy_sold_kWh);
    fprintf('Battery charge energy (AC):   %10.1f kWh\n', k.energy_batt_charge_kWh);
    fprintf('Battery discharge energy (AC):%10.1f kWh\n', k.energy_batt_discharge_kWh);
    fprintf('Generation - load:            %10.1f kWh\n', k.energy_balance_kWh);
    fprintf('Hour of max price:            %10d\n', k.hour_price_max);
    fprintf('Hours with battery use:       %10d\n', k.hours_battery_used);
    fprintf('Mean generation:              %10.1f W\n', k.mean_generation_W);
    fprintf('Final SOC:                    %10.2f %%\n', k.SOC_final);
    fprintf('============================================================\n');
end
