function [pos] = FillAxesPos(ax,mult,offset)

if nargin <3
    offset = 0;
end

mult = mult*0.99;
outerpos = ax.OuterPosition;
ti = ax.TightInset; 
left = outerpos(1) + ti(1);
bottom = outerpos(2) + ti(2);
ax_width = outerpos(3) - ti(1) - ti(3);
ax_height = outerpos(4) - ti(2) - ti(4);
pos = [left+((1-mult)/2)+offset bottom+((1-mult)/2) ax_width*mult ax_height*mult];

end

