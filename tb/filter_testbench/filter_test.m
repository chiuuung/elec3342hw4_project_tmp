clear all; 
close all;

load info_wave.mat

x = double(x - 2048);
Fs=96000; % Sampling freq
Ts=1/Fs; % Sampling Period
length_t = length(x) * Ts; 
t=0:Ts:length_t;
t=t(1:length(x));
t=t';

%% Plot original signal
f = figure;
f.Position(3:4) = [1600 900];

subplot(1,2,1);
plot(t,x)
xlabel('Time (s)')
ylabel('Amplitude')
set(gca, 'xlim', [.061 .065])
title('Original signal (time domain)');

subplot(1,2,2);
spectrogram(x, 1024, 32, 1024, 'yaxis');
set(gca, 'clim', [0 60]);
title('Original signal (Spectrogram) pi rad/sp eq. Nyquist freq');

%% Filtering
x = x;% TODO: filter X

f = figure;
f.Position(3:4) = [1600 900];

subplot(1,2,1);
plot(t,x)
xlabel('Time (s)')
ylabel('Amplitude')
set(gca, 'xlim', [.061 .065])
title('Filtered signal (time domain)');

subplot(1,2,2);
spectrogram(x, 1024, 32, 1024, 'yaxis');
set(gca, 'clim', [0 60]);
title('Filtered signal (Spectrogram) pi rad/sp eq. Nyquist freq');

%% Downsampling - can be optional
downsample_n = 1; % TODO: adjust downsample factor
x = downsample(x, downsample_n);
Fs=96000/downsample_n; %% Sampling Frequency
Ts=1/Fs; %% Sampling Period
length_t = length(x) * Ts; 
t=0:Ts:length_t;
t=t(1:length(x));
t=t';

f = figure;
f.Position(3:4) = [1600 900];

subplot(1,2,1);
plot(t,x)
xlabel('Time (s)')
ylabel('Amplitude')
set(gca, 'xlim', [.061 .065])
title('Downsampled signal (time domain)');

subplot(1,2,2);
spectrogram(x, 128, 8, 128, 'yaxis');
set(gca, 'clim', [0 60]);
title('Downsampled signal (Spectrogram) pi rad/sp eq. Nyquist freq');