%% Display setting and output setup
scr = get(groot,'ScreenSize');                              % screen resolution
phi = (1 + sqrt(5))/2;
scr_ratio = phi/2.2;
offset = [ scr(3)/4 scr(4)/4]; 
fig_pos = [offset(1) offset(2) scr(3)*scr_ratio*.7 scr(4)*scr_ratio];
figReggression =  figure('Position',fig_pos);
fontName='CMU Serif';
fontSize = 20;

figReggression = plotregression(targets,outputs);
h1 = findobj(figReggression,'-property','FontName');

for i=1:length(h1)
    h1(i).FontSize = fontSize;
    h1(i).FontName = fontName;
end
 
hold off

clear ax1 ax2 cmap fontName fontSize legend1 len line_thin line_thick marker_size
clear marker_spacing offset p_hi p_lo p_nominal phi r1 r2 r3 scr scr_ratio