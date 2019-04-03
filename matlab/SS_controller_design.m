%% State Space Observer Controller
% Tyson Cross       1239448
% James Goodhead    1387118

clc; clear all;

System_parameters;

ts = 0:0.01:20;                                     % Time vector
Vs = [0:0.1:5];                                     % volts (input range)
ut = zeros(size(ts));                               % input step function


%%% Newtonian Modelling (i.t.o displacement)
syms s t
num = 1;                                            % numerator of TF
s1 = l.*B + f.*R./(l.*B);                           % s term of 2nd order ODE
s2 = m.*(R./(l.*B));                                % s^2 term of 2nd order ODE
sden = s2.*(s.*s) + s1.*s ;                         % denominator of TF

sys = num./sden;                                    % TF as symbolic function
X = Vs.*sys;                                        % output = input * TF
den = sym2poly(sden);
system = tf(num, den)

% state space
[A1,B1,C1,D1] = ssdata(system);

% A1 = [ 0 1 ; 0 -0.475 ];
% B1 = [ 0; 1 ];
% C1 = [ 1 0 ];
% D1 = [ 0 ];

% state space
ss_system = ss(A1,B1,C1,D1);                        % State Space system  
set(ss_system,'StateName',{'position';'velocity'},'InputName',{'voltage'})
% ss_system = canon(ss_system/-7.5,'companion')';
obs_sys = obsv(A1,C1);                              % observability
rank_obs = rank(obs_sys);                           % rank of observer ss
poles = eig(ss_system)                              % poles of system

% simulation
[ys,ts,xs] = lsim(ss_system,ut,ts,[1 0]);

figSim = figure();
plot(ts,ys)
title('Open-Loop Response to Non-Zero Initial Condition')
xlabel('Time (sec)')
ylabel('Velocity (m)')
hold off


% SS Controller Design
p1 = -0.3;                                          % choose poles to add
p2 = -0.2;                                          % second pole to add

K = place(A1',C1',[p1 p2]);                         % place poles in K
ss_obs = ss(A1-B1*K,B1,C1,D1);                      % contruct system
poles = eig(A1 - K*C1')                             % check poles 

% Calculate normalisation
size_A = size(A1,1);
Z = [zeros([1,size_A]) 1];
N = inv([A1,B1;C1,D1])*Z';
Nx = N(1:size_A);
Nu = N(1+size_A);
Nbar = Nu + K*Nx;

% rlocus(ss_system);

% lsim(ss_system, X, ts, x0);