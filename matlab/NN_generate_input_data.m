% % Data generation for NN

V = [-100:0.5:100]';                                    % volts (input range)
t = linspace(0,10,length(V));                          % time series input

% NN parameters
b = f;
B2 = B;
B3 = B;
input = [t' V] %repmat(V,1,length(t));
output = 0;