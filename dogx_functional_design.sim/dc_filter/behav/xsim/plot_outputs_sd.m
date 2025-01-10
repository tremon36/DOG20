fs=3.072e6;

%freqz(num,denom,[0:0.01:50],fs);
% Define input as 9 bit signed sine function

input_matrix_us = readmatrix("dc_filter_out.csv");

last_sample = length(input_matrix_us(:,1));%1747990;
first_sample = 1;%1517540;
clear input_matrix;
for i = 1:4 
    input_matrix(:,i) = input_matrix_us(first_sample:last_sample,i);
end

sine_sampled = input_matrix(1:length(input_matrix)-1,1);
sine_sampled_sd = input_matrix(1:length(input_matrix)-1,2);
intermediate_output = input_matrix(1:length(input_matrix)-1,4) / 2^23;
filter_output = intermediate_output; % Before there was an intermediate output. Now intermediate output and final output are the same

% Now do filter in double precision

num_filt = [1 -1];
denom_filt = [1 , -(2^16-1) / 2^16];

filtered_output_double = filter(num_filt,denom_filt,sine_sampled_sd);

% plot all


figure,plot(sine_sampled);
hold on;
plot(sine_sampled_sd);
grid on;
title("INPUT - CLEAN & MODULATED");
hold off;
figure,plot(intermediate_output);
grid on;
hold on;
plot(intermediate_output);
hold off;
title("OUTPUT");
figure, plot(intermediate_output);
title("INTERMEDIATE FILTER OUT");

mean1 = mean(double(intermediate_output(1:length(filter_output))));

f_v = (fs/2) * (0:(length(filter_output)/2-1)) ./ (length(filter_output)/2-1);
figure,semilogx(f_v,20*log10(abs(esph(filter_output))))%(length(filter_output)-65536:end)))));
title("FILTER OUTPUT FFT");
figure,semilogx(f_v,20*log10(abs(esph(double(sine_sampled_sd(1:length(filter_output)))))))%(length(filter_output)-65536:end))))));
title("INPUT SINE S-D FFT");
figure,semilogx(f_v,20*log10(abs(esph(double(intermediate_output(1:length(filter_output)))-mean1))))%(length(filter_output)-65536:end))))));
title("INTERMEDIATE FFT");
figure,semilogx(f_v,20*log10(abs(esph(double(filtered_output_double(1:length(filter_output)))))))%(length(filter_output)-65536:end))))));
title("DOUBLE PRECISION FILTER FFT");
%figure,semilogx(f_v,20*log10(abs(esph(d(length(vivado_output)-65536:end)))));
%hold on;
%semilogx(f_v,20*log10(abs(esph(x(length(vivado_output)-65536:end)))));

[A,B] = butter(3,30e3/(fs/2));
figure, plot(filter(A,B,filter_output));
title("FILTERED FINAL OUTPUT");
grid on;



