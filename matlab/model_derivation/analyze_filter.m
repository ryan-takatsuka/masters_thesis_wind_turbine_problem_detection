%% analyze_filter.m

%% Initialization
clear
close all
clc

%% analyze filter
% The filter parameters
n = 2;
wn = 0.2;

% Create the butterworth filter
[b, a] = butter(n, wn);

% Calculate the filter response
[h, w] = freqz(b, a);
[h_ma, w_ma] = freqz(ones(4,1)/4, 1);

% Plots
figure
plot(w/2/pi, mag2db(abs(h)), 'k', 'LineWidth', 2, ...
    'DisplayName', 'Butterworth IIR filter')
hold on
plot(w_ma/2/pi, mag2db(abs(h_ma)), 'k--', 'LineWidth', 2,...
    'DisplayName', 'Moving Average (window=4)')
xlabel('Normalized Frequency')
ylabel('Magnitude [dB]')
title('Filter frequency response')
legend('show')
grid on

% 
% figure
% plot(w_ma, mag2db(abs(h_ma)), 'k--', 'LineWidth', 2)
