% 05_linearize_tf.m
% LINEARIZATION OF YOUR TANK TRANSFER FUNCTION
% (Spoiler: It's already linear, but let's analyze it!)

clear all; close all; clc;

%% STEP 1: DEFINE YOUR TANK (Same as before)
% =========================================================================

% Physical parameters
A = 5.0;          % Tank area (m²)
K_pump = 0.05;    % Pump gain (m³/s per volt)
leak_rate = 0.01; % Leak rate (1/s)

% Transfer function parameters
K_tf = K_pump / A;      % = 0.01
pole_tf = leak_rate / A; % = 0.002

% Create transfer function
num = K_tf;
den = [1, pole_tf];
G_continuous = tf(num, den);

fprintf('========================================\n');
fprintf('  YOUR TANK TRANSFER FUNCTION\n');
fprintf('========================================\n\n');
fprintf('G(s) = %.4f / (s + %.4f)\n\n', K_tf, pole_tf);

%% STEP 2: LINEARIZATION ANALYSIS
% =========================================================================

fprintf('????????????????????????????????????????????????????????????\n');
fprintf('  LINEARIZATION ANALYSIS\n');
fprintf('????????????????????????????????????????????????????????????\n\n');

% Check if system is linear
fprintf('? This transfer function is LINEAR because:\n');
fprintf('  1. It has constant coefficients (A, K_pump, leak_rate are fixed)\n');
fprintf('  2. No nonlinear terms (no s², no multiplication of states)\n');
fprintf('  3. Follows superposition: G(s)(u1+u2) = G(s)u1 + G(s)u2\n\n');

%% STEP 3: LINEARIZATION AT OPERATING POINT
% =========================================================================

% Operating point: setpoint = 1.5m
setpoint = 1.5;
u_eq = (leak_rate * setpoint) / K_pump;  % = 0.3V

fprintf('Linearization at operating point:\n');
fprintf('  Operating point: level = %.1f m\n', setpoint);
fprintf('  Input voltage at operating point: u_eq = %.2f V\n', u_eq);
fprintf('\n  Small-signal model around operating point:\n');
fprintf('  ?G(s) = G(s)  (SAME! Because system is linear)\n');
fprintf('  ?Level(s) = G(s) × ?Voltage(s)\n\n');

%% STEP 4: TIME CONSTANT ANALYSIS
% =========================================================================

tau = 1 / pole_tf;  % = 500 seconds

fprintf('????????????????????????????????????????????????????????????\n');
fprintf('  TIME DOMAIN CHARACTERISTICS\n');
fprintf('????????????????????????????????????????????????????????????\n\n');

fprintf('Time constant (?) = 1/pole = 1/%.4f = %.0f seconds\n', pole_tf, tau);
fprintf('\nMeaning:\n');
fprintf('  - After %.0f seconds, level reaches 63.2%% of final value\n', tau);
fprintf('  - After %.0f seconds (5?), level reaches 99.3%% of final value\n', 5*tau);
fprintf('  - This is a SLOW system!\n\n');

%% STEP 5: STEP RESPONSE FOR DIFFERENT INPUTS
% =========================================================================

figure('Position', [50, 50, 1000, 700]);

% Subplot 1: Step responses
subplot(2,2,1);
voltages = [0.1, 0.2, 0.3, 0.4, 0.5];
colors = {'b', 'c', 'g', 'm', 'r'};
hold on;

for i = 1:length(voltages)
    [y, t] = step(voltages(i) * G_continuous);
    plot(t, y, colors{i}, 'LineWidth', 1.5);
    fprintf('Input %.1f V ? Steady-state: %.2f m\n', voltages(i), y(end));
end

xlabel('Time (seconds)');
ylabel('Water Level (m)');
title('Step Response for Different Input Voltages');
legend({'0.1V', '0.2V', '0.3V', '0.4V', '0.5V'}, 'Location', 'best');
grid on;

% Subplot 2: Linear relationship check
subplot(2,2,2);
steady_states = [];
for i = 1:length(voltages)
    [y, ~] = step(voltages(i) * G_continuous);
    steady_states(i) = y(end);
end
plot(voltages, steady_states, 'bo-', 'LineWidth', 2, 'MarkerSize', 8);
xlabel('Input Voltage (V)');
ylabel('Steady-State Level (m)');
title('Linearity Check: Input vs Output');
grid on;
hold on;
% Ideal line
v_line = [0, 0.6];
level_line = v_line * (K_tf / pole_tf);
plot(v_line, level_line, 'r--', 'LineWidth', 1);
legend('Actual', 'Ideal (gain=5)', 'Location', 'best');

% Subplot 3: Pole-zero map
subplot(2,2,3);
pzmap(G_continuous);
title('Pole-Zero Map (Single pole at s = -0.002)');
grid on;

% Subplot 4: Bode plot
subplot(2,2,4);
bode(G_continuous);
title('Bode Plot - Frequency Response');
grid on;

sgtitle('Tank Transfer Function Analysis (Continuous System)');

%% STEP 6: COMPARE WITH DISCRETE (Preview for Arduino)
% =========================================================================

fprintf('\n????????????????????????????????????????????????????????????\n');
fprintf('  PREVIEW: DISCRETE VERSION (for Arduino later)\n');
fprintf('????????????????????????????????????????????????????????????\n\n');

% Sample time (typical for Arduino control)
Ts = 0.1;  % 100ms sampling

% Convert continuous to discrete
G_discrete = c2d(G_continuous, Ts, 'zoh');

fprintf('Continuous: G(s) = %.4f / (s + %.4f)\n', K_tf, pole_tf);
fprintf('Discrete (Ts=%.1fs): ', Ts);
G_discrete;

fprintf('\nComparison:\n');
fprintf('  - Continuous: Natural for analysis\n');
fprintf('  - Discrete:   For Arduino implementation\n');
fprintf('  - The difference is small because Ts=0.1s << ?=%.0fs\n', tau);

%% STEP 7: SAVE LINEARIZED MODEL
% =========================================================================

save('tank_linearized.mat', 'G_continuous', 'G_discrete', 'K_tf', 'pole_tf', 'tau');

fprintf('\n? Linearized model saved to "tank_linearized.mat',"\n");
fprintf('\n========================================\n');
fprintf('  SUMMARY\n');
fprintf('========================================\n');
fprintf('? Your TF is ALREADY linear\n');
fprintf('? No extra linearization needed for AI tuning\n');
fprintf('? Use CONTINUOUS for analysis/Simulink\n');
fprintf('? Use DISCRETE later for Arduino\n');
fprintf('========================================\n');