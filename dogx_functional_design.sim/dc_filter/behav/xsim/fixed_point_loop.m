function [b_f,c_f,d_f,e_f,f_f,g_f,h_f]= fixed_point_loop(x, lsim)
    % FIXED POINT PARAMETERS
    b_f = fi(zeros(size(x)), 1, 9, 0,'RoundMode','Fix'); 
    c_f = fi(zeros(size(x)), 1, 25, 16,'RoundMode','Fix');
    d_f = fi(zeros(size(x)), 1, 25, 16,'RoundMode','Fix'); 
    e_f = fi(zeros(size(x)), 1, 25, 16,'RoundMode','Fix');
    f_f = fi(zeros(size(x)), 1, 25, 16,'RoundMode','Fix'); 
    g_f = fi(zeros(size(x)), 1, 25, 16,'RoundMode','Fix');
    h_f = fi(zeros(size(x)), 1, 25, 16,'RoundMode','Fix'); 
    
    % INITIAL CONDITIONS
    x(1) = 0;

    
    % Compute frequency response (Optional, can be commented out)
    % freqz(num, denom, [0:0.01:50], fs); 
    
    % MAIN LOOP

    for i = 2:lsim-1
        b_f(i) = x(i-1);
        c_f(i) = x(i) - b_f(i);
        e_f(i) = d_f(i-1);
        f_f(i) = e_f(i) * 2^0;
        g_f(i) = f_f(i) - e_f(i)*(2^-16);
        h_f(i) = g_f(i) * 2^0;
        d_f(i) = c_f(i) + h_f(i);
    end

end
