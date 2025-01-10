fs = 3.072e6;
lsim = length(intermediate_output);
tsim = 1/fs*(lsim-1);

Nbvco=4 % Number of bits VCO counter
Nvco=2^Nbvco;
NP=Nvco;
Nbext=5; %Number of bits of extra counter
NbC1=Nbvco+Nbext % Number of bits of first counter C1
NC1=2^NbC1;
NbDiff1 = NbC1; %number of bits of differential canceling diff output
NbDiff2 = NbC1; %number of bits of feedback loop difference
prc = 6;

Nbsd=Nbvco+Nbext % Number of bits of SD quantizer
Nsd=2^Nbsd;
Nbdcoext=3; % Number of bits of DCO ALU
Nbdco=Nbsd+Nbdcoext % Number of bits DCO counter
Ndco=2^Nbdco;

n_shift = Nbdcoext; % eliminate extra bits
nbfirstdiff = NbC1; %number of bits of first difference output

% Filter parameters
Nb_dec = 14;
Nb_filt = nbfirstdiff + Nb_dec;
exp_filt = 16;

tv = [0:lsim-1].*1/fs;
inputv = sine_sampled_sd;

sim("Sigma_delta_2023.slx");

f_v = (fs/2) * (0:(length(filter_output)/2-1)) ./ (length(filter_output)/2-1);
figure,semilogx(f_v,20*log10(abs(esph(double(intermediate_output(1:length(filter_output)))))))%(length(filter_output)-65536:end))))));
title("INTERMEDIATE FFT");
hold on;
semilogx(f_v,20*log10(abs(esph(double(output)))));%(length(filter_output)-65536:end)))));

