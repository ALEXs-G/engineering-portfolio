function [Ebat, E_clamp] = battery_model(Ebat, Pbatt, p)
%BATTERY_MODEL Update stored battery energy for one 1 h step.
%   Pbatt is the AC-side battery power [W] (>0 discharge, <0 charge).
%   Charging stores Pbatt*eta_charge; discharging removes Pbatt/eta_discharge.
%   The result is clamped to [SOC_min, SOC_max], as in the legacy script.
%   E_clamp [Wh] is the energy added (+) or removed (-) by that clamp. A
%   nonzero value is not physical: it means the EMS dispatched more energy
%   than the operating window allowed.

    b = p.battery;
    if Pbatt < 0
        Ebat = Ebat + (-Pbatt) * b.eta_charge;
    elseif Pbatt > 0
        Ebat = Ebat - Pbatt / b.eta_discharge;
    end

    E_unclamped = Ebat;
    Ebat = min(max(Ebat, b.E_max * b.SOC_min / 100), b.E_max * b.SOC_max / 100);
    E_clamp = Ebat - E_unclamped;
end
