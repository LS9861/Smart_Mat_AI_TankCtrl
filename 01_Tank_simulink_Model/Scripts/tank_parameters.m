% tank_parameters.m
% MASTER PARAMETERS FILE - Single source of truth for everything!
% Run this BEFORE opening Simulink or running any script
 clear; clc;
%% TANK PHYSICAL PARAMETERS
A = 5.0;           % Tank cross-sectional area (m²)
K_pump = 0.05;     % Pump gain (m³/s per volt)
leak_rate = 0.01;  % Leak rate (1/s)

%% 
Ts = 0.1;
rampslope = 0.015;
initout = 0.5;

%% CONTROL PARAMETERS
setpoint = 1.5;    % Target water level (m)
SIM_TIME = 2000;    % Simulation time (seconds)
dt = 0.1;          % Time step for script simulation (seconds)

%% DERIVED PARAMETERS (Calculated automatically - DO NOT CHANGE)
K_tf = K_pump / A;           % Transfer function numerator = 0.01
pole_tf = leak_rate / A;      % Transfer function pole = 0.002
tau = 1 / pole_tf;            % Time constant = 500 seconds
u_eq = (leak_rate * setpoint) / K_pump;  % Feedforward voltage = 0.30V

%% PID GAINS (Will be updated by AI)
Kp = 1.5;    % Proportional gain (initial)
Ki = 0.15;   % Integral gain (initial)
Kd = 0;      % Derivative gain (not used for PI)

%% TRANSFER FUNCTION FOR SIMULINK
num = K_tf;          % Numerator: [0.01]
den = [1, pole_tf];  % Denominator: [1, 0.002]

%% DISPLAY SUMMARY
fprintf('\n========================================\n');
fprintf('  TANK PARAMETERS LOADED\n');
fprintf('========================================\n');
fprintf('Physical Parameters:\n');
fprintf('  Area (A):        %.2f m²\n', A);
fprintf('  Pump gain:       %.2f m³/s per V\n', K_pump);
fprintf('  Leak rate:       %.3f 1/s\n', leak_rate);
fprintf('  Setpoint:        %.1f m\n', setpoint);
fprintf('  Sim time:        %.0f s\n', SIM_TIME);
fprintf('\nDerived Parameters:\n');
fprintf('  Transfer function: G(s) = %.4f / (s + %.4f)\n', K_tf, pole_tf);
fprintf('  Time constant:     %.0f s\n', tau);
fprintf('  Feedforward:       %.2f V\n', u_eq);
fprintf('\nCurrent PID Gains:\n');
fprintf('  Kp = %.2f, Ki = %.2f, Kd = %.2f\n', Kp, Ki, Kd);
fprintf('========================================\n\n');

%% SAVE TO BASE WORKSPACE FOR SIMULINK
assignin('base', 'A', A);
assignin('base', 'K_pump', K_pump);
assignin('base', 'leak_rate', leak_rate);
assignin('base', 'setpoint', setpoint);
assignin('base', 'SIM_TIME', SIM_TIME);
assignin('base', 'dt', dt);
assignin('base', 'K_tf', K_tf);
assignin('base', 'pole_tf', pole_tf);
assignin('base', 'tau', tau);
assignin('base', 'u_eq', u_eq);
assignin('base', 'Kp', Kp);
assignin('base', 'Ki', Ki);
assignin('base', 'Kd', Kd);
assignin('base', 'num', num);
assignin('base', 'den', den);

fprintf('? All parameters saved to base workspace (Simulink can see them)\n');