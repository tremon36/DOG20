fs=3.072e6;

input_matrix = readmatrix("dc_filter_out.csv");

sine_1 = input_matrix(1:length(input_matrix)-1,1);
sine_2 = input_matrix(1:length(input_matrix)-1,2);
filter_1_input = input_matrix(1:length(input_matrix)-1,3);
filter_1_output = input_matrix(1:length(input_matrix)-1,4);

mixed_input = input_matrix(1:length(input_matrix)-1,5);
mixed_output = input_matrix(1:length(input_matrix)-1,6);
alpha = input_matrix(1:length(input_matrix)-1,7);

figure,plot(mixed_input / 2^23);
hold on;
plot(mixed_output);
plot(alpha*40);
title("OUTPUTS");

% Filter

[A,B] = butter(3,30e3/(fs/2));
filtered_mixed_output = filter(A,B,mixed_output);
figure, plot(filtered_mixed_output);

% Audiowrite

data_3 = mixed_output ./ (max(abs(mixed_output))+ 0.05);
audiowrite("converter_output.wav",data_3,fs);

mixed_output_end = mixed_output(floor(length(mixed_output)) * 0.8 : end); % only use last 20% of signal for fft, filter transition
f_v = (fs/2) * [0:length(mixed_output_end)/2-1] / (length(mixed_output_end)/2-1);
data_mixed_fft = 20*log10(abs(esph(mixed_output_end)));
figure, semilogx(f_v,data_mixed_fft);
title("MIXED OUTPUT FFT");