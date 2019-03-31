        close all,  clc;
        plt=0;
          tic

        X = inputs(1); %[1x1500] cell
        T = targets(1);     %[1x1500] cell
         x  = cell2mat(X);
         t  = cell2mat(T);
         [ 1 N ] = size(X);           % [ 1 1500]
         [ O N ] = size(T);
        MSE00 = mean(var(t',1)) % 1.1197e+07
        MSE00a = mean(var(t',0)) %1.12041e+07
        %Normalization
        zx = zscore(cell2mat(X), 1);
        zt = zscore(cell2mat(T), 1);
            Ntrn = N-2*round(0.15*N)  
            trnind = 1:Ntrn
            Ttrn = T(trnind)
        Neq     = prod(size(Ttrn))     % 1500
        %Significant Lags were determined using the code at :
        %<http://www.mathworks.com/matlabcentral/newsreader/view_thread/341287#935393>
        %sigilag95: [0:517 520 521 524 525 636:1255 1345:1384] %Significant Input Lag
        %sigflag95: [0:348 411:1207 1321:1401]  %significant Feedback lag
        sigflags95 = [0     8     9    14    17    25    29    52    57    87   123]
        rng('default')
        % %  
        % %  
FD   = 1:2; %Random Selection of sigflag subset
ID   = 1:2; %Random selection of sigilag subset
   NFD  = length(FD)   % 
   NID  = length(ID)  %
MXFD  = max(FD)      
   MXID = max(ID)
Ntrneq = prod(size(t))
   %  Nw =  ( NID*I + NFD*O + 1)*H + ( H + 1)*O
   Hub     =  -1+ceil( (Ntrneq-O) / ((NID*I)+(NFD*O)+1))  
    Hmax    =  floor(Hub/10) %  
    Hmax = 2 ==>  Nseq >>Nw :
           Hmin    = 0
           dH      = 1
           Ntrials = 25
           j=0
           rng(4151941)
           for h = Hmin:dH:Hmax
              j = j+1
              if h == 0
                  net = narxnet( ID, FD, [] );
                  Nw =  ( NID*I + NFD*O + 1)*O
              else
                  net = narxnet( ID, FD, h );
                  Nw =  ( NID*I + NFD*O + 1)*h + ( h + 1)*O
              end
              Ndof            = Ntrn-Nw
              [ Xs Xi Ai Ts ] = preparets(net,X,{},T);
              ts              = cell2mat(Ts);
              xs              = cell2mat(Xs);
              MSE00s          = mean(var(ts',1))
              MSE00as         = mean(var(ts'))
              MSEgoal         = 0.01*Ndof*MSE00as/Neq
              MinGrad         = MSEgoal/10
              net.trainParam.goal      =  MSEgoal;
              net.trainParam.min_grad  =  MinGrad;
              net.divideFcn            =  'dividetrain';
              for i = 1:Ntrials
                  net            =  configure(net,Xs,Ts);
                  [ net tr Ys ]  =  train(net,Xs,Ts,Xi,Ai);
                  ys             =  cell2mat(Ys);
                  stopcrit{i,j}  = tr.stop;
                  bestepoch(i,j) = tr.best_epoch;
                  MSE            = mse(ts-ys);
                  MSEa           = Neq*MSE/Ndof;
                  R2(i,j)        = 1-MSE/MSE00s; 
                  R2a(i,j)       = 1-MSEa/MSE00as;
              end
           end
           stopcrit   =  stopcrit    %Min grad reached (for all).
           bestepoch  =  bestepoch
           R2         =  R2
           R2a        =  R2a
           Totaltime  =  toc