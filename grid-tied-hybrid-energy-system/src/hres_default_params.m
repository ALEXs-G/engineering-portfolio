function p = hres_default_params()
%HRES_DEFAULT_PARAMS Parameters of the grid-tied PV + wind + battery system.
%   Values are identical to legacy/Matlab_see_code.m (the version used for
%   the report). Units: W, Wh, degC, W/m^2, m/s, %, hourly time step.

    % --- Photovoltaic: Sharp ND-R250A5, 5 series x 25 parallel ----------
    p.pv.P_ref = 250;           % module rated power at STC [W]
    p.pv.G_stc = 1000;          % STC irradiance [W/m^2]
    p.pv.T_stc = 25;            % STC cell temperature [degC]
    p.pv.alpha_T = -0.0029;     % temperature coefficient applied to power [1/degC] (see README)
    p.pv.T_noct_ref = 20;       % ambient temperature at NOCT conditions [degC]
    p.pv.NOCT = 47.5;           % nominal operating cell temperature [degC]
    p.pv.G_noct = 800;          % irradiance at NOCT conditions [W/m^2]
    p.pv.Ns = 5;                % modules in series
    p.pv.Np = 25;               % strings in parallel
    p.pv.eta_mppt = 0.95;       % MPPT efficiency [-]

    % --- Wind: 4 x Bergey BWC XL.1 --------------------------------------
    p.wind.P_rated = 1.2e3;     % rated power per turbine [W]
    p.wind.v_cut_in = 2.0;      % [m/s]
    p.wind.v_rated = 13.0;      % [m/s]
    p.wind.v_cut_out = 20.0;    % [m/s]
    p.wind.N = 4;               % number of turbines

    % --- Battery: BYD Battery-Box Commercial C130 -----------------------
    p.battery.E_max = 131e3;        % nominal energy capacity [Wh]
    p.battery.P_max = 88e3;         % max charge/discharge power [W]
    p.battery.SOC_ini = 50;         % initial state of charge [%]
    p.battery.SOC_min = 20;         % lower operating limit [%]
    p.battery.SOC_max = 90;         % upper operating limit [%]
    p.battery.eta_charge = 0.95;    % charge efficiency [-]
    p.battery.eta_discharge = 0.95; % discharge efficiency [-]

    % --- Energy management ----------------------------------------------
    p.ems.price_window_h = 24 * 5;  % moving-average window for the price [h]
    % false: reproduce the original (report) behaviour, where the discharge
    %        limit ignores discharge efficiency and the SOC clamp then adds
    %        back the missing energy (see README, "Known model issues").
    % true:  limit discharge power to E_available * eta_discharge.
    p.ems.efficiency_aware_discharge_limit = false;

    % --- Simulation -----------------------------------------------------
    p.sim.start_index = 1;      % first sample of the data set used
    p.sim.n_hours = 24 * 365;   % simulated horizon [h]
    p.sim.dt_h = 1;             % time step [h]; model equations assume 1 h
end
