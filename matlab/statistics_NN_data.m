close all; clc;
plt=0 ;

    T = targets; 
    
 t = cell2mat(T); 
 [ O N ]  = size(t)   % [ 1 100 ] 
 MSE00 = var(t',1); % 0.0633
 max(MSE00)
 zt = zscore(t',1)'; 
  
 plt=plt+1;
 figure(plt);
 subplot(211) 
 plot(t) 
 title('SIMPLENAR SERIES') 
 subplot(212) 
 plot(zt) 
 title('STANDARDIZED SERIES') 
  
 rng('default');
 n = randn(1,N); 
 L = floor(0.95*(2*N-1))  % 377 
 for i = 1:100 
     autocorrn            = nncorr( n,n, N-1, 'biased'); 
     sortabsautocorrn = sort(abs(autocorrn)); 
     thresh95(i)          = sortabsautocorrn(L); 
 end 
 sigthresh95 = mean(thresh95) %  0.1152
  
 autocorrt = nncorr(zt,zt,N-1,'biased'); 
 siglag95 = -1+ find(abs(autocorrn(N:2*N-1))>=sigthresh95) 
 

 plt = plt+1;
 figure(plt);
 hold on 
 plot(0:N-1, -sigthresh95*ones(1,N),'b--') 
 plot(0:N-1, zeros(1,N),'k') 
 plot(0:N-1,  sigthresh95*ones(1,N),'b--') 
 plot(cell2mat(autocorrt(N:2*N-1)))
 plot(cell2mat(autocorrt(N+siglag95)),'ro') 
 title('SIGNIFICANT SIMPLENAR AUTOCORRELATIONS') 

 % For NARNET choose an adequate positive subset of siglag95 
 net                             = narnet(1:2,10);            % default 
 [Xo,Xoi,Aoi,To]            = preparets(net,{},{},T); 
 [ net tr Yo Eo Xof Aof] = train(net,Xo,To,Xoi,Aoi); 
 view(net) 
%  Yo         = net(Xo,Xoi,Aoi); 
%   Eo        = gsubtract(To,Yo); 
  NMSEo = mse(Eo)/MSE00      % NMSEo = 1.151e-8 

to = cell2mat(To); 
yo = cell2mat(Yo); 
 plt = plt+1;
 figure(plt);
 hold on 
 plot(3:N, to, 'bo') 
 plot(3:N, yo, 'r.') 
 legend('target','output') 
 axis([ -1 101 0 1.25 ]) 
 title('SIMPLENAR SERIES MODEL') 