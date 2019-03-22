%% LDC Model (Newtonian)
% Tyson Cross       1239448
% James Goodhead    1387118

clc; clear all;

% System Parameters
m = 0.1;                                            % kg
B = 0.2;                                            % Telsa
l = 1;                                              % m
R = 5;                                              % Ohms
Vs = [-20:0.1:20]';                                 % volts (input range)
f = 0.01;                                           % friction coefficient

% Modelling
syms s t
num = 1;                                            % numerator of TF
s1 = l.*B + f.*R./(l.*B);                           % s term of 2nd order ODE
s2 = m.*(R./(l.*B));                                % s^2 term of 2nd order ODE
sden = s2.*(s.*s) + s1.*s ;                         % denominator of TF

sys = num./sden;                                    % TF as symbolic function
X = Vs.*sys;                                        % output = input * TF

% Simulink
den = sym2poly(sden);
system = tf(num, den);
rlocus(system)
tau = 1;

% % state space
% ss_system = tf2ss(num, den);

% % Solution
% xt = ilaplace(X);                                   % inverse laplace
% 
% % Data generation for NN
% t = 0:0.1:10;                                       % time series input
% x = subs(xt);                                       % explicit values

% % NN parameters
% input = repmat(Vs,1,length(t));
% output = double(x);