% master_ai_controller.m
% MASTER AI CONTROLLER FOR WATER TANK
% Saves results to Results folder

clear all; close all; clc;

%% LOAD PARAMETERS
run('tank_parameters.m')

%% CREATE RESULTS FOLDER IF IT DOESN'T EXIST
results_folder = '../Results';
if ~exist(results_folder, 'dir')
    mkdir(results_folder);
    fprintf('? Created Results folder: %s\n', results_folder);
end

%% GET TIMESTAMP FOR UNIQUE FILENAMES
timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');

fprintf('========================================\n');
fprintf('  AI MASTER CONTROLLER\n');
fprintf('========================================\n');
fprintf('Plant: G(s) = %.4f / (s + %.4f)\n', K_tf, pole_tf);
fprintf('Time constant: %.0f seconds\n', tau);
fprintf('Target: %.1f meters\n', setpoint);
fprintf('========================================\n\n');

%% LOAD API KEY
try
    api_key = api_key_config();
    fprintf('? API key loaded\n\n');
catch
    error('Create api_key_config.m with your DeepSeek API key');
end

%% ASK AI FOR OPTIMAL GAINS
fprintf('Asking DeepSeek AI for optimal PI gains...\n');

prompt = sprintf([ ...
    'Water tank system.\n' ...
    'Plant: G(s) = %.4f / (s + %.4f)\n' ...
    'Time constant: %.0f seconds (VERY SLOW)\n' ...
    'Setpoint: %.1f meters\n' ...
    'Feedforward voltage: %.2f V\n\n' ...
    'Recommend PI controller gains (Kp and Ki).\n' ...
    'FORMAT EXACTLY: Kp=1.8, Ki=0.25'], ...
    K_tf, pole_tf, tau, setpoint, u_eq);

try
    ai_response = call_deepseek(prompt, api_key);
    fprintf('AI: %s\n', ai_response(1:min(150,end)));
    
    kp_match = regexp(ai_response, 'Kp[=:\s]*([\d.]+)', 'tokens');
    ki_match = regexp(ai_response, 'Ki[=:\s]*([\d.]+)', 'tokens');
    
    if ~isempty(kp_match), Kp = str2double(kp_match{1}{1}); end
    if ~isempty(ki_match), Ki = str2double(ki_match{1}{1}); end
    
    fprintf('\n? AI RECOMMENDS: Kp = %.2f, Ki = %.2f\n', Kp, Ki);
catch
    fprintf('\n?? Using proven fallback gains\n');
    Kp = 1.8; Ki = 0.25;
end

%% UPDATE SIMULINK (optional)
try
    open_system('DiscreteTankCtrl');
    set_param('DiscreteTankCtrl/PID Controller', 'P', num2str(Kp));
    set_param('DiscreteTankCtrl/PID Controller', 'I', num2str(Ki));
    fprintf('? Simulink PID updated\n');
catch
    fprintf('?? Simulink update skipped\n');
end

%% RUN SCRIPT SIMULATION (RELIABLE)
fprintf('\nRunning simulation...\n');

dt = 0.1;
n_steps = round(SIM_TIME / dt);
time = (0:n_steps-1)' * dt;

level = zeros(n_steps, 1);
level(1) = 0.5;
integral = 0;
e_prev = setpoint - level(1);

for i = 1:n_steps-1
    error = setpoint - level(i);
    
    integral = integral + error * dt;
    integral = max(-1.5, min(1.5, integral));
    
    u = Kp * error + Ki * integral + u_eq;
    u = max(0, min(3, u));
    
    level(i+1) = level(i) + (K_pump*u - leak_rate*level(i))/A * dt;
    level(i+1) = max(0, min(2.5, level(i+1)));
    
    e_prev = error;
end

%% CALCULATE PERFORMANCE
error_signal = level - setpoint;
steady_start = max(1, n_steps - round(30/dt));
steady_error = mean(abs(error_signal(steady_start:end))) * 1000;
final_level = level(end);
overshoot = max(0, (max(level) - setpoint) / setpoint * 100);

% Settling time (within 2% = 0.03m)
tolerance = 0.03;
settle_idx = find(abs(error_signal) <= tolerance, 1, 'last');
if ~isempty(settle_idx)
    settling_time = time(settle_idx);
else
    settling_time = SIM_TIME;
end

% Rise time (10% to 90%)
level_10 = level(1) + 0.1 * (setpoint - level(1));
level_90 = level(1) + 0.9 * (setpoint - level(1));
idx_10 = find(level >= level_10, 1, 'first');
idx_90 = find(level >= level_90, 1, 'first');
if ~isempty(idx_10) && ~isempty(idx_90) && idx_90 > idx_10
    rise_time = time(idx_90) - time(idx_10);
else
    rise_time = SIM_TIME;
end

%% DISPLAY RESULTS
fprintf('\n========================================\n');
fprintf('  FINAL RESULTS\n');
fprintf('========================================\n');
fprintf('???????????????????????????????????????????????????\n');
fprintf('?                CONTROLLER GAINS                  ?\n');
fprintf('???????????????????????????????????????????????????\n');
fprintf('?  Kp = %-8.2f  Ki = %-8.2f                  ?\n', Kp, Ki);
fprintf('???????????????????????????????????????????????????\n');
fprintf('?                PERFORMANCE                      ?\n');
fprintf('???????????????????????????????????????????????????\n');
fprintf('?  Final level:     %.3f m                         ?\n', final_level);
fprintf('?  Steady error:    %.2f mm                        ?\n', steady_error);
fprintf('?  Overshoot:       %.1f %%                         ?\n', overshoot);
fprintf('?  Settling time:   %.1f s                         ?\n', settling_time);
fprintf('?  Rise time:       %.1f s                         ?\n', rise_time);
fprintf('???????????????????????????????????????????????????\n');

%% SAVE RESULTS TO FILE (with timestamp)
% Save data to Results folder
results_file = fullfile(results_folder, sprintf('controller_results_%s.mat', timestamp));
save(results_file, 'Kp', 'Ki', 'steady_error', 'overshoot', 'settling_time', 'rise_time', ...
     'final_level', 'time', 'level', 'SIM_TIME', 'setpoint');

fprintf('\n? Results saved to: %s\n', results_file);

% Also save latest results without timestamp (overwrites)
latest_file = fullfile(results_folder, 'controller_results_latest.mat');
save(latest_file, 'Kp', 'Ki', 'steady_error', 'overshoot', 'settling_time', 'rise_time', ...
     'final_level', 'time', 'level', 'SIM_TIME', 'setpoint');
fprintf('? Latest results saved to: %s\n', latest_file);

%% SAVE RESULTS AS TEXT FILE (for easy viewing)
text_file = fullfile(results_folder, sprintf('controller_results_%s.txt', timestamp));
fid = fopen(text_file, 'w');
fprintf(fid, '========================================\n');
fprintf(fid, '  AI CONTROLLER RESULTS\n');
fprintf(fid, '========================================\n');
fprintf(fid, 'Date: %s\n\n', datetime('now'));
fprintf(fid, 'PLANT PARAMETERS:\n');
fprintf(fid, '  Transfer function: G(s) = %.4f / (s + %.4f)\n', K_tf, pole_tf);
fprintf(fid, '  Time constant: %.0f seconds\n', tau);
fprintf(fid, '  Setpoint: %.1f m\n', setpoint);
fprintf(fid, '  Feedforward: %.2f V\n\n', u_eq);
fprintf(fid, 'CONTROLLER GAINS:\n');
fprintf(fid, '  Kp = %.2f\n', Kp);
fprintf(fid, '  Ki = %.2f\n\n', Ki);
fprintf(fid, 'PERFORMANCE METRICS:\n');
fprintf(fid, '  Final level: %.3f m\n', final_level);
fprintf(fid, '  Steady-state error: %.2f mm\n', steady_error);
fprintf(fid, '  Overshoot: %.1f %%\n', overshoot);
fprintf(fid, '  Settling time (2%%): %.1f seconds\n', settling_time);
fprintf(fid, '  Rise time: %.1f seconds\n', rise_time);
fclose(fid);
fprintf('? Text results saved to: %s\n', text_file);

%% PLOT AND SAVE FIGURE
figure('Position', [100, 100, 1000, 800]);

subplot(2,1,1);
plot(time, level, 'b-', 'LineWidth', 1.5);
hold on;
plot([0, SIM_TIME], [setpoint, setpoint], 'r--', 'LineWidth', 1.5);
ylabel('Water Level (m)');
title(sprintf('AI-Tuned PI Controller: Kp=%.2f, Ki=%.2f (Error: %.2f mm)', Kp, Ki, steady_error));
legend('Actual Level', sprintf('Setpoint (%.1fm)', setpoint), 'Location', 'best');
grid on;
ylim([1.4, 1.6]);

subplot(2,1,2);
error_plot = (level - setpoint) * 1000;
plot(time, error_plot, 'm-', 'LineWidth', 1);
hold on;
plot([0, SIM_TIME], [0, 0], 'k-', 'LineWidth', 1.5);
plot([0, SIM_TIME], [5, 5], 'r--', 'LineWidth', 1);
plot([0, SIM_TIME], [-5, -5], 'r--', 'LineWidth', 1);
ylabel('Error (mm)');
xlabel('Time (s)');
title(sprintf('Error History: Final error = %.2f mm', steady_error));
grid on;
ylim([-10, 20]);

% Save figure
fig_file = fullfile(results_folder, sprintf('controller_plot_%s.png', timestamp));
saveas(gcf, fig_file);
fprintf('? Plot saved to: %s\n', fig_file);

% Also save as .fig for MATLAB
fig_file_mat = fullfile(results_folder, sprintf('controller_plot_%s.fig', timestamp));
saveas(gcf, fig_file_mat);
fprintf('? MATLAB figure saved to: %s\n', fig_file_mat);

%% SUMMARY
fprintf('\n========================================\n');
fprintf('  RESULTS SAVED TO: %s\n', results_folder);
fprintf('========================================\n');
fprintf('  Files saved:\n');
fprintf('  ??? %s\n', sprintf('controller_results_%s.mat', timestamp));
fprintf('  ??? %s\n', 'controller_results_latest.mat');
fprintf('  ??? %s\n', sprintf('controller_results_%s.txt', timestamp));
fprintf('  ??? %s\n', sprintf('controller_plot_%s.png', timestamp));
fprintf('  ??? %s\n', sprintf('controller_plot_%s.fig', timestamp));
fprintf('========================================\n');

fprintf('\n? AI MASTER CONTROLLER READY!\n');