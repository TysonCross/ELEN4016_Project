m = 0.1
B =0.2
L = 0.6
R =5
Vs =-12:0.01:12
%u = 0.01

syms s;
num = 1;
den = sym2poly(B.*L.*s +((R.*m)./(L.*B)).*s.*s);
system = tf(num,den);
X = Vs*system
ilaplace(X);
%ss_system = tf2ss(system.num,system.den);

%system = tf([(B.*L),],[1])