%RUN_EXAMPLE Run the modular simulation on SYNTHETIC data.
%   Demonstrates that the code executes end to end without the original
%   (unpublished) Data_T.mat. The printed numbers come from synthetic
%   inputs and are NOT the results reported in HRSsimulationREPORT.pdf.

here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'src'));
addpath(here);

p = hres_default_params();
Data_T = generate_example_data(24 * 365, 42);

r = simulate_system(Data_T, p);
chk = check_results(r, p);
k = summarize_results(r, p);

print_summary(k, 'Example run on SYNTHETIC data (not report results)');
fprintf('Bus balance max residual: %.3g W\n', chk.bus_residual_max_W);
fprintf('Energy added by SOC clamp: %.1f Wh\n', chk.clamp_energy_Wh);

if usejava('desktop')
    plot_results(r, p, 1);
end
