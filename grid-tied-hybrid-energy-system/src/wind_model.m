function Pwind = wind_model(v, p)
%WIND_MODEL Wind farm output power [W] from hub-height wind speed [m/s].
%   Cubic interpolation between cut-in and rated speed, rated power up to
%   cut-out, zero otherwise. Same equations as legacy/Matlab_see_code.m.

    w = p.wind;
    P = zeros(size(v));

    ramp = v > w.v_cut_in & v < w.v_rated;
    P(ramp) = w.P_rated * ((v(ramp).^3 - w.v_cut_in^3) / (w.v_rated^3 - w.v_cut_in^3));

    full = v >= w.v_rated & v < w.v_cut_out;
    P(full) = w.P_rated;

    Pwind = P * w.N;
end
