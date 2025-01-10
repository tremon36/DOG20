Fs = 3.072e6;

input_matrix_us = readmatrix("data_out2.csv");

alpha = input_matrix_us(:,2);
data = input_matrix_us(:,1);

t = 1/Fs * [0:length(data)-1];

figure,plot(t,data);
hold on; 
plot(t,alpha*40);

[A,B] = butter(3,20e3/(Fs/2));
hold off;
figure, plot(t,filter(A,B,data));
hold on;
plot(t,alpha*40);

f_v = (Fs/2) * (0:(length(data)/2-1)) ./ (length(data)/2-1);
data_fft = 20*log10(abs(esph(data)));
figure,semilogx(f_v,data_fft);

%data_3 = data ./ (max(abs(data))+ 0.05);
%audiowrite("converter_output.wav",data_3,Fs);