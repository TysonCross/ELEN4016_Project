Instructions
------------

ELEN4016 Control Project

Tyson Cross       1239448
James Goodhead    1387118

Matlab folder structure
-----------------------

    └── matlab
        ├── System_parameters.m                 <-- System parameters
        ├── Control_system_PID.m                <-- Main Control system setup and analysis (PID)
        ├── Model_Control_system_PID.slx        <-- PID controller simulink model 
        ├── Control_system_SS.slx               <-- Control system setup and analysis (State Space)
        ├── Model_Control_system_SS.m           <-- SS controller simulink model
        ├── Model_TransferFunction.slx          <-- Simulink system model (Transfer Function)
        ├── Model_StateSpace.slx                <-- Simulink system model (State Space)
        ├── Model_NARX.slx                      <-- Simulink system model (Neural Net)
        ├── NN_training.m                       <-- NARX Net training and caching setup (run to load NN)
        ├── NeuralNetUnitLDC_IO.slx             <-- BlackBox LDC system (load system parameters first)
        ├── NN_Blackbox_comparison.slx          <-- Comparison between Blackbox and NARX net
        ├── cache                               <-- Cache folder for NN
        │   ├── IO_data.mat                     <-- Input/Output data from Backbox for training NN
        │   └── NN_model.mat                    <-- Cached NN (can be trained or untrained)
        ├── FillAxesPos.m                       <-- Utility script
        ├── plot_errorClosed.m                  <-- Utility script
        ├── plot_errorOpen.m                    <-- Utility script
        ├── plot_netView.m                      <-- Utility script
        ├── plot_outputClosed.m                 <-- Utility script
        ├── plot_outputOpen.m                   <-- Utility script
        ├── plot_trainPerform.m                 <-- Utility script
        ├── plot_trainRegression.m              <-- Utility script
        ├── plot_trainState.m                   <-- Utility script

-----------------------------------------------------------------------------------------------------------

System modelling
----------------

Model_TransferFunction.slx models the LDC system using a transfer function found from the Laplace transform of a Newtonian/Lagrangian analysis of the LDC system. Please run 'Control_system_PID.m' first to load the system parameters, and the transfer function into the workspace.

'Model_StateSpace.slx' models the LDC system using the state space equations, found from the Lapace transforms of a Newtonian/Lagrangian analysis of the LDC system. Please run 'Control_system_SS.m' first to load the state space matrices into the workspace.

Model_NARX.m models the LDC system using a trained neural net, exported as a simulink model.


-----------------------------------------------------------------------------------------------------------

Control Systems
---------------

PID Control system:
This simulink file models the control system to move a conductive bar in an LDC motor system 1m from start to the end of rails. This is a nested loop structure with and inner and outer PID control loop. Please run 'Control_system_PID.m' first, and then open 'Control_system_PID.slx'. The system models input AGWN and accomodates a filter to reduce this external disturbance.

State Space Control system:
This simulink file models the control system to move a conductive bar in an LDC motor system 1m from start to the end of rails. This is an state space model, with an incomplete but functional observer controller. Please run 'Control_system_SS.m' first, and then open 'Control\_system\_SS.slx'.


-----------------------------------------------------------------------------------------------------------

Neural Net Training
-------------------

NARX net creation/caching/training:
'NN_modelling.m' is a script to create, control and/or train, or refine the training of a NARX net model. The script has individual control over various phases:

    use_cached_data = false;            % if false, generate new data
    use_cached_net = false;             % if false, generate new NARX net
    do_train = true;                    % if true, perform training
    recover_checkpoint = true;          % if training did not finish, use checkpoint
    archive_net = true;                 % archive NN, data and figures to subfolder
    make_images = true;                 % generate performance figures

The IO data, and the NN, are optionally cached and/or read from the /cache subfolder. If the archive_net option is set to true, then the training sessions' artifacts (such as figures, caches, simulink model of the NARX) are saved in a date-hashed sub-subfolder, beneath _/cache_.

NN/Blackbox comparison:
'NN_Blackbox_comparison.slx' compares the step response (or other input) of the lecturer-provided Blackbox system to the trained Neural Net's output. Please run 'System_parameters.m' first.


-----------------------------------------------------------------------------------------------------------

*Notes: I reccomend that you install Knuth's Computer Modern font family (from LaTeX) to match the intended display. These fonts can be downloaded from https://www.fontsquirrel.com/fonts/computer-modern


