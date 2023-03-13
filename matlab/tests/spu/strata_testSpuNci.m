%%%%
% nSignals: number of signals to be integrated
%%%
function strata_testSpuNci(spu_helper, nSignals, inputFormat, outputFormat)

    %Prepare input signals for NCI
    L = 128;                      % Length of signal
    t = (0:L-1)'/L;               % Time vector    
    maxAmplitude = 1/nSignals;    % Max signal amplitude
    signal = maxAmplitude * sin(2*pi*t);    
    x = repmat(signal,1,nSignals); 
    %x = x + 0.01*randn(L,nSignals);                                        %Add random noise to input signal
    x =  complex(x);
    
    %Calculate the expected NCI (using MATLAB)
    expected_nci = pulsint(x);                                             %pulseint does the square root of the sum of power of two of each element
    expected_nci = expected_nci.^2;                                        %undo the square root to match the NCI calculated by AURIX's SPU
    
    %Prepare input for Aurix-SPU's NCI
    nColumns = 8;                                                          %The Spu requires minimum 8 columns as input
    for i = 1:nColumns
        inputMatrix(:,i,:) = x;                                            %Same input-signals (along pages) for all columns     
    end
    
    %Do NCI using spu   
    actual_nci = spu_helper.doNci(inputMatrix, inputFormat, outputFormat);

    %Plot resulting NCI
    fig_name = sprintf('NCI with: input-format= %d - output-format= %d',inputFormat, outputFormat);
    figure('Name', fig_name);
    plot_i = 1;
    for i = 1:nColumns
        %Plot the first input-signal
        subplot(nColumns,2,plot_i)
        plot(abs(inputMatrix(:,1,1)));
        ylabel('Magnitude')
        title('Input Signal')
        
        %Plot the actual result (AURIX-SPU's NCI)
        subplot(nColumns,2,plot_i + 1)
        plot(actual_nci(:,1),'LineStyle','--','Marker','x')
        hold on;
        
        %Plot the expected result (MATLAB's NCI)
        plot(expected_nci,'LineStyle','--','Marker','o')
        legend('NCI performed using AURIX', 'NCI performed using MATLAB')
        ylabel('Magnitude')
        title('NCI result')
        
        %Compare NCIs
        d = abs(actual_nci(:,1) - expected_nci);
        if any(d(:) > 0.10*maxAmplitude)
            error('NCI does not match the expected value');
        end
        
        plot_i = plot_i + 2;
    end

end

