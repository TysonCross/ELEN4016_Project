
% [inputs,feedbackDelays,layerStates,targets] =  preparets(net,in_data,{},target_data);
% net = narxnet(delayin,delaytarget,hiddenlayers);
% [net,TR] = train(net,inputs,targets,feedbackDelays,);

close all;
figTEST = figure();
plot(output,'r');
hold on
plot(in_NN_data,'b');


    input = [0;repmat(1,200,1)]
