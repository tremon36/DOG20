fs = 3.072e6;

input_matrix_us = readmatrix("sd_out.csv");

data_output = input_matrix_us(:,2);
sine_input = input_matrix_us(:,1);

figure,plot(data_output * 2^23);
hold on; 
plot(sine_input);

[A,B] = butter(3,20e3/(fs/2));
hold off;
figure, plot(filter(A,B,data_output));
hold on;

% FFT

f_v = (fs/2) * (0:(length(data_output)/2-1)) ./ (length(data_output)/2-1);
data_fft = 20*log10(abs(esph(data_output)));

figure,semilogx(f_v,data_fft);



