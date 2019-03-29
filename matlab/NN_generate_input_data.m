% % Data generation for NN
clear all; clc;

% NN parameters
System_parameters;

% phases to run
use_cached_data = false;
use_cached_net = false;
do_train = false;

% generate data
if (use_cached_data==false)
    time_delta = 0.1;
    voltage_steps = 0.1;
    Voltage = [-50:voltage_steps:50];                        % volts (input range)
    time_steps = [0:time_delta:10]';                         % time series input

    % create matrix input
    v_1 = zeros(1,length(Voltage));
    v_2 = repmat(Voltage,length(time_steps)-1,1);
    v_input = [v_1;v_2];

    % simulation
    start_simulink;
    model =  'NeuralNetUnitLDC_IO.slx';
    % output = 0;
    load_system(model);

    for i = 1:length(Voltage)
        input = timeseries(v_input(:,i),time_steps);
%         sim(model);
        output = sim(model, 'SrcWorkspace','current',...
                'StartTime',string(time_steps(1)),...
                'StopTime',string(time_steps(end)),...
                'FixedStep', string(time_delta));
        out_temp(:,i) = output.output.Data;
    end

    clear output i

    output = timeseries(out_temp,time_steps);

    % after simulation
    in_NN_data = v_input;
    out_NN_data = out_temp;

    save('cache/IO_data','in_NN_data','out_NN_data');
    clear v_input voltage_steps out_temp tout v_1 v_2  
    
    disp("Data generated")
else
    load('cache/IO_data');
    disp('Loaded IO data from cache')
end

% clear b B B2 B3 f i l m R  T time_steps time_delta V model

% create NN
if (use_cached_net==false)
    % prepare the data

    in_NN_data = con2seq(in_NN_data);
    out_NN_data = con2seq(out_NN_data);

    % segment_data
    numelements = round(0.8*length(in_NN_data));
    indices = randperm(length(in_NN_data));
    indices_main = indices(1:numelements);
    indices_new = indices(numelements:end);

    in_train_data = in_NN_data(indices_main);
    target_train_data = out_NN_data(indices_main);
    in_new_data = in_NN_data(indices_new);
    out_new_data = out_NN_data(indices_new);

    trained_status = false;

    % setup
    net = narxnet(1:2,1:2,10);
    % net.divideFcn = '';
    net.trainParam.min_grad = 1e-10;
    [p,Pi,Ai,t] = preparets(net,in_train_data,{},target_train_data);

    save('cache/NN_model','p','Pi','Ai','t',...
        'in_NN_data','out_NN_data',...
        'in_train_data','target_train_data',...
        'in_new_data','out_new_data',...
        'trained_status','net');

    clear numelements indices indices indices_new
else
    load('cache/NN_model');
    disp('Loaded NNet from cache')
end

if (do_train==false)
    return;
    beep;
end

% training
if ((trained_status==false) || (do_train))
    net = train(net,p,t,Pi);
    beep;
    disp("Training complete")
    trained_status = true;
    
    save('cache/NN_model','p','Pi','Ai','t','in_NN_data','out_NN_data',...
        'in_train_data','target_train_data','in_new_data','out_new_data',...
        'trained_status','net');
else
    load('cache/NN_model')
end
    
    % simulate the network and plot the resulting errors 
    yp = sim(net,p,Pi);
    e = cell2mat(yp)-cell2mat(t);
    plot(e)

    % close the loop
    narx_net_closed = closeloop(net);

    view(net);
    view(narx_net_closed);

    [p1,Pi1,Ai1,t1] = preparets(narx_net_closed,in_new_data,{},out_new_data);
    yp1 = narx_net_closed(p1,Pi1,Ai1);


TS = size(t1,2);
% plot(1:TS,cell2mat(t1),'b',1:TS,cell2mat(yp1),'r')
