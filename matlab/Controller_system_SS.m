%% State Space Observer Controller
% Tyson Cross       1239448
% James Goodhead    1387118

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
ss_system = ss(A1,B1,C1,D1);                        % State Space system  
set(ss_system,'StateName',{'position';'velocity'},'InputName',{'voltage'})
obs_sys = obsv(A1,C1);                              % observability
rank_obs = rank(obs_sys);                           % rank of observer ss
% rlocus(ss_system)

% SS Controller Design
p1 = -1 +1i;                                    % choose poles to add
p2 = -1 -1i;                                    % second pole to add
P1 = [p1 p2];

K1 = acker(A1,B1,P1)
% K1 = place(A1',C1',P1);                        % controller gain

% Calculate normalisation
size_A = size(A1,1);
Z = [zeros([1,size_A]) 1];
N = inv([A1,B1;C1,D1])*Z';
Nx = N(1:size_A);
Nu = N(1+size_A);
Nbar = Nu + K1*Nx;

op1 = -6.5 + 0.6i;
op2 = -6.5 - 0.6i;
OP1 = Nbar*[op1 op2];
% L1 = acker(A1',C1',OP1)
L1 = place(A1',C1',OP1)';                      % observer gain (2x-5x the controller gain

est = estim(ss_system,L1) 
poles_plant = eig(ss_system)                        % poles of system
poles = eig(A1 - K1*C1')                            % check poles 

% rlocus(ss_system);
