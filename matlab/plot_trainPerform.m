%% Display setting and output setup
% set(0,'ShowHiddenHandles','on'); delete(get(0,'Children')); % close windows
scr = get(groot,'ScreenSize');                              % screen resolution
phi = (1 + sqrt(5))/2;
scr_ratio = phi/3;
offset = [ scr(3)/4 scr(4)/4]; 
fig_pos = [offset(1) offset(2) scr(3)*scr_ratio scr(4)*scr_ratio];
figPerform =  figure('Position',fig_pos);

set(figPerform,'numbertitle','off',...                            % Give figure useful title
        'name','NN training performance',...
        'Color','white');
    
% data
figPerform = plotperform(TR);

fontName='CMU Serif';
fontSize = 28;
set(groot,'defaultAxesFontName', fontName,...
    'defaultTextFontName', fontName,...
    'DefaultAxesColor','none',...
    'FixedWidthFontName', 'ElroNet Monospace');

h2 = findobj('-property','FontName');

for i=1:length(h2)
    h2(i).FontSize = fontSize;
    h2(i).FontName = fontName;
end

set(figPerform.CurrentAxes.Legend,'Position',...
    [0.661679536679537 0.547140649149923 0.163610038610039 0.215610510046368]);

axtrainPerform = figPerform.CurrentAxes;
axtrainPerform.Position = FillAxesPos(axtrainPerform,0.99);

hold off

clear ax1 ax2 cmap fontName fontSize legend1 len line_thin line_thick marker_size
clear marker_spacing offset p_hi p_lo p_nominal phi r1 r2 r3 scr scr_ratio