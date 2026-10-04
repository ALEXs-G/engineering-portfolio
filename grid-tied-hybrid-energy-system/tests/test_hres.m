function tests = test_hres
%TEST_HRES Unit and regression tests for the modular HRES simulation.
%   Run from MATLAB:   results = runtests('tests/test_hres.m')
%   All tests use synthetic data; none depends on the original Data_T.mat.
    tests = functiontests(localfunctions);
end

function setupOnce(tc)
    root = fileparts(fileparts(mfilename('fullpath')));
    tc.TestData.root = root;
    addpath(fullfile(root, 'src'), fullfile(root, 'examples'));
    tc.TestData.p = hres_default_params();
    tc.TestData.data = generate_example_data(24 * 60, 1);   % 60 synthetic days
end

% --- Component models ------------------------------------------------------

function testPvZeroIrradianceGivesZeroPower(tc)
    p = tc.TestData.p;
    verifyEqual(tc, pv_model([0 0], [-10 40], p), [0 0]);
end

function testPvAtStcCellTemperature(tc)
    % Choose Tamb so that Tcell = 25 degC at 1000 W/m^2:
    % Tcell = Tamb + 1000/800 * (47.5 - 20) = Tamb + 34.375
    p = tc.TestData.p;
    expected = p.pv.eta_mppt * p.pv.P_ref * p.pv.Ns * p.pv.Np;   % 29 687.5 W
    verifyEqual(tc, pv_model(1000, 25 - 34.375, p), expected, 'AbsTol', 1e-9);
end

function testWindPowerCurveRegions(tc)
    p = tc.TestData.p;
    v = [0 2.0 7.5 13.0 19.9 20.0 25];
    P = wind_model(v, p);
    rated = p.wind.P_rated * p.wind.N;
    verifyEqual(tc, P([1 2 6 7]), [0 0 0 0]);            % below/at cut-in, at/above cut-out
    verifyEqual(tc, P([4 5]), [rated rated]);            % rated region
    verifyTrue(tc, P(3) > 0 && P(3) < rated);            % cubic region
end

% --- EMS and battery -------------------------------------------------------

function testEmsSellsSurplusWhenPriceHigh(tc)
    p = tc.TestData.p;
    E = p.battery.E_max * 0.5;
    [buy, sell, batt] = ems_controller(-1000, 2, 1, E, p);
    verifyEqual(tc, [buy sell batt], [0 1000 0]);
end

function testEmsChargesSurplusWhenPriceLow(tc)
    p = tc.TestData.p;
    E = p.battery.E_max * 0.5;
    [buy, sell, batt] = ems_controller(-1000, 1, 2, E, p);
    verifyEqual(tc, [buy sell batt], [0 0 -1000]);
end

function testEmsBuysWhenBatteryAtMinimum(tc)
    p = tc.TestData.p;
    E = p.battery.E_max * p.battery.SOC_min / 100;
    [buy, sell, batt] = ems_controller(3000, 2, 1, E, p);
    verifyEqual(tc, [buy sell batt], [3000 0 0]);
end

function testBatteryNeverLeavesSocWindow(tc)
    p = tc.TestData.p;
    b = p.battery;
    [E, ~] = battery_model(b.E_max * 0.895, -b.P_max, p);
    verifyLessThanOrEqual(tc, E, b.E_max * b.SOC_max / 100 + 1e-9);
    [E, ~] = battery_model(b.E_max * 0.205, b.P_max, p);
    verifyGreaterThanOrEqual(tc, E, b.E_max * b.SOC_min / 100 - 1e-9);
end

% --- System-level checks ----------------------------------------------------

function testSimulationSatisfiesConstraints(tc)
    p = tc.TestData.p;
    r = simulate_system(tc.TestData.data, p);
    chk = check_results(r, p);   % errors on any violated constraint
    verifyLessThan(tc, chk.bus_residual_max_W, 1e-6);
end

function testEfficiencyAwareLimitRemovesClampEnergy(tc)
    p = tc.TestData.p;
    p.ems.efficiency_aware_discharge_limit = true;
    r = simulate_system(tc.TestData.data, p);
    chk = check_results(r, p);
    verifyEqual(tc, chk.clamp_energy_Wh, 0, 'AbsTol', 1e-6);
end

function testInputValidationRejectsBadData(tc)
    p = tc.TestData.p;
    d = tc.TestData.data;
    bad = d;
    bad.G(5) = NaN;
    verifyError(tc, @() simulate_system(bad, p), 'hres:input:nonFinite');
    bad = d;
    bad.wind = bad.wind(1:end - 1);
    verifyError(tc, @() simulate_system(bad, p), 'hres:input:length');
    bad = d;
    bad.load(1) = -1;
    verifyError(tc, @() simulate_system(bad, p), 'hres:input:negative');
end

% --- Regression against the original script ---------------------------------

function testRefactorMatchesLegacyScript(tc)
    % Runs legacy/Matlab_see_code.m on the same synthetic data and compares
    % every time series. The legacy file is not modified: a temporary copy
    % without its workspace-clearing header (clear all/clc/clearvars/close
    % all) is executed inside a helper function.
    p = tc.TestData.p;
    Data_T = tc.TestData.data; %#ok<NASGU> saved below
    tmp = tempname;
    mkdir(tmp);
    cleanup = onCleanup(@() rmdir(tmp, 's'));
    save(fullfile(tmp, 'Data_T.mat'), 'Data_T');

    src = fileread(fullfile(tc.TestData.root, 'legacy', 'Matlab_see_code.m'));
    src = regexprep(src, '(?m)^\s*(clear all|clc|clearvars|close all)\s*$', '');
    src = [src, sprintf('\nsave(''legacy_out.mat'', ''Ppv'', ''Pwind'', ''Pcompra'', ''Pvenda'', ''Pbatt'', ''SOC'');\n')];
    fid = fopen(fullfile(tmp, 'legacy_run.m'), 'w');
    fwrite(fid, src);
    fclose(fid);

    run_legacy(fullfile(tmp, 'legacy_run.m'));   % run() executes in tmp, writes legacy_out.mat there
    close all;
    legacy = load(fullfile(tmp, 'legacy_out.mat'));

    r = simulate_system(tc.TestData.data, p);
    verifyEqual(tc, r.Ppv, legacy.Ppv, 'AbsTol', 1e-9);
    verifyEqual(tc, r.Pwind, legacy.Pwind, 'AbsTol', 1e-9);
    verifyEqual(tc, r.Pbuy, legacy.Pcompra, 'AbsTol', 1e-9);
    verifyEqual(tc, r.Psell, legacy.Pvenda, 'AbsTol', 1e-9);
    verifyEqual(tc, r.Pbatt, legacy.Pbatt, 'AbsTol', 1e-9);
    verifyEqual(tc, r.SOC, legacy.SOC, 'AbsTol', 1e-9);
end

function run_legacy(script_path) %#ok<INUSD> used inside evalc
    evalc('run(script_path)');   % isolated workspace; suppresses the legacy console output
end
