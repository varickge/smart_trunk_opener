function strata_testSpuFft(spu_helper, inputFormat, outputFormat)
    %Input signals (along columns)
    Fs = 1000;                    % Sampling frequency
    T = 1/Fs;                     % Sampling period
    L = 512;                     % Length of signal
    t = (0:L-1)*T;                % Time vector
    nSignals = 9;
    x = zeros(L, nSignals);
    for i=1:nSignals
        x(:,i) = cos(2*pi*50*i*t);
    end   
    
    %Do FFT using spu    
    nFFT =  L;
    offset = 1;
    dim = 2;
    if (nFFT == L) 
        settings.size = 0;
    else
        settings.size = nFFT;
    end
    settings.acceptedBins = 0;
    settings.window = strata.IfxRsp.FftWindow.NoWindow;
    settings.windowFormat = 0;
    settings.exponent = 0;
    settings.flags = 0;    
    y = spu_helper.doFft(x, inputFormat, settings, L, offset, dim, outputFormat);
 
    %Plot resulting FFT in the frequency domain
    fig_name = sprintf('Fft with: input-format= %d - output-format= %d', inputFormat, outputFormat);
    figure('Name', fig_name);
    for i=1:nSignals
        subplot(nSignals,1,i)
        title(['y ',num2str(i),' in the Frequency Domain'])
        hold on;
        
        %Aurix Fft
        fft_AURIX  = y(i,:)';
        P_AURIX = abs(fft_AURIX);
        plot(P_AURIX,'LineStyle','--','Marker','x')
        hold on;
        
        %Matlab fft
        inputSignal = x(:,i);
        fft_MATLAB = fft(inputSignal,nFFT)/nFFT;
        P_MATLAB = abs(fft_MATLAB);
        plot(P_MATLAB,'LineStyle','--','Marker','o')
        legend('FFT performed using AURIX', 'FFT performed using MATLAB');
        
        %Compare ffts
       d = abs(P_AURIX - P_MATLAB);
       if any(d > 1e-3)
            error('Fft result does not match the Matlab fft result ');
       end
    end
end

