% % Data generation for NN
clear all;

delta = 0.5;
V = [-100:delta:100];                              	% volts (input range)
t = linspace(0,10,length(V))';                      % time series input
if (length(t) == length(V)) 
    disp(["Length is:", length(t)]);
end

% NN parameters
System_parameters;
b = f;
B2 = B;
B3 = B;
v_1 = zeros(1,length(V));
v_2 = repmat(V,length(t)-1,1);
v_input = [v_1;v_2];
% input_all = timeseries(v_input,t); %[t V]; % repmat(V,1,length(t));

% simulation
start_simulink;
model =  'NeuralNetUnitLDC_IO.slx';
output = 0;
load_system(model);

for i = 1:length(t)
    input = timeseries(v_input(:,i),t);
    sim(model);
%     sim(model,'StartTime',string(t(1)),'StopTime',string(t(end)),'FixedStep', string(t(2)-t(1)) );
    out_temp(:,i) = output.Data;
end

% after simulation
in_NN_data = v_input;
out_NN_data = out_temp;

% plot(t,in_NN_data(:,2));
% hold on;
% plot(t,out_NN_data)