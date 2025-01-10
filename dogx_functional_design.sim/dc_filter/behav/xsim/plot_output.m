fs = 3e6;
t = [0:length(input)-1] * 1/fs;
plot(t,input);
hold on;
plot(t,output);