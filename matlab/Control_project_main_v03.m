%% LDC Model (Newtonian)
% Tyson Cross       1239448
% James Goodhead    1387118

clc; clear all;

system_parameters;

%%% Newtonian Modelling (i.t.o displacement)
syms s t
num = 1;                                            % numerator of TF
s1 = l.*B + f.*R./(l.*B);                           % s term of 2nd order ODE
s2 = m.*(R./(l.*B));                                % s^2 term of 2nd order ODE
sden = s2.*(s.*s) + s1.*s ;                         % denominator of TF

% Modelling in terms of velocity
% sden = s2.*(s) + s1;
% sys = num./sden

sys = num./sden;                                    % TF as symbolic function
% X = V.*sys;                                       % output = input * TF

% state space
[A1,B1,C1,D1] = ssdata(system);                     % two state variables
rank_sys = rank(ctrb(A1,B1));
obs_sys = obsv(A1,C1);
rank_obs = rank(obs_sys);

% % Solution to x (displacement in time domain)
% xt = ilaplace(X);                                   % inverse laplace

% % Solve for displacement as function of time symbolically
% syms x(t) y;
% Dx = diff(x);
% ode = m*diff(x,t,2) + ((l*l*B*B)/R + f)*diff(x,t) == l*B/R*y;
% cond1 = x(0) == 0;
% cond2 = Dx(0) == 0;
% conds = [cond1 cond2];
% xSol(t) = dsolve(ode,conds);
% xsol = simplify(xSol)

%%% Simulink
den = sym2poly(sden);
system = tf(num, den);
rlocus(system);
poles=eig(system);

%% Control_system_simulation.slx

% Modelling of PID controller (Tuned)
 P = 0.159243539750473;                                         % proportional 
 I = 0.0209333117982786;                                        % integral
 D = 0.242558878110515;                                         % derivative
 N = 20.119;
PIDsystem = P + I/s + D*(N/(1+(N/s)));                          % controller transfer function

% Model of entire system 
 Gs = PIDsystem.*sys                                            % Open loop (combined) transfer function
 Xs = 1/s;                                                      % step input
 Ys = (Xs*Gs)/(1+Gs)                                            % output from closed loop transfer function
 
 % Time domain
 Distance = ilaplace(Ys);
 Velocity = diff(Distance);
 Acceleration = diff(Velocity);
 %t = 0:0.01:5
 
 %Model of the Output of PID controler
 Xs = 1/s;
 controllerEffort = (Xs-Ys)*(PIDsystem);                     %Voltage applied to the motor
 MotorV = (ilaplace(controllerEffort,t));
 MotorC = MotorV./R;                                            %Current in the motor 
 MotorP = MotorC.*MotorV;                                        %instantanious Power
 MotorCE3 = double(int(MotorP,t,0,3))
% MotorCE = int(MotorP,t,0,t,'PrincipalValue',true);
%                                                               %Motor cumulative energy
%                                                               
% %Calculate the increase in resistace due to increase in temperature. 
% deltaT = subs(MotorCE,t,3)/(0.385*0.75264);
% Rnew = R*(1+0.0039*(deltaT));
