%%%%
% nSignals: number of signals to be integrated
%%%
function strata_testSpuPsd(spu_helper)
    
    %Prepare input signals for Psd and expected Psd (using MATLAB)
    numOfSignals = 4;
    freq = 1000;
    Fs = 2*freq*numOfSignals;            % Sampling frequency
    T = 1/Fs;                            % Sampling period
    L = 8;                              % Length of signal
    t = (0:L-1)*T;                       % Time vector    
    window = rectwin(L);
    nFft = 128;
    for i=1:numOfSignals       
        S(i,:) = cos(2*pi*freq*i*t);        
        expected_psd(i, :) = (periodogram(complex(S(i,:)), window, nFft));
    end
    
    %Do PSD using spu
    actual_psd = spu_helper.doPsd(S, strata.DataFormat.ComplexQ31, nFft);

    %Plot results    
    fig_name = sprintf('Power Spectral density with: nfft = %d', nFft);
    figure('Name', fig_name);
    title(fig_name);

    f = Fs*(0:(nFft-1))/nFft;
    plot_i = 1;
    for i=1:numOfSignals
        subplot(numOfSignals,2,plot_i);
        plot(t, S(i,:))
        hold on
        xlabel('Time')
        ylabel('Magnitude')
        
        subplot(numOfSignals,2,plot_i + 1)
        hold on;
        %Scale Matlab-psd to match actual-psd (only mathches if divided by nFft * 2.5)
        expected_psd(i, :) = expected_psd(i, :)/nFft;
        plot(f, expected_psd(i,:), 'LineStyle','--','Marker','o')
        hold on;
        plot(f, actual_psd(i,:), 'LineStyle','--','Marker','x')
        legend('MATLAB', 'AURIX')
        xlabel('f (Hz)')
        ylabel('Psd')
        
        plot_i = plot_i + 2;
    end
end

