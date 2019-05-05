%% init
clear
close all
clc

%% create some frequency data
F_min = 2;
F_s = 128;
F_r = 4;
N_fft = 128;
N_b = 255;
D = F_s / 2 / F_r;

f_y = 3;

%% Design filter
b = filterDesign(F_s, N_b, F_r/2, F_r);
[h, f] = freqz(b, 1, 2^20, F_s);
h = abs(h);

%% Generate the signals
time = (0:1/F_s:N_fft*D/F_s)';
time_ds = time(1:D:end);
y = sin(f_y*2*pi*time) + 1e-2*randn(size(time));
y_ref = sin(F_min*2*pi*time);



%% Process the signal
y_window = zeros(N_b+1, 1);
y_ref_window = zeros(N_b+1, 1);
y_ds = [];
for i=1:D:length(time)-1
    y_window = [y_window(D+1:end); y(i:i+D-1)];    
    y_ref_window = [y_ref_window(D+1:end); y_ref(i:i+D-1)];
    temp = y_window' * (2*y_ref_window .* b');
    y_ds = [y_ds, temp];
end


%% Calculate the frequency transform
[freq, mag] = my_fft(time, y)
[freq_ds, mag_ds] = my_fft(time_ds, y_ds);
freq_ds = freq_ds + F_min;


%% Plots
figure
subplot(2,1,1)
hold on
plot(freq, mag, 'k', 'DisplayName', 'Standard FFT (N=2048)')
plot(freq_ds, mag_ds, 'r--', 'DisplayName', 'Zoom FFT result (N=128)')
set(gca, 'Yscale', 'log')
grid on
xlabel('Frequency [Hz]')
ylabel('Signal Strength')
title('Zoom FFT example')
legend('show')

subplot(2,1,2)
hold on
plot(freq, mag, 'k', 'DisplayName', 'Standard FFT (N=2048)')
plot(freq_ds, mag_ds, 'r--', 'DisplayName', 'Zoom FFT result (N=128)')
set(gca, 'Yscale', 'log')
grid on
xlabel('Frequency [Hz]')
ylabel('Signal Strength')
title('Zoomed in to the frequency range of the Zoom FFT')
legend('show')
xlim([1 7])


function b = filterDesign(Fs, N, Fpass, Fstop)
%FILTERDESIGN Returns a discrete-time filter object.

% MATLAB Code
% Generated by MATLAB(R) 9.4 and DSP System Toolbox 9.6.
% Generated on: 30-Apr-2019 23:36:04

% Equiripple Lowpass filter designed using the FIRPM function.

% All frequency values are in Hz.
% Fs = 128;  % Sampling Frequency
% 
% N     = 700  % Order
% Fpass = 1;   % Passband Frequency
% Fstop = 2;  % Stopband Frequency
Wpass = 10;   % Passband Weight
Wstop = 0.1;   % Stopband Weight
dens  = 20;  % Density Factor

% Calculate the coefficients using the FIRPM function.
b  = firpm(N, [0 Fpass Fstop Fs/2]/(Fs/2), [1 1 0 0], [Wpass Wstop], ...
    {dens});

% [EOF]
end

function [freq, fft_out] = my_fft(time, signal, varargin)
	% my_fft - This function calculates the DFT (discrete Fourier transform) of a signal.  This uses
	% MATLAB's native fft() function.
	%
	% Author: Ryan Takatsuka
	% Last Revision: 27-Feb-2019
	%
	% Syntax:
	%	[freq, fft_out] = my_fft(time, signal)
	%	[freq, fft_out] = my_fft(time, signal, 'Window', 'Blackman', 'Output', 'rms')
	%   
	% Inputs:
	%	time (vector): The time vector [seconds]
	%	signal (vector): The signal vector to be transformed to the frequency domain
	%
	% Outputs:
	%	freq (vector): Frequency vector [Hz]
	%	fft_out (vector): The DFT output that is in the specified output form
	%
	% Examples: 
	%	[freq, mag] = my_fft(time, signal);
	%	plot(freq, mag)
	% 	set(gca, 'Yscale', 'log')
	%
	%	This example calculates the FFT of the given signal and plots the response with a
	%	logarithmic scale for the magnitude vector.
	%
	% Notes:
	%	This function uses a windowing filter to calculate the DC components, which is more accurate
	%	than a standard FFT, but slower.
	%
	% Dependencies:
	%	fft, hamming, blackman
	%
	% For more information, see detailed documentation.
	
	% Input parsing
	p = inputParser;
	p.addOptional('Window', 'Blackman')
	p.addOptional('Output', 'rms')
	parse(p, varargin{:})
	
	if length(signal)/2 ~= floor(length(signal)/2)
		signal = signal(1:end-1);
	end
	
	% Design the window function
	if strcmp(p.Results.Window, 'None')
		w = ones(size(signal));
	elseif strcmp(p.Results.Window, 'Hamming')
		w = hamming(length(signal));
	elseif strcmp(p.Results.Window, 'Blackman')
		w = blackman(length(signal));
	else
		error('Not a valid window type!')
	end
	
	% Reshape the inputs
	signal = reshape(signal, [length(signal),1]);
	
	% Calculate the length of the signal
	N = length(signal);
	
	% Calculate the magnitude vector
	% FFT of the signal vector (magnitude of real and imaginary components
	mag = abs(fft(signal.*w));
	% Convert to a single-sided vector and fix factor of 2 scaling
	mag = mag(1:N/2+1);
	mag(2:end-1) = 2*mag(2:end-1);
	
	% Calculate the sampling frequency of the data
	Fs = 1/(mean(diff(time)));
	
	% Calculate the frequency vector for the data
	freq = transpose(Fs * (0:N/2) / N);
	freq_bin = freq(end) - freq(end-1);
	
	% Calculate window gain compensation
	K = sum(w);
	
	% Format the magnitude data in the output type
	if strcmp(p.Results.Output, 'rms')
		fft_out = mag / K;
	elseif strcmp(p.Results.Output, 'rms_db')
		fft_out = mag2db(mag / K);
	elseif strcmp(p.Results.Output, 'power')
		fft_out = mag.^2 / K;
	elseif strcmp(p.Results.Output, 'power_db')
		fft_out = pow2db(mag.^2 / K);
	elseif strcmp(p.Results.Output, 'power_density_db')
		fft_out = pow2db(mag.^2 / K / freq_bin);
	else
		error('Not a valid output type!')
	end

end