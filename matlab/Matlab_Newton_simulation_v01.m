%% LDC Model (Newtonian)
% Tyson Cross       1239448
% James Goodhead    1387118

clc; clear all;

% System Parameters
m = 0.04;                                            % kg
B = 0.5;                                            % Telsa
l = 0.1;                                            % m
R = 1;                                              % Ohms
V = [-100:0.5:100]';                                % volts (input range)
f = 0.01;                                           % friction coefficient


% Modelling
syms s t
num = 1;                                            % numerator of TF
s1 = l.*B + f.*R./(l.*B);                           % s term of 2nd order ODE
s2 = m.*(R./(l.*B));                                % s^2 term of 2nd order ODE
sden = s2.*(s.*s) + s1.*s ;                         % denominator of TF

sys = num./sden;                                    % TF as symbolic function
% X = V.*sys;                                         % output = input * TF

% Simulink
den = sym2poly(sden);
system = tf(num, den);
rlocus(system);
poles=eig(system);
tau = 1;

% state space
[A1,B1,C1,D1] = ssdata(system);                     % two state variables
rank_sys = rank(ctrb(A1,B1));
obs_sys = obsv(A1,C1);
rank_obs = rank(obs_sys);

% % Solution
% xt = ilaplace(X);                                   % inverse laplace

syms x(t) y;
Dx = diff(x);
ode = m*diff(x,t,2) + ((l*l*B*B)/R + f)*diff(x,t) == l*B/R*y;
cond1 = x(0) == 0;
cond2 = Dx(0) == 0;
conds = [cond1 cond2];
xSol(t) = dsolve(ode,conds);
xsol = simplify(xSol)
% 
% % Data generation for NN
t = linspace(0,10,length(V));                                       % time series input
% x1 = subs(xt);                                       % explicit values

% % NN parameters
b = f;
B2 = B; B3 = B;
input = [t' V] %repmat(V,1,length(t));
% output = double(x1);