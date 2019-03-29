% %Plot system Mechanical Parameters
   figure
   fplot(Distance,[0 3])
   hold on
   fplot(Velocity,[0 3])
   hold on
   fplot(Acceleration/10,[0 3])
   title('Step Response of Closed Loop System Including PID Controller');
   xlabel('Time (s)');
   ylabel('Displacement, Velocity, Acceleration (m,m/s,m/(s^2)x10^+1');
%  
%  %Plot system Electrical Parameters
  figure
  %fplot(MotorV,[0 3])
  %hold on
  %fplot(MotorC,[0 3])
  %hold on
  %fplot(MotorP/10,[0 3])
  %hold on
  %fplot(MotorCE,[0 3])
  title('Step Response of Closed Loop System Including PID Controller');
  xlabel('Time (s)');
  ylabel('Voltage, Current, Power, Energy (V,A,Wx10+1, J');
  legend('Voltage', 'Current','Power');
 