function [Pbuy, Psell, Pbatt] = ems_controller(P_net, price, price_avg, Ebat, p)
%EMS_CONTROLLER Rule-based energy management decision for one time step.
%   P_net     load - renewable generation [W] (>0 deficit, <0 surplus)
%   price     current energy price (any unit; only compared with price_avg)
%   price_avg moving-average price (same unit)
%   Ebat      battery energy at the start of the step [Wh]
%
%   Returns grid import Pbuy >= 0, grid export Psell >= 0 and battery power
%   Pbatt at the AC bus (>0 discharge, <0 charge), all in W.
%   With a 1 h step, the energy limits [Wh] are compared directly with power [W].
%   Rules are those of legacy/Matlab_see_code.m:
%     surplus: sell if price > average or SOC >= SOC_max, else charge (rest sold)
%     deficit: buy  if price < average or SOC <= SOC_min, else discharge (rest bought)

    b = p.battery;
    Pbuy = 0;
    Psell = 0;
    Pbatt = 0;
    SOC_now = 100 * Ebat / b.E_max;

    if P_net < 0
        surplus = abs(P_net);
        E_free = b.E_max * b.SOC_max / 100 - Ebat;
        if price > price_avg || SOC_now >= b.SOC_max
            Psell = surplus;
        else
            P_charge = min([surplus, b.P_max, E_free]);
            Pbatt = -P_charge;
            Psell = surplus - P_charge;
        end
    else
        deficit = P_net;
        E_avail = Ebat - b.E_max * b.SOC_min / 100;
        if price < price_avg || SOC_now <= b.SOC_min
            Pbuy = deficit;
        else
            E_limit = E_avail;
            if p.ems.efficiency_aware_discharge_limit
                E_limit = E_avail * b.eta_discharge;
            end
            P_discharge = min([deficit, b.P_max, E_limit]);
            Pbatt = P_discharge;
            Pbuy = deficit - P_discharge;
        end
    end
end
