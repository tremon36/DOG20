% function y=esph(x)
% %y=esph(x)
% 
% [a,b]=size(x);
% 
% if b>a
%     x=x';
% end
% 
% x = x/5;
% 
% y=fft(x.*hanning(length(x),'periodic'))/(length(x)/4);
% y=y(1:end/2);
% 
% % y=abs(y)/max(abs(y));

function [ v_fft ] = esph( v_s)

[a,b]=size(v_s);

if b>a
    v_s=v_s';
end


%FFT
%   Here the function receives a column vector and it's multiplied by a Hann window
%   Then the FFT is calculated

% length of the v_fft vector
N = length(v_s);
% in order to get correct values on the FFT the maximum v_s values is adjusted to 1.
v_fft = fft(v_s.*hanning(N,'periodic'))/(N/4);
v_fft = abs(v_fft(1:N/2));

end