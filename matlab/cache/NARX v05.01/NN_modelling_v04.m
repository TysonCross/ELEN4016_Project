%%% Data generation for NN
set(0,'ShowHiddenHandles','on'); %delete(get(0,'Children')); % close windows
close all; clear all;

% Phases to run
use_cached_data = false;         % if false, generate new data
use_cached_net = false;          % if false, generate new NARX net
do_train = true;               % if true, perform training
recover_checkpoint = false;     % if training did not finish, use checkpoint
archive_net = true;            % archive NN, data and figures to subfolder

%% Data generation phase
if (use_cached_data==false)
    disp('Generating and caching data...')
    
    time_step = 0.01;
    max_voltage = 5;
    num_entries = 5e5;

    i = 10;
    voltage = zeros(i,1,1)';
    while i<num_entries
        min_time_jump = randi(5)/time_step;
        max_time_jump = randi(30)/time_step;
        chance = rand();
       if (chance<0.1)
           voltage_now = 0;
       elseif (chance>0.1 && chance<0.15)
           voltage_now = max_voltage;
      elseif (chance>0.15 && chance<0.2)
           voltage_now = -max_voltage; 
       elseif (chance>0.2 && chance<0.3)
           voltage_now = max(0,rand()*(max_voltage) - (max_voltage/2));
       else
           voltage_now = rand()*(max_voltage) - (max_voltage/2);
       end
       time_jump = randi(max_time_jump-1) + min_time_jump;
       j = i;
       while j<(i+time_jump)
           voltage(j) = voltage_now;
           j = j + 1;
       end
       i = i + time_jump;
    end
    
    clear i j
    
    voltage = voltage(1:num_entries); % clip off unwanted extra values.
    t = linspace(0,time_step*num_entries,num_entries);
    
    % blackbox parameters
    System_parameters;
    
    % simulation
    start_simulink;
    model = 'NeuralNetUnitLDC_IO.slx';
    load_system(model);
    
    input = timeseries(voltage,t,'Name','input to blackbox');
    out_temp = sim(model, 'SrcWorkspace','current',...
            'StartTime',string(t(1)),...
            'StopTime',string(t(end)),...
            'FixedStep', string(time_step));
    output = out_temp.output;

fig1 = figure(1)
plot(t,voltage)
hold on
plot(t,output.Data(1:end-1))
hold off
    
    % prepare the data after simulation
    in_data = num2cell(input.Data(:)');
    target_data = num2cell(output.Data(1:end-1)');
    
    % report sizes:
    fprintf("Data set of %d entries \n", numel(in_data));
    [a,b] = size(in_data);
    fprintf("Data consists of %d timesteps of %d elements\n",b,a);
   
    save('cache/IO_data',...
        'in_data','target_data',...
        'time_step','t', 'model');
    clear v_input voltage_steps out_temp tout v_1 v_2 i input output
    clear time_jump max_voltage num_entries voltage_now max_time_jump
    disp("Data generated")
else
    load('cache/IO_data');
    disp('Loaded IO data from cache...')
end

%% NARX creation phase
if (use_cached_net==false)
    disp("Creating NARX net...")

    fprintf("NARX net has input size: %d \n", numel(t));
    trained_status = false;

    % NN setup
    input_delays = 1:2;
    feedback_delays = 1:2;
    hidden_layers = 10;
    net = narxnet(input_delays,feedback_delays,hidden_layers);
    net.divideFcn = 'divideblock';
    net.divideParam.trainRatio = 75/100;
    net.divideParam.valRatio = 15/100;
    net.divideParam.testRatio = 10/100;

    save('cache/NN_model',...
        'trained_status','net');
    clear numelements indices indices indices_new indices_main
    disp('Cached untrained NARX net')
else
    load('cache/NN_model');
    if (trained_status)
        disp('Trained NARX net loaded from cache...')
        if (training_complete==false)
            disp("WARNING: training was stopped by user previously")
        end
    else
        disp('Untrained NARX net loaded from cache...')
    end
end

[inputs,feedbackDelays,layerStates,targets] = ...
        preparets(net,in_data,{},target_data);

%% Training phase
if do_train
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
    net.trainParam.epochs = 2000;
    net.trainParam.show = 10;
    net.trainParam.min_grad = 1e-10;
    net.trainParam.max_fail = 10;
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
end
    
%% Training tests and performance evaluation

if trained_status
    % simulate the network and plot the resulting errors
    outputs = sim(net,inputs,feedbackDelays);
    errors = gsubtract(targets,outputs);
    performance_open = perform(net,targets,outputs)

    % figures
    plot_outputOpen;
    plot_errorOpen;


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
    
    plot_trainPerform;
    plot_trainState;
    plot_trainRegression;
    
    plot_outputClosed;
    plot_errorClosed;
    pause(4)

    plot_netView;
    
    clear max_val max_index 

end

%% Save metadata, caches and matlab script
if (archive_net) && (trained_status)
   disp('Copying data, please wait...')
   currentFileName = 'NN_Modelling_v04.m';
   if (exist(currentFileName)==2)
       foldername = mlreportgen.utils.hash(string(datetime('now')));
       foldername = strcat("cache/", extractBefore(foldername,8));
       mkdir(foldername);
       copyfile(currentFileName, foldername);
       copyfile('cache/NN_model.mat',foldername);
       copyfile('cache/IO_data.mat',foldername);
       figHandles = findobj('Type', 'figure');
       for i=1:length(figHandles)
            figure(figHandles(i).Number);
            fig_name = figHandles(i).Name;
            fig_name(isspace(fig_name)==1)='_';
            fig_name = regexprep(fig_name, '[ .,''!?()]', '');
            fn = sprintf('%s/%s.eps',foldername,fig_name);
            export_fig(fn,figHandles(i))
       end
       gensim(net_closed,time_step);
       fn = sprintf('%s/narx_net.slx',foldername);
       save_system(gcs,fn)
       bdclose(gcs);
       pause(6);
       close all;
       fprintf("Data archived in %s\n",foldername)
   else
       dprintf('WARNING: %s does not exist!\n',currentFileName);
   end
else
    disp("WARNING: output NARX data not archived")
end