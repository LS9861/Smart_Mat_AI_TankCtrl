% auto_tune_and_compare.m
% Step 1: AI auto-tunes gains
% Step 2: Compares continuous vs discrete with the tuned gains

%% STEP 1: LOAD PARAMETERS
run('tank_parameters.m');
if ~exist('Ts', 'var')
    Ts = 0.1;  % Sample time for Arduino
end

fprintf('========================================\n');
fprintf('  AUTO-TUNE AND COMPARE\n');
fprintf('========================================\n\n');

%% STEP 2: AI AUTO-TUNING
fprintf('Step 1: AI Auto-Tuning...\n');

try
    api_key = api_key_config();
    
    prompt = sprintf([ ...
        'Water tank: G(s)=%.4f/(s+%.4f), tau=%.0fs. ' ...
        'Recommend PI gains. FORMAT: Kp=1.8, Ki=0.25'], ...
        K_tf, pole_tf, tau);
    
    ai_response = call_deepseek(prompt, api_key);
    
    kp_match = regexp(ai_response, 'Kp[=:\s]*([\d.]+)', 'tokens');
    ki_match = regexp(ai_response, 'Ki[=:\s]*([\d.]+)', 'tokens');
    
    if ~isempty(kp_match)
        Kp = str2double(kp_match{1}{1});
    end
    if ~isempty(ki_match)
        Ki = str2double(ki_match{1}{1});
    end
    
    fprintf('? AI suggests: Kp = %.2f, Ki = %.2f\n\n', Kp, Ki);
    
catch
    fprintf('?? Using fallback gains: Kp=1.8, Ki=0.25\n\n');
    Kp = 1.8;
    Ki = 0.25;
end

%% STEP 3: CONTINUOUS SIMULATION
fprintf('Step 2: Continuous Simulation (ideal)...\n');

n_steps_cont = round(SIM_TIME / dt);
time_cont = (0:n_steps_cont-1)' * dt;
level_cont = zeros(n_steps_cont, 1);
level_cont(1) = 0.5;
integral = 0;
e_prev = setpoint - level_cont(1);

for i = 1:n_steps_cont-1
    error = setpoint - level_cont(i);
    integral = integral + error * dt;
    integral = max(-1.5, min(1.5, integral));
    u = Kp * error + Ki * integral + u_eq;
    u = max(0, min(3, u));
    level_cont(i+1) = level_cont(i) + (K_pump*u - leak_rate*level_cont(i))/A * dt;
    e_prev = error;
end
fprintf('   ? Complete\n');

%% STEP 4: DISCRETE SIMULATION (Arduino)
fprintf('Step 3: Discrete Simulation (Arduino with Ts=%.3fs)...\n', Ts);

n_steps_disc = round(SIM_TIME / Ts);
time_disc = (0:n_steps_disc-1)' * Ts;
level_disc = zeros(n_steps_disc, 1);
level_disc(1) = 0.5;
integral = 0;
e_prev = setpoint - level_disc(1);

for i = 1:n_steps_disc-1
    error = setpoint - level_disc(i);
    integral = integral + error * Ts;
    integral = max(-1.5, min(1.5, integral));
    u = Kp * error + Ki * integral + u_eq;
    u = max(0, min(3, u));
    level_disc(i+1) = level_disc(i) + (K_pump*u - leak_rate*level_disc(i))/A * Ts;
    e_prev = error;
end
fprintf('   ? Complete\n');

%% STEP 5: CALCULATE ERRORS
steady_start_cont = max(1, n_steps_cont - round(30/dt));
steady_error_cont = mean(abs(level_cont(steady_start_cont:end) - setpoint)) * 1000;

steady_start_disc = max(1, n_steps_disc - round(30/Ts));
steady_error_disc = mean(abs(level_disc(steady_start_disc:end) - setpoint)) * 1000;

%% STEP 6: DISPLAY RESULTS
fprintf('\n========================================\n');
fprintf('  RESULTS\n');
fprintf('========================================\n');
fprintf('AI-Tuned Gains: Kp = %.2f, Ki = %.2f\n', Kp, Ki);
fprintf('Continuous Error:   %.2f mm\n', steady_error_cont);
fprintf('Discrete Error:     %.2f mm\n', steady_error_disc);
fprintf('Sample time (Ts):   %.3f s (%.0f ms)\n', Ts, Ts*1000);
fprintf('========================================\n');

%% STEP 7: PLOT
figure('Position', [100, 100, 1000, 800]);

subplot(2,1,1);
plot(time_cont, level_cont, 'b-', 'LineWidth', 1.5);
hold on;
plot(time_disc, level_disc, 'r--', 'LineWidth', 1.5);
plot([0, SIM_TIME], [setpoint, setpoint], 'k--', 'LineWidth', 1.5);
ylabel('Water Level (m)');
title(sprintf('AI-Tuned: Kp=%.2f, Ki=%.2f (Cont vs Disc)', Kp, Ki));
legend('Continuous (Ideal)', sprintf('Discrete (Ts=%.3fs)', Ts), 'Setpoint');
grid on;
ylim([1.4, 1.6]);

subplot(2,1,2);
plot(time_cont, (level_cont - setpoint)*1000, 'b-', 'LineWidth', 1);
hold on;
plot(time_disc, (level_disc - setpoint)*1000, 'r--', 'LineWidth', 1);
plot([0, SIM_TIME], [0, 0], 'k-');
ylabel('Error (mm)');
xlabel('Time (s)');
title(sprintf('Error: Continuous (%.2f mm) vs Discrete (%.2f mm)', steady_error_cont, steady_error_disc));
legend('Continuous', 'Discrete');
grid on;

fprintf('\n? Complete! AI tuned, then compared continuous vs discrete.\n');