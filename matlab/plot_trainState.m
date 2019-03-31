%% Display setting and output setup
% set(0,'ShowHiddenHandles','on'); delete(get(0,'Children')); % close windows
scr = get(groot,'ScreenSize');                              % screen resolution
phi = (1 + sqrt(5))/2;
scr_ratio = phi/2.2;
offset = [ scr(3)/4 scr(4)/4]; 
fig_pos = [offset(1) offset(2) scr(3)*scr_ratio*.7 scr(4)*scr_ratio];
figTrainState =  figure('Position',fig_pos);

set(figTrainState,'numbertitle','off',...                            % Give figure useful title
        'name','NN training performance',...
        'Color','white');
    
% data
figTrainState = plottrainstate(TR);

fontName='CMU Serif';
fontSize = 28;
set(groot,'defaultAxesFontName', fontName,...
    'defaultTextFontName', fontName,...
    'DefaultAxesColor','none',...
    'FixedWidthFontName', 'ElroNet Monospace');

h3 = findobj(figTrainState,'-property','FontName');

for i=1:length(h3)
    h3(i).FontSize = fontSize;
    h3(i).FontName = fontName;
end

hold off

clear ax1 ax2 cmap fontName fontSize legend1 len line_thin line_thick marker_size
clear marker_spacing offset p_hi p_lo p_nominal phi r1 r2 r3 scr scr_ratio