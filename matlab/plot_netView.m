%% Display setting and output setup
scr = get(groot,'ScreenSize');                              % screen resolution
phi = (1 + sqrt(5))/2;
scr_ratio = phi/4;
offset = [ scr(3)/4 scr(4)/4]; 
fig_pos = [offset(1) offset(2) scr(3)*scr_ratio*0.76 scr(4)*scr_ratio*0.5];
figNetView =  figure('Position',fig_pos);

set(figNetView,'numbertitle','off',...                            % Give figure useful title
        'name','NARX Net diagram',...
        'Color','white');
    
% data
jframe = view(net_closed);
jpanel = get(jframe,'ContentPane');
[~,h] = javacomponent(jpanel);
set(h, 'units','normalized', 'position',[0 0 1 1],...
    'BackgroundColor', [1 1 1],...
    'Clipping','off');
%# close java window
jframe.setVisible(false);
jframe.dispose();
