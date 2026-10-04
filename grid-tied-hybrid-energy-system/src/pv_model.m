function Ppv = pv_model(G, Tamb, p)
%PV_MODEL PV array output power [W] from irradiance and ambient temperature.
%   Ppv = PV_MODEL(G, Tamb, p) with G [W/m^2], Tamb [degC] (same size).
%   Cell temperature uses the NOCT model; power is derated linearly with
%   cell temperature, multiplied by the MPPT efficiency and clipped at 0.
%   Same equations as legacy/Matlab_see_code.m, vectorized.

    pv = p.pv;
    Tcell = Tamb + (G ./ pv.G_noct) .* (pv.NOCT - pv.T_noct_ref);
    Pmodule = pv.eta_mppt .* (pv.P_ref .* (G ./ pv.G_stc) .* (1 + pv.alpha_T .* (Tcell - pv.T_stc)));
    Pmodule = max(Pmodule, 0);
    Ppv = Pmodule * pv.Ns * pv.Np;
end
