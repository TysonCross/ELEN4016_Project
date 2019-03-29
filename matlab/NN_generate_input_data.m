% % Data generation for NN
clear all;

time_delta = 0.1;
voltage_steps = 0.5;
V = [-50:voltage_steps:50];                     % volts (input range)
t = [0:time_delta:10]';                         % time series input

% NN parameters
System_parameters;
b = f;
B2 = B;
B3 = B;

% create matrix input
v_1 = zeros(1,length(V));
v_2 = repmat(V,length(t)-1,1);
v_input = [v_1;v_2];
% input_all = timeseries(v_input,t); %[t V]; % repmat(V,1,length(t));

% simulation
start_simulink;
model =  'NeuralNetUnitLDC_IO.slx';
% output = 0;
load_system(model);

for i = 1:length(V)
    input = timeseries(v_input(:,i),t);
    sim(model);
%     sim(model,'StartTime',string(t(1)),'StopTime',string(t(end)),'FixedStep', string(time_delta),'ReturnWorkspaceOutputs','on' );
    out_temp(:,i) = output.Data;
end

% after simulation
in_NN_data = v_input;
out_NN_data = out_temp;

clear b B B2 B3 f i l m R input output out_temp model T t time_delta tout V v_1 v_2 v_input voltage_steps
disp("Data generated")
beep;

% plot(t,in_NN_data(:,2));
% hold on;
% plot(t,out_NN_data)