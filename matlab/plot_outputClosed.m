%% Display setting and output setup
% set(0,'ShowHiddenHandles','on'); delete(get(0,'Children')); % close windows
scr = get(groot,'ScreenSize');                              % screen resolution
phi = (1 + sqrt(5))/2;
scr_ratio = phi/3;
offset = [ scr(3)/4 scr(4)/4]; 
fig_pos = [offset(1) offset(2) scr(3)*scr_ratio scr(4)*scr_ratio];
figOutputClosed =  figure('Position',fig_pos);
set(figOutputClosed,'numbertitle','off',...                            % Give figure useful title
        'name','Test output from NN and BlackBox (closed net)',...
        'Color','white');
fontName='CMU Serif';
fontSize = 28;
set(0,'defaultAxesFontName', fontName);                     % Make fonts pretty
set(0,'defaultTextFontName', fontName);
set(0,'DefaultAxesColor','none');                           % Transparent background
set(groot,'FixedWidthFontName', 'ElroNet Monospace')     

% data

y = [cell2mat(outputs_closed(TR.testInd));...
    cell2mat(targets_c(TR.testInd))];
x = [t(TR.testInd).*time_step];

% Colors
cmap = colormap(lines);

line_thin = 2;
line_thick = 3;
marker_size = 8;
marker_spacing = 1000;
len = length(x);

% Draw plots
axOutputClosed = axes();

p_OutputClosed = plot(x,y(1,:),...
    'Color', cmap(2,:),...
    'DisplayName','NN (open) output',...
	'LineStyle','--',...
	'LineWidth',line_thin);
hold on

p_OutputClosed2 = plot(x,y(2,:),...
    'Color', cmap(8,:),...
    'DisplayName','Target values from BB',...
	'LineStyle',':',...
	'LineWidth',line_thin);
hold on

% Axes and labels
set(axOutputClosed,'FontSize',fontSize,...
    'Color','none',...
    'Box','off',...
    'XAxisLocation','bottom',...
    'YMinorTick','on',...
    'XMinorTick','on',...
    'TickDir','both',...
    'Layer','top',...
    'LineWidth',line_thin,...
    'TickLabelInterpreter','latex');
set(axOutputClosed,...
    'Xlim',[ceil(min(min(x))) ceil(max(max(x)))],...
    'Ylim',[floor(min(min(y))) ceil(max(max(y)))]);
hold on
xlabel('Time [s] \rightarrow',...
    'FontName',fontName,...
    'FontSize',fontSize);
ylabel('Voltage [V] \rightarrow',...
    'FontName',fontName,...
    'FontSize',fontSize);

% Title and Annotations
% t1 = title(figOutputClosed.Name);

% Legend
legend1 = legend;
set(legend1,...
     'Position',[0.404700326122332 0.210131556174964 0.233108108108108 0.132394109235202],...
     'Box','off');
hold on

% Adjust figure
axOutputClosed.Position = FillAxesPos(axOutputClosed,0.99);
% ax2.Position = ax1.Position;
% set(gca,'Layer','bottom')
hold off

clear ax1 ax2 cmap fontName fontSize legend1 len line_thin line_thick marker_size
clear marker_spacing offset p_hi p_lo p_nominal phi r1 r2 r3 scr scr_ratio