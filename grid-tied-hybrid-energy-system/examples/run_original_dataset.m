%RUN_ORIGINAL_DATASET Run the modular simulation on the original Data_T.mat.
%   Requires data/Data_T.mat, which is NOT included in this repository
%   (see data/README.md). With that file, the indicators should match the
%   report (Table 5.1) because the default parameters reproduce the legacy
%   script. This has not been verified in this repository.

here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'src'));
data_file = fullfile(here, '..', 'data', 'Data_T.mat');

if ~exist(data_file, 'file')
    error('hres:data:missing', ['Original data set not found: %s\n', ...
        'It is not distributed with this repository. See data/README.md, ', ...
        'or use examples/run_example.m with synthetic data.'], data_file);
end

S = load(data_file, 'Data_T');
p = hres_default_params();
r = simulate_system(S.Data_T, p);
chk = check_results(r, p);
k = summarize_results(r, p);
print_summary(k, 'Annual simulation results (original data set)');
fprintf('Energy added by SOC clamp: %.1f Wh\n', chk.clamp_energy_Wh);
plot_results(r, p, 1);
