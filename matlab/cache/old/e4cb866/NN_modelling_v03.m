%%% Data generation for NN
% set(0,'ShowHiddenHandles','on'); delete(get(0,'Children')); % close windows
close all; clear all; clc;

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
    voltage_step = 0.5;
    voltage = [0:voltage_step:10];              % volts (input range)
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
    fprintf("Data set of %d entries \n", numel(out_NN_data));
    [a,b] = size(out_NN_data);
    fprintf("Data consists of %d timesteps of %d elements\n",a,b);
   
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
    in_data = con2seq(in_NN_data);
    target_data = con2seq(out_NN_data);

    fprintf("NARX net has input size: %d \n", numel(t));
    trained_status = false;

    % NN setup
    delayin = 1:2;
    delay = 2;
    delaytarget = 1:delay;
    hiddenlayers = 1;
    net = narxnet(delayin,delaytarget,hiddenlayers);
    net.divideFcn = 'dividerand';
    net.divideParam.trainRatio = 85/100;
    net.divideParam.valRatio = 10/100;
    net.divideParam.testRatio = 5/100;
    [inputs,feedbackDelays,layerStates,targets] = ...
        preparets(net,in_data,{},target_data);

    save('cache/NN_model',...
        'inputs','feedbackDelays','layerStates','targets',...
        'in_data','target_data',...
        'trained_status','net','delay');
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
                preparets(net,in_data,{},target_data);
        else
            disp("Unable to recover last checkpoint, retraining")
        end
    end
    
    net.trainFcn =  'trainlm';
    net.trainParam.epochs = 1000;
    net.trainParam.show = 10;
    net.trainParam.min_grad = 1e-10;
    net.trainParam.max_fail = 20;
    [net,TR] = train(net,inputs,targets,feedbackDelays,...
        'CheckpointFile','cache/checkpoint.mat');
    beep;
    disp("Training complete")
    trained_status = true;
    if strcmp(TR.stop,"User stop.")==false
        training_complete = true;
    end
    if exist('cache/checkpoint.mat','file') == 2
        delete cache/checkpoint.mat;
    end
    
    save('cache/NN_model','inputs','feedbackDelays','layerStates','targets',...
        'in_data','target_data','TR','delay',...
        'trained_status','training_complete','net');
    disp('Cached trained NARX net')
else
    load('cache/NN_model')
    disp('Trained NARX net loaded from cache...')
end
    
%% Training tests and performance evaluation

% simulate the network and plot the resulting errors
outputs = sim(net,inputs,feedbackDelays);
errors = gsubtract(targets,outputs);
performance_open = perform(net,targets,outputs)
    
figError = figure();
set(figError,'name','Error between NN output and known output');
plot(cell2mat(errors),'r');
title('Error between NN output and known output (open net)');
hold off

% figErrorHist = figure();
% ploterrhist(errors,'bins',20);

%% Deployment and testing

% Close the loop
net_closed = closeloop(net);

% Test the NARX net with original data
[inputs_c,feedbackDelays_c,layerStates_c,targets_c] = ...
    preparets(net_closed,in_data,{},target_data);
outputs_closed  = net_closed(inputs_c,{},layerStates_c);
% outputs_closed_sim  = sim(net_closed,inputs_c,{});
errors_closed = gsubtract(targets_c,outputs_closed);
performance_closed = perform(net_closed,targets_c,outputs_closed)

% figures
figOutput = figure();
set(figOutput,'name','Output from NN and BlackBox');
axOutput = axes(figOutput);
plot(cell2mat(outputs_closed(TR.testInd)),'r');
hold on;
plot(cell2mat(targets_c(TR.testInd)),'g');
hold on
title('Output from NN and BlackBox');

figPerform = figure();
plotperform(TR);
figTrainState = figure();
plottrainstate(TR);
figErrors = figure();
plot(cell2mat(errors_closed),'r');
title('Error between NN output and output (closed net)');
figReggression = figure();
plotregression(targets,outputs)

clear max_val max_index 

jframe = view(net_closed);
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
   copyfile('NN_Modelling_v03.m',foldername)
   copyfile('cache/NN_model.mat',foldername)
   copyfile('cache/IO_data.mat',foldername)
   figHandles = findobj('Type', 'figure');
   for i=1:length(figHandles)
        figure(figHandles(i).Number);
        fn = sprintf('%s/fig%s.eps',foldername,num2str(i));
        export_fig(fn,figHandles(i))
   end
   gensim(net_closed,time_step);
   fn = sprintf('%s/narx.slx',foldername);
   save_system(gcs,fn)
   bdclose(gcs)
   disp(sprintf("Data archived in %s",foldername))
else
    disp("WARNING: output NARX data not archived")
end