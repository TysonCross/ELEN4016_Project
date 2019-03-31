%% Display setting and output setup
% set(0,'ShowHiddenHandles','on'); delete(get(0,'Children')); % close windows
scr = get(groot,'ScreenSize');                              % screen resolution
phi = (1 + sqrt(5))/2;
scr_ratio = phi/3;
offset = [ scr(3)/4 scr(4)/4]; 
fig_pos = [offset(1) offset(2) scr(3)*scr_ratio scr(4)*scr_ratio];
figErrorClosed =  figure('Position',fig_pos);
set(figErrorClosed,'numbertitle','off',...                            % Give figure useful title
        'name','Error between (closed net) NN output and target',...
        'Color','white');
fontName='CMU Serif';
fontSize = 28;
set(0,'defaultAxesFontName', fontName);                     % Make fonts pretty
set(0,'defaultTextFontName', fontName);
set(0,'DefaultAxesColor','none');                           % Transparent background
set(groot,'FixedWidthFontName', 'ElroNet Monospace')     

% data

y = [cell2mat(errors_closed)];
x = [t(1:length(y)).*time_step];

% Colors
cmap = colormap(lines);

line_thin = 2;
line_thick = 3;
marker_size = 8;
marker_spacing = 1000;
len = length(x);

% Draw plots
axErrorClosed = axes();

p_ErrorClosed = plot(x,y,...
    'Color', cmap(9,:),...
    'DisplayName','Error',...
	'LineStyle','-',...
	'LineWidth',line_thin);
hold on

% Axes and labels
set(axErrorClosed,'FontSize',fontSize,...
    'Color','none',...
    'Box','off',...
    'XAxisLocation','bottom',...
    'YMinorTick','on',...
    'XMinorTick','on',...
    'TickDir','both',...
    'Layer','top',...
    'LineWidth',line_thin,...
    'TickLabelInterpreter','latex');
set(axErrorClosed,...
    'Xlim',[ceil(min(min(x))) ceil(max(max(x)))],...
    'Ylim',[-0.75 0.4]);
hold on
xlabel('Time [s] \rightarrow',...
    'FontName',fontName,...
    'FontSize',fontSize);
ylabel('',...
    'FontName',fontName,...
    'FontSize',fontSize);

% Title and Annotations
abs_err = max(max(abs(y)));
str = sprintf('Max abs error: |%d|',abs_err);
t1 = title(str);

% Legend
% legend1 = legend;
% set(legend1,...
%      'Position',[0.404700326122332 0.210131556174964 0.233108108108108 0.132394109235202],...
%      'Box','off');
% hold on

% Adjust figure
axErrorClosed.Position = FillAxesPos(axErrorClosed,0.99);

hold off
clear axErrorClosed cmap fontName fontSize legend1 len line_thin line_thick marker_size
clear marker_spacing offset p_hi p_lo p_nominal phi r1 r2 r3 scr scr_ratio