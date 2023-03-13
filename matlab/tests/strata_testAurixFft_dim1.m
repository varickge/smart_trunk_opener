%**************************************************************************
%                        IMPORTANT NOTICE
%**************************************************************************
% THIS SOFTWARE IS PROVIDED "AS IS". NO WARRANTIES, WHETHER EXPRESS,
% IMPLIED OR STATUTORY, INCLUDING, BUT NOT LIMITED TO, IMPLIED WARRANTIES
% OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE APPLY TO THIS
% SOFTWARE. INFINEON SHALL NOT, IN ANY CIRCUMSTANCES, BE LIABLE FOR SPECIAL,
% INCIDENTAL, OR CONSEQUENTIAL DAMAGES, FOR ANY REASON WHATSOEVER.
%**************************************************************************

close all
clearvars
clc

run('../addStrataPath.m')
addpath('spu') % Add SpuHelper class to path

%% connect to board and get access to its processing module
board = strata.Connection.withAutoAddress();
memory = board.getIMemory();
spu = board.getComponent('IProcessingRadar', 0);
spu_helper = SpuHelper(spu, memory);

% input signals
Fs   = 500;                                             % [1/s]     sampling frequency
T    = 1/Fs;                                            % [s]       sampling period

L    = 256;                                             % [1]       length (fft) input signal w/o zero padding
Fzp  = 4;                                               % [1]       zero padding factor, 1 for no zero padding
Lzp  = Fzp * L;                                         % [1]       length (fft) input signal w/ zero padding

tvec = (0:L-1)*T;                                       % [s]       time vector

xrnd = 0.25 + (1.0-0.25).*rand(1,8);                    % [1]       random signal amplitude {0.25,...,1}
frnd = 10.0 + (Fs/2-10.0).*rand(1,8);                   % [Hz]      random signal frequency {10,...,Fs/2}
x = zeros(8, L);
for i = 1:8
   x(i,:) = xrnd(i)*cos(2*pi*frnd(i)*tvec);    % [double]  (fft) input signal 
end

%Settings
fftSettings.size           = Lzp;                                	% [1]   length of FFT input vector after zero padding (multiple interger of power of 2); 0 - applying no zero padding. 
fftSettings.acceptedBins   = 0;                                 	% [1]   0 = disable rejection or depends on the fftFlags
fftSettings.window         = strata.IfxRsp.FftWindow.Hann;          % [1]   selecting a window function applying to time data before performing FFT; [NoWindow, Hann, Hamming, BlackmanHarris]
%fftSettings.window         = strata.IfxRsp.FftWindow.NoWindow;    	% [1]   selecting a window function applying to time data before performing FFT; [NoWindow, Hann, Hamming, BlackmanHarris]
fftSettings.windowFormat   = strata.DataFormat.Q31;
fftSettings.exponent       = 0;                                 	% [1]   number of shift left at the result (Gain)
fftSettings.flags          = 0;%strata.IfxRsp.FFT_FLAGS.DISCARD_HALF; % [1]   option for discarding (negative) half of the fft output ; [FFT_FLAGS_DISCARD_HALF, FFT_FLAGS_INPLACE].
inputFormat = strata.DataFormat.ComplexQ31;
outputFormat = strata.DataFormat.ComplexQ31;
offset = 1;
dim = 1;
y_AURIX = spu_helper.doFft(x, inputFormat, fftSettings, L, offset, dim, outputFormat);

%Get scaling factor
dataProperties.samples = L;
settings.fftSteps = 1;
settings.fftSettings = fftSettings;
w_scale_AURIX =  strata.IfxRsp.getScalingFactor(settings, dataProperties); 
y_AURIX_scaled = w_scale_AURIX*y_AURIX;

%scaling factor for matlab fft
if fftSettings.window == strata.IfxRsp.FftWindow.Hann
    window = hann(L);
elseif fftSettings.window == strata.IfxRsp.FftWindow.Hamming
    window = hamming(L);
else
    window = ones(L, 1);
end
w_weight = sum(window);
w_scale_MATLAB = 1/w_weight;

if fftSettings.flags == strata.IfxRsp.FFT_FLAGS.DISCARD_HALF
    fvec = (0:Fs/Lzp:Fs/2-Fs/Lzp);
    w_scale_MATLAB = 2 * w_scale_MATLAB;
else
    fvec = (-Fs/2:Fs/Lzp:Fs/2-Fs/Lzp);
    y_AURIX_scaled = fftshift(y_AURIX_scaled, 2);
end

%Plot resulting FFT in the frequency domain
for i = 1:8
    subplot(8,1,i)
    title(['y ',num2str(i),' in the Frequency Domain'])
    hold on;
    
    %FFT AURIX
    fft_AURIX = y_AURIX_scaled(i,:)';
    P_AURIX = abs(fft_AURIX);
    plot(fvec, P_AURIX, 'LineStyle', '--', 'Marker', 'x')
    hold on;
          
    %% FFT MATLAB
    inputSignal = x(i,:) .* window';
    fft_MATLAB = fft(inputSignal', Lzp);
    fft_MATLAB = fft_MATLAB * w_scale_MATLAB;
    if fftSettings.flags == strata.IfxRsp.FFT_FLAGS.DISCARD_HALF
        P_MATLAB = fft_MATLAB(1:Lzp/2);
    else
        P_MATLAB = fftshift(fft_MATLAB);
    end
    P_MATLAB = abs(P_MATLAB);
    plot(fvec, P_MATLAB, 'LineStyle','--', 'Marker', 'o')
    legend('FFT performed using AURIX', 'FFT performed using MATLAB');

    d = P_AURIX - P_MATLAB;
    if any(d > 1e-3)
        warning('Fft result do not match!');
    end
end
