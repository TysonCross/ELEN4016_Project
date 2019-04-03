%% LDC Model (Newtonian)
% Tyson Cross       1239448
% James Goodhead    1387118

clc; clear all;

solve_differential = false;
doMatlabBlockSimulation = false;

System_parameters;

ts = 0:0.01:20;                                     % Time vector
Vs = [0:0.1:20];                                    % volts (input range)

%%% Newtonian Modelling (i.t.o displacement)
syms s t
num = 1;                                            % numerator of TF
s1 = l.*B + f.*R./(l.*B);                           % s term of 2nd order ODE
s2 = m.*(R./(l.*B));                                % s^2 term of 2nd order ODE
sden = s2.*(s.*s) + s1.*s ;                         % denominator of TF

% (Modelling in terms of velocity)
% sden_v = 2.*s2.*(s) + s1;

sys = num./sden;                                    % TF as symbolic function
X = Vs.*sys;                                        % output = input * TF
den = sym2poly(sden);
system = tf(num, den)
poles=eig(system);

% % Solution to x (displacement in time domain)
xt = ilaplace(X);                                	% inverse laplace

% % Solve for displacement as function of time symbolically
if solve_differential
    syms x(t) y;
    Dx = diff(x);
    ode = m*diff(x,t,2) + ((l*l*B*B)/R + f)*diff(x,t) == l*B/R*y;
    cond1 = x(0) == 0;
    cond2 = Dx(0) == 0;
    conds = [cond1 cond2];
    xSol(t) = dsolve(ode,conds);
    xsol = simplify(xSol)
end

%%% Simulink: Control_system_simulation.slx

if doMatlabBlockSimulation
    % Modelling of PID controller (Tuned)
    P_in = 0.159243539750473;                                   % proportional 
    I_in = 0.0209333117982786;                                  % integral
    D_in = 0.242558878110515;                                   % derivative
    N_in = 20.119;                                              % filter order
    pidIn = P_in + I_in/s + D_in*(N_in/(1+(N_in/s)));           % inner controller TF

    P_out = 2.18874816182797;                                   % proportional 
    I_out = 4.71571977773303;                                   % integral
    D_out = -0.00510145458960086;                            	% derivative
    N_out = 4.53125915381535;                                   % filter order
    pidOut = P_out + I_out/s + D_out*(N_out/(1+(N_out/s)));     % outer controller TF

    % Model of entire system 
     H = pidIn.*sys;                                    % Inner open loop (combined) TF
     G = H/(1+H);                                       % Inner closed loop
     T = (pidOut*G)/(1 + G + pidOut*G);                	% Outer closed loop
     Y = X*T;                                           % output from total closed loop TF

     % Time domain
    %  Distance = simplify(ilaplace(Y));
    %  Velocity = diff(Distance);
    %  Acceleration = diff(Velocity);

     %%% Below needs to be updated for double PID controller
    %  %Model of the Output of PID controler
    %  controllerEffort = (X-Y)*(pidIn);                  % Voltage applied to the motor
    %  MotorV = (ilaplace(controllerEffort,t));
    %  MotorC = MotorV./R;                               	% Current in the motor 
    %  MotorP = MotorC.*MotorV;                         	% instantanious Power
    %  MotorCE3 = double(int(abs(MotorP),t,0,4))
    %  %MotorCE = int(MotorP,t,0,t,'PrincipalValue',true); 	% Motor cumulative energy
    %                                                                
    %  MotorVmatrix = abs(double(subs(MotorV,t,ts)));     	% voltage sampled at T
    %  MotorCmatrix = abs(MotorVmatrix./R);
    %  MotorPmatrix = MotorCmatrix.*MotorVmatrix;
    %  MotorCEmatrix = cumsum(MotorPmatrix.*0.001);
end

% load the data simulation with stepped input voltage values
% load('cache/IO_data.mat');
% input = timeseries(cell2mat(in_data),t,'Name','input to blackbox');


