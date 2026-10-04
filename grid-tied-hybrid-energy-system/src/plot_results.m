function plot_results(r, p, week)
%PLOT_RESULTS Annual and weekly power-flow and SOC plots (MATLAB R2018b+).
%   Same figures as the legacy script, with English labels.
    if nargin < 3
        week = 1;
    end

    days = r.t / 24;
    dis = max(r.Pbatt, 0);
    chg = -min(r.Pbatt, 0);
    names = {'PV', 'Wind', 'Grid import', 'Grid export', 'Battery discharge', 'Battery charge', 'Load'};

    i0 = (week - 1) * 24 * 7 + 1;
    i1 = min(i0 + 24 * 7 - 1, numel(r.t));
    w = i0:i1;

    figure('Name', 'Annual power flows');
    area(days, [r.Ppv', r.Pwind', r.Pbuy', r.Psell', dis', chg'] / 1000);
    hold on;
    plot(days, r.load / 1000, 'k', 'LineWidth', 1.2);
    hold off;
    legend(names, 'Location', 'best');
    xlabel('Time [days]');
    ylabel('Power [kW]');
    title('PV + wind + battery + grid, 1 year');
    grid on;

    figure('Name', 'Annual SOC');
    plot(days, r.SOC, 'LineWidth', 1.2);
    yline(p.battery.SOC_min, '--', 'SOC min');
    yline(p.battery.SOC_max, '--', 'SOC max');
    ylim([0 100]);
    xlabel('Time [days]');
    ylabel('SOC [%]');
    title('Battery state of charge, 1 year');
    grid on;

    figure('Name', sprintf('Week %d power flows', week));
    area(1:numel(w), [r.Ppv(w)', r.Pwind(w)', r.Pbuy(w)', r.Psell(w)', dis(w)', chg(w)'] / 1000);
    hold on;
    plot(1:numel(w), r.load(w) / 1000, 'k', 'LineWidth', 1.5);
    hold off;
    legend(names, 'Location', 'best');
    xlabel('Time [h]');
    ylabel('Power [kW]');
    title(sprintf('PV + wind + battery + grid, week %d', week));
    grid on;

    figure('Name', sprintf('Week %d SOC', week));
    plot(1:numel(w), r.SOC(w), 'LineWidth', 1.5);
    yline(p.battery.SOC_min, '--', 'SOC min');
    yline(p.battery.SOC_max, '--', 'SOC max');
    ylim([0 100]);
    xlabel('Time [h]');
    ylabel('SOC [%]');
    title(sprintf('Battery state of charge, week %d', week));
    grid on;
end
