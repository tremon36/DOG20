%% Input frequencies

Fs = 3.072e6;
Ts = 1/Fs;
Ft = 1e3;
sine_ampl = 40;
sine_offset = 0;

%% Bit amounts

nbfirstdiff = 9;
Nb_dec = 23;
Nb_filt = nbfirstdiff + Nb_dec;

%% Simulation length

n_periods = 1000; % Number of periods of the input ft
tsim = n_periods * 1 / Ft;
lsim = tsim / Ts;


%% Run simulation

out = sim('sigmadelta_dr.slx');

%% Compute FFTs

filter_output = double(out.filter(1536000:end)); % discard first 500 periods
sd_output = double(out.sd(1536000:end));
final_output = double(out.sd2(1536000:end));
simlength = length(out.filter(1536000:end));


freqs = (Fs / 2) * [0:simlength/2-1] ./ (simlength/2-1);
e_filter_output = 20 * log10(abs(esph(filter_output)));
e_sd = 20 * log10(abs(esph(sd_output)));

filter_output1 = double(out.filter1(1536000:end)); % discard first 500 periods
sd_output1 = double(out.sd1(1536000:end));
simlength1 = length(out.filter1(1536000:end));

freqs1 = (Fs / 2) * [0:simlength1/2-1] ./ (simlength1/2-1);
e_filter_output1 = 20 * log10(abs(esph(filter_output1)));
e_sd1 = 20 * log10(abs(esph(sd_output1)));

e_final_output = 20 * log10(abs(esph(final_output)));

%% Compute mean

mean_sd = mean(sd_output);
mean_filter = mean(filter_output);
mean_final = mean(e_final_output);


%% PLOT


%% PLOT

figure, plot(filter_output);
title("FILTER OUT");

figure, plot(final_output);
title("FINAL OUT");

[coef1,coef2] = butter(3,20e3/(Fs/2));
figure, plot(filter(coef1,coef2,filter_output1));
title("FINAL OUT FILTERED");

figure, plot(sd_output);
title("SIGMA-DELTA input");

figure, semilogx(freqs,e_sd);
title("SIGMA-DELTA input FFT");

figure, semilogx(freqs,e_filter_output);
title("FILTER OUTPUT FFT");

figure, semilogx(freqs,e_final_output);
title("FINAL OUTPUT FFT");
%% EXTRA

num = [1,-1];
denom = [1,-(2^16-1)/2^16];

% La diferencia calculada son 22.91 muestras para una frecuencia de
% entrad de 1 KHz. No parece que esto tenga un efecto notable sobre la
% continua o FFT, por lo que no se tiene en cuenta




