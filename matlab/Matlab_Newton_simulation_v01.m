%% LDC Model (Newtonian)
% Tyson Cross       1239448
% James Goodhead    1387118

clc; clear all;

% System Parameters
m = 0.04;                                            % kg
<<<<<<< HEAD:matlab/Matlab_Newton_simulation_v01.m
B = 0.5;                                            % Telsa
l = 0.1;                                            % m
R = 1;                                              % Ohms
V = [-100:0.5:100]';                                % volts (input range)
f = 0.01;                                           % friction coefficient


% Modelling
=======
B = 0.3;                                            % Telsa
l = 0.1;                                              % m
R = 0.1;                                            % Ohms
%Vs = [-20:0.1:20]';                                % volts (input range)
Vs = 15
f = 0.01;                                           % friction coefficient

% Modelling in terms of displacement
>>>>>>> NonLinearRes:matlab/NewtonMethod.m
syms s t
num = 1;                                            % numerator of TF
%s1 = l.*B + f.*R./(l.*B);                          % s term of 2nd order ODE
s1 = l.*B;                                          % Without friction
s2 = m.*(R./(l.*B));                                % s^2 term of 2nd order ODE
sden = s2.*(s.*s) + s1.*s ;                         % denominator of TF
sys = num./sden                                     % TF as symbolic function
%X = Vs.*sys;                                        % output = input * TF

% Modelling in terms of velocity
% num = 1;
% sden = s2.*(s) + s1;
% sys = num./sden
% velocity = Vs.*sys;

<<<<<<< HEAD:matlab/Matlab_Newton_simulation_v01.m
sys = num./sden;                                    % TF as symbolic function
% X = V.*sys;                                         % output = input * TF
=======
>>>>>>> NonLinearRes:matlab/NewtonMethod.m

% Simulink
den = sym2poly(sden);
system = tf(num, den);
<<<<<<< HEAD:matlab/Matlab_Newton_simulation_v01.m
rlocus(system);
poles=eig(system);
tau = 1;

% state space
[A1,B1,C1,D1] = ssdata(system);                     % two state variables
rank_sys = rank(ctrb(A1,B1));
obs_sys = obsv(A1,C1);
rank_obs = rank(obs_sys);
=======
%rlocus(system)
%tau = 1;

% Modelling of PID controller
 P = 0.159243539750473
 I = 0.0209333117982786
 D = 0.242558878110515
 N = 20.119
PIDsystem = P + I/s + D*(N/(1+(N/s)))



% Model of entire system 
 Gs = PIDsystem.*sys
 Ys = ((1/s)*Gs)/(1+Gs)
 Distance = ilaplace(Ys)
 Velocity = diff(Distance);
 Acceleration = diff(Velocity);
 %t = 0:0.01:5
 
%  %Model of the Output of PID controler
% controllerEffort = ((1/s)-Ys)*(PIDsystem)                     %Voltage applied to the motor
% MotorV = (ilaplace(controllerEffort,t))
% MotorC = MotorV./R                                            %Curent in the motor 
% MotorP = MotorC.*MotorV                                        %instantanious Power
% MotorEC = double(int(MotorP,t,0,3));
%                                                               %Motor cumulative energy
%                                                               
% %Culculate the increase in resistace due to increase in temperature. 
% deltaT = MotorEC/(0.385*0.75264);
% Rnew = R*(1+0.0039*(deltaT));
% 
% 
%  
% %Plot system Mechanical Parameters
%  figure
%  fplot(Distance,[0 3])
%  hold on
%  fplot(Velocity,[0 3])
%  hold on
%  fplot(Acceleration/10,[0 3])
%  title('Step Responce of Closed Loop System Including PID Controller');
%  xlabel('Time (s)');
%  ylabel('Displacement,Velocity,Acceleration (m,m/s,m/(s^2)x10^+1');
%  
%  %Plot system Electrical Parameters
%  figure
%  fplot(MotorV,[0 3])
%  hold on
%  fplot(MotorC,[0 3])
%  hold on
%  fplot(MotorP/10,[0 3])
%  %hold on
%  %fplot(MotorCE,[0 3])
%  title('Step Responce of Closed Loop System Including PID Controller');
%  xlabel('Time (s)');
%  ylabel('Voltage,Current,Power, Energy (V,A,Wx10+1, J');
%  legend('Voltage', 'Current','Power');
 
 


% % state space modeling  controllable and observable
>>>>>>> NonLinearRes:matlab/NewtonMethod.m

 [Ass,Bss,Css,Dss] = tf2ss(num, den)
 [V,D] = eig(Ass)
 test = [0,1;-2,-3]
 [V,D] = eig(test)
 P = inv(V)
 Lambda = P*Ass*inv(P)
 Bhat = P*Bss
 Chat = Css*inv(P)
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