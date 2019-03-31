%%% Data generation for NN
clear all; clc;

% NN parameters
System_parameters;

% Phases to run
use_cached_data = false;         % if false, generate new data
use_cached_net = false;          % if false, generate new NARX net
do_train = true;                % if true, perform training
recover_checkpoint = true;      % if training did not finish, use checkpoint
archive_net = true;              % archive NN, data dn figures to subfolder

%% Data generation phase
if (use_cached_data==false)
    disp('Generating and caching data...')
    
    time_step = 0.1;
    voltage_step = 0.01;
    voltage = [0:voltage_step:1];              % volts (input range)
    t = [0:time_step:20]';                      % time series input

    % create matrix input
    v_1 = zeros(1,length(voltage));
    v_2 = repmat(voltage,length(t)-1,1);
    v_input = [v_1;v_2];

    % simulation
    start_simulink;
    model = 'NeuralNetUnitLDC_IO.slx';
    load_system(model);
    
    for i = 1:length(voltage)
        input = timeseries(v_input(:,i),t);
        output = sim(model, 'SrcWorkspace','current',...
                'StartTime',string(t(1)),...
                'StopTime',string(t(end)),...
                'FixedStep', string(time_step));
        out_temp(:,i) = output.output.Data;
    end

    % after simulation
    in_NN_data = v_input;
    out_NN_data = out_temp;
    
    % report sizes:
    msg = ["Data set of " num2str(numel(out_NN_data)) " entries"];
    disp(msg)
    [a,b] = size(out_NN_data);
    msg = ["Data consists of '" num2str(a) ...
        " timesteps of '" num2str(b) " elements"];
    disp(msg)
    disp(' ')
    
    save('cache/IO_data',...
        'in_NN_data','out_NN_data',...
        'time_step','t', 'voltage_step', 'voltage', 'model');
    clear v_input voltage_steps out_temp tout v_1 v_2 i input output
    disp("Data generated")
else
    load('cache/IO_data');
    disp('Loaded IO data from cache...')
end

%% NARX creation phase
if (use_cached_net==false)
    disp("Creating NARX net...")

    % prepare the data
    in_NN_data = con2seq(in_NN_data);
    out_NN_data = con2seq(out_NN_data);

    % segment_data (and randomise sequence order)
    numelements = round(0.8*length(in_NN_data));
    indices = randperm(length(in_NN_data));
    indices_main = indices(1:numelements);
    indices_new = indices(numelements:end);

    in_train_data = in_NN_data(indices_main);
    target_train_data = out_NN_data(indices_main);
    in_new_data = in_NN_data(indices_new);
    target_new_data = out_NN_data(indices_new);

    msg = sprintf("NARX net has input size: " num2str(numel(t))];
    disp(msg)
    msg = ["Training set of " num2str(round(0.8*numel(out_NN_data(:)))) ...
            " sequences"];
    disp(msg)
    msg = ["Testing set of " num2str(round(0.2*numel(out_NN_data(:)))) ...
            " sequences"];     
    trained_status = false;

    % NN setup
    delayin = 0:1;
    delaytarget = 1:2;
    hiddenlayers = 1;
    net = narxnet(delayin,delaytarget,hiddenlayers);
    net.divideFcn = 'divideblock';
    net.divideParam.trainRatio = 85/100;
    net.divideParam.valRatio = 10/100;
    net.divideParam.testRatio = 5/100;
    [inputs,feedbackDelays,layerStates,targets] = ...
        preparets(net,in_train_data,{},target_train_data);

    save('cache/NN_model',...
        'inputs','feedbackDelays','layerStates','targets',...
        'in_NN_data','out_NN_data',...
        'in_train_data','target_train_data',...
        'in_new_data','target_new_data',...
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

%% Training phase
if ((trained_status==false) || (do_train))
    disp("Training NARX net (open loop)")
    training_complete = false;
    if (recover_checkpoint==true)
        if exist('cache/checkpoint.mat','file') == 2
            load('cache/checkpoint.mat');
            disp("Recovered last checkpoint")
            [inputs,feedbackDelays,layerStates,targets] = ...
                preparets(net,in_train_data,{},target_train_data);
        else
            disp("Unable to recover last checkpoint, retraining")
        end
    end
    
    net.trainFcn =  'trainlm';
    net.trainParam.epochs = 1500;
    net.trainParam.show = 10;
    net.trainParam.min_grad = 1e-10;
%     net.plotFcns = {'plotperform','plottrainstate','plotresponse', ...
%         'ploterrcorr', 'plotinerrcorr'};
    [net,TR] = train(net,inputs,targets,feedbackDelays,'CheckpointFile','cache/checkpoint.mat');
    beep;
    disp("Training complete")
    trained_status = true;
    training_complete = true;
    if exist('cache/checkpoint.mat','file') == 2
        delete cache/checkpoint.mat;
    end
    
    save('cache/NN_model','inputs','feedbackDelays','layerStates','targets',...
        'in_NN_data','out_NN_data','TR',...
        'in_train_data','target_train_data',...
        'in_new_data','target_new_data',...
        'trained_status','training_complete','net');
    disp('Cached trained NARX net')
else
    load('cache/NN_model')
    disp('Trained NARX net loaded from cache...')
end
    
%% Testing and plotting phase

% simulate the network and plot the resulting errors 
yp = sim(net,inputs,feedbackDelays);
e = cell2mat(yp)-cell2mat(targets);
% [~, max_index] = max(max(e));
    
fig10 = figure(10);
set(fig10,'name','Error between NN output and known output');
% plot(e(:,max_index),'r');
plot(e,'r');
title('Error between NN output and known output');

% close the loop
narx_net_closed = closeloop(net);

view(narx_net_closed)

%%Test the Network
[inputs_test,inputStates_test,layerStates_test,targets_test] = ...
    preparets(narx_net_closed,in_new_data,{},target_new_data);
outputs_test = narx_net_closed(inputs_test,inputStates_test,layerStates_test);
errors = gsubtract(targets_test,outputs_test);
performance = perform(narx_net_closed,targets_test,outputs_test)

figOutput = figure();
set(figOutput,'name','Output from NN and BlackBox');
axOutput = axes(figOutput)
plot(axOutput,t,cell2mat(outputs_test),'r');
hold on;
plot(axOutput,t,cell2mat(target_new_data),'b');
hold on
plot(axOutput,t,cell2mat(targets_test),'g');
hold on
title('Output from NN and BlackBox');

figPerform = figure()
plotperform(TR);
figTrainState = figure()
plottrainstate(TR);

clear max_val max_index 

jframe = view(narx_net_closed);
hFig = figure('Menubar','none', 'Position',[100 100 565 166]);
jpanel = get(jframe,'ContentPane');
[~,h] = javacomponent(jpanel);
set(h, 'units','normalized', 'position',[0 0 1 1])
%# close java window
jframe.setVisible(false);
jframe.dispose();


%% Save metadata, caches and matlab script
if (archive_net) && (training_complete)
   foldername = mlreportgen.utils.hash(string(datetime('now')))
   foldername = strcat("cache/", extractBefore(foldername,8));
   mkdir(foldername)
   copyfile('NN_modelling_v03.m',foldername)
   copyfile('cache/NN_model.mat',foldername)
   copyfile('cache/IO_data.mat',foldername)
   figHandles = findobj('Type', 'figure');
   for i=1:length(figHandles)
        figure(figHandles(i).Number);
        fn = sprintf('%s/fig%s.eps',foldername,num2str(i));
        export_fig(fn,figHandles(i))
   end
   gensim(narx_net_closed,time_step);
   fn = sprintf('%s/narx.slx',foldername);
   save_system(gcs,fn)
   bdclose(gcs)
   disp(sprintf("Data archived in %s",foldername))
else
    disp("WARNING: output NARX data not archived")
end