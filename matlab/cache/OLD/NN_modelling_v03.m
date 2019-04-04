%%% Data generation for NN
% set(0,'ShowHiddenHandles','on'); delete(get(0,'Children')); % close windows
close all; clear all; clc;

% Phases to run
use_cached_data = false;         % if false, generate new data
use_cached_net = false;          % if false, generate new NARX net
do_train = true;                % if true, perform training
recover_checkpoint = false;      % if training did not finish, use checkpoint
archive_net = false;              % archive NN, data dn figures to subfolder

%% Data generation phase
if (use_cached_data==false)
    disp('Generating and caching data...')
    
    clear all;
    time_step = 0.01;
    max_voltage = 1;
    time_num = 1000;

    min_time_jump = 10;
    max_time_jump = 50;
%     voltage = zeros(length(ts),1)';
i = 1;
    while i<time_num
       voltage_now = rand()*max_voltage;
       time_jump = randi(max_time_jump-1) + min_time_jump;
       j = i;
       while j<(i+time_jump)
           voltage(j) = voltage_now
           time_jump_log(j) = time_jump;
           j = j + 1;
       end
       i = i + time_jump;
    end

    close all;
figTEST = figure();
plot(voltage,'r');
hold on
plot(time_jump_log,'b');

    % blackbox parameters
    System_parameters;
    
    % simulation
    start_simulink;
    model = 'NeuralNetUnitLDC_IO.slx';
    load_system(model);
    
    input = timeseries(v_input,t,'Name','input to blackbox');
    out_temp = sim(model, 'SrcWorkspace','current',...
            'StartTime',string(t(1)),...
            'StopTime',string(t(end)),...
            'FixedStep', string(time_step));
    output = out_temp.output;

    % after simulation
    in_NN_data = input.Data(:);
    out_NN_data = output.Data(:);
    
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
%     in_data = con2seq(in_NN_data);
%     target_data = con2seq(out_NN_data);
    in_data = num2cell(in_NN_data');
    target_data = num2cell(out_NN_data');

    fprintf("NARX net has input size: %d \n", numel(t));
    trained_status = false;

    % NN setup
    input_delays = 1:2;
    feedback_delays = 1:201;
    hidden_layers = 1;
    net = narxnet(input_delays,feedback_delays,hidden_layers);
    net.divideFcn = 'dividerand';
    net.divideParam.trainRatio = 70/100;
    net.divideParam.valRatio = 15/100;
    net.divideParam.testRatio = 15/100;
    [inputs,feedbackDelays,layerStates,targets] = ...
        preparets(net,in_data,{},target_data);

    save('cache/NN_model',...
        'inputs','feedbackDelays','layerStates','targets',...
        'in_data','target_data',...
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
        'in_data','target_data','TR',...
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

% figures
figOutput = figure();
set(figOutput,'name','Output from NN and BlackBox');
axOutput = axes(figOutput);
plot(cell2mat(outputs(TR.valInd)),'r');
hold on;
% plot(cell2mat(targets(TR.valInd)),'g');
hold on
title('Output from NN and BlackBox');

figError = figure();
set(figError,'name','Error between NN output and known output');
plot(cell2mat(errors),'r');
title('Error between NN output and known output (open net)');
hold off

gensim(net,time_step);

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
figOutputClosed = figure();
set(figOutputClosed,'name','Output from NN and BlackBox');
axOutputClosed = axes(figOutputClosed);
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