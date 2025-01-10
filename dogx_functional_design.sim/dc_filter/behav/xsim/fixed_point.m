
%clear all;
n_bits_shift = 16;

fs=3e6;
ft=10;

num = [1,-1];
denom = [1,-(2^n_bits_shift - 1) / 2^n_bits_shift];

%freqz(num,denom,[0:0.01:50],fs);
% Define input as 9 bit signed sine function

input_matrix = readmatrix("dc_filter_out.csv");

input = fix(input_matrix(1:length(input_matrix)-1,1)) / 64 + 5.65;
vivado_output = input_matrix(1:length(input_matrix)-1,2);

lsim=length(input);

%x=(1/2+1/2*sin(2*pi/fs*ft*(0:lsim-1)))*2^8 * 0.95;
x = input;

% Initialize variables as vectors with zeros
n = length(x); % Length of the simulation
c_d = zeros(1, n);
e_d = zeros(1, n);
f = zeros(1, n);
a = zeros(1, n);
b = zeros(1, n);
c = zeros(1, n);
d = zeros(1, n);
e = zeros(1, n);

% Assuming sine_1 is already defined as an input vector of length n
for ii = 1:n
    % Assign previous values (delayed feedback)
    if ii > 1
        c_d(ii) = c(ii - 1);
        e_d(ii) = e(ii - 1);
    else
        c_d(ii) = 0; % Initial condition
        e_d(ii) = 0; % Initial condition
    end
    
    % Compute the current values
    f(ii) = floor(e_d(ii)); % Use MATLAB's floor function
    a(ii) = x(ii);     % Current value of sine_1
    b(ii) = a(ii) - f(ii);
    c(ii) = b(ii) + c_d(ii);
    d(ii) = c(ii) - f(ii);
    e(ii) = d(ii) + e_d(ii);
end

fp_x = fi(f,1,9,0);
f_fe = f;

%lets do filter


%% USE FOR DOUBLE PRECISION

 b = zeros(size(x));
 c = zeros(size(x));
 
 d = zeros(size(x)); 
 e = zeros(size(x)); 
 
 f = zeros(size(x)); 
 g = zeros(size(x));
 
 h = zeros(size(x));

%% DOUBLE PRECISION END


 %lsim = 2 ^ 22;
 fs = 3e6;
 t = (1/fs) * (0:lsim-1);
 %x = round(128 * sin(2*pi*1.5*t)) + 30;
 x = f_fe;
 freqz(num,denom,[0:0.01:50],fs);

x(1) = 0;


for i= 2:lsim-1
    %d(i) = x(i) - x(i-1) + ((2^18-1)/ 2^18) * d(i-1);
    b(i) = x(i-1);
    c(i) = x(i) - b(i);
    e(i) = d(i-1);
    f(i) = e(i) * 2^n_bits_shift;
    g(i) = f(i) - e(i);
    h(i) = g(i) / 2^n_bits_shift; 
    d(i) = c(i) + h(i);
end

alg = [double(b),double(c),double(d),double(e),double(f),double(g),double(h)];

[b_f,c_f,d_f,e_f,f_f,g_f,h_f] = fixed_point_loop_mex(x,lsim);

alg_f = [double(b_f),double(c_f),double(d_f),double(e_f),double(f_f),double(g_f),double(h_f)];
ttf = filter(num,denom,x);

figure(2);
%plot(d);
title("comparison");
hold on;
plot(d);
plot(x);
%plot(ttf);
legend('d_f','x')
hold off;

%% FFTs

f_v = (fs/2) * (0:65536/2-1) / (65536/2-1);
%figure,semilogx(f_v,20*log10(abs(esph(vivado_output(length(vivado_output)-65536:end)))));
%figure,semilogx(f_v,20*log10(abs(esph(double(d_f(length(vivado_output)-65536:end))))));
%figure,semilogx(f_v,20*log10(abs(esph(d(length(vivado_output)-65536:end)))));
%hold on;
%semilogx(f_v,20*log10(abs(esph(x(length(vivado_output)-65536:end)))));

