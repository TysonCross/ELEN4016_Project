% % Data generation for NN
clear all; clc;

% NN parameters
System_parameters;

% phases to run
use_cached_data = false;
use_cached_net = false;
do_train = true;

% generate data
if (use_cached_data==false)
    disp("Generating and caching data...")
    
    time_step = 0.05;
    voltage_step = 0.1;
    voltage = [-50:voltage_step:50];              % volts (input range)
    t = [0:time_step:10]';                          % time series input

    % create matrix input
    v_1 = zeros(1,length(voltage));
    v_2 = repmat(voltage,length(t)-1,1);
    v_input = [v_1;v_2];

    % simulation
    start_simulink;
    model =  'NeuralNetUnitLDC_IO.slx';
    % output = 0;
    load_system(model);
    
    for i = 1:length(voltage)
        input = timeseries(v_input(:,i),t);
%         sim(model);
        output = sim(model, 'SrcWorkspace','current',...
                'StartTime',string(t(1)),...
                'StopTime',string(t(end)),...
                'FixedStep', string(time_step));
        out_temp(:,i) = output.output.Data;
    end

    clear output i

    output = timeseries(out_temp,t);

    % after simulation
    in_NN_data = v_input;
    out_NN_data = out_temp;
    
    % report sizes:
    size(out_NN_data)
    disp(["Data set of ", length(out_NN_data), " elements"])
    
    save('cache/IO_data',...
        'in_NN_data','out_NN_data',...
        'time_step','t','model');
    clear v_input voltage_steps out_temp tout v_1 v_2 voltage i
    clear input output
    disp("Data generated")
else
    load('cache/IO_data');
    disp('Loaded IO data from cache...')
end

% clear b B B2 B3 f i l m R  T time_steps time_delta V model

% create NN
if (use_cached_net==false)
    disp("Creating NARX net...")

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

    disp(["Data set of ", length(out_NN_data), " elements"])
    disp(["Data set of ", length(out_NN_data), " elements"])
    
    trained_status = false;

    % setup
    delayin = 1:2;
    delaytarget = 1:2;
    hiddenlayers = 20;
    net = narxnet(delayin,delaytarget,hiddenlayers);
    net.divideFcn = '';
    net.trainParam.min_grad = 1e-10;
    [p1,Pi1,Ai1,t1] = preparets(net,in_train_data,{},target_train_data);
    view(net);

    save('cache/NN_model','p1','Pi1','Ai1','t1',...
        'in_NN_data','out_NN_data',...
        'in_train_data','target_train_data',...
        'in_new_data','out_new_data',...
        'trained_status','net');
    clear numelements indices indices indices_new indices_main
    disp('Cached untrained NARX net')
else
    load('cache/NN_model');
    if (trained_status)
        disp('Trained NARX net loaded from cache...')
    else
        disp('Untrained NARX net loaded from cache...')
    end
end

% if (do_train==false)
%     disp("Training is OFF, stopping")
%     return;
%     beep;
% end

% training
if ((trained_status==false) || (do_train))
    disp("Training NARX net")
    net = train(net,p1,t1,Pi1);
    beep;
    disp("Training complete")
    trained_status = true;
    
    save('cache/NN_model','p1','Pi1','Ai1','t1',...
        'in_NN_data','out_NN_data',...
        'in_train_data','target_train_data',...
        'in_new_data','out_new_data',...
        'trained_status','net');
    disp('Cached trained NARX net')
else
    load('cache/NN_model')
    disp('Trained NARX net loaded from cache...')
end
    
    % simulate the network and plot the resulting errors 
    yp = sim(net,p1,Pi1);
    e = cell2mat(yp)-cell2mat(t1);
fig10 = figure(10);
set(fig10,'name','Error between NN output and known output');
plot(e,'r');

    % close the loop
    narx_net_closed = closeloop(net);
    view(narx_net_closed);

    [p2,Pi2,Ai2,t2] = preparets(narx_net_closed,in_new_data,{},out_new_data);
    yp1 = narx_net_closed(p2,Pi2,Ai2);

fig11 = figure(11);
set(fig11,'name','Output from NN and BlackBox');
plot(cell2mat(yp1),'r');
hold on;
plot(cell2mat(out_new_data),'b');
