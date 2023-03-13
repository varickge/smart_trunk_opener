function scalingFactor = getScalingFactor(processingConfig, dataProperties, radarInfo)
    if (processingConfig.fftSteps > 2)
        error('scalingFactor(): invalid number of fftSteps.');
    end

    % caluclation scaling factor taking (a) internal scaling by length of 
    % fft input vector including zero padding, (b) windowing,  and (c) 
    % enabling/disabling of FFT_FLAGS_DISCARD_HALF option into account

    scalingFactor = 1;
    
    % get dimension of fft output vector and windowing weight acc. to 'range' dimension
    if processingConfig.fftSteps > 0
        samples = double(dataProperties.samples);
        RANGE_FFT_INPUT_SIZE = 2^nextpow2(samples);
                    
        if ((processingConfig.fftSettings(1).size == 0) || (processingConfig.fftSettings(1).size <= samples))
            % zero padding disabled
            RANGE_FFT_OUTPUT_SIZE = samples;
        else
            % zero padding enabled
            RANGE_FFT_OUTPUT_SIZE = processingConfig.fftSettings(1).size;               
        end
        RANGE_FFT_OUTPUT_SIZE = 2^nextpow2(RANGE_FFT_OUTPUT_SIZE);
        
        if bitand(processingConfig.fftSettings(1).flags, strata.IfxRsp.FFT_FLAGS.DISCARD_HALF)
            RANGE_FFT_OUTPUT_SIZE = RANGE_FFT_OUTPUT_SIZE / 2;
        end
        
        switch processingConfig.fftSettings(1).window
            case 1
                win_r = ones(samples, 1);
            case 2
                win_r = hann(samples);
            case 3
                win_r = hamming(samples);
            case 4
                win_r = blackmanharris(samples);
            otherwise
                error('Selected windowing function is not supported.');
        end
        win_r_weight = sum(win_r)/samples;
        
        scalingFactor = scalingFactor/win_r_weight;
        scalingFactor = scalingFactor.*(RANGE_FFT_OUTPUT_SIZE/RANGE_FFT_INPUT_SIZE);
    end

    % get dimension of fft output vector and windowing weight acc. to 'velocity' dimension
    if processingConfig.fftSteps > 1 
        rampsPerTx = double(radarInfo.rampsPerTx);
        VELOCITY_FFT_INPUT_SIZE = 2^nextpow2(rampsPerTx);
                    
        if ((processingConfig.fftSettings(2).size == 0) || (processingConfig.fftSettings(2).size <= rampsPerTx))
            % zero padding disabled
            VELOCITY_FFT_OUTPUT_SIZE = rampsPerTx;
        else
            % zero padding enabled
            VELOCITY_FFT_OUTPUT_SIZE = processingConfig.fftSettings(2).size;               
        end
        VELOCITY_FFT_OUTPUT_SIZE = 2^nextpow2(VELOCITY_FFT_OUTPUT_SIZE);
        
        if bitand(processingConfig.fftSettings(2).flags, strata.IfxRsp.FFT_FLAGS.DISCARD_HALF)
            VELOCITY_FFT_OUTPUT_SIZE = VELOCITY_FFT_OUTPUT_SIZE / 2;
        end
        
        switch processingConfig.fftSettings(2).window
            case 1
                win_v = ones(rampsPerTx, 1);
            case 2
                win_v = hann(rampsPerTx);
            case 3
                win_v = hamming(rampsPerTx);
            case 4
                win_v = blackmanharris(rampsPerTx);
            otherwise
                error('Selected windowing function is not supported.');
        end
        win_v_weight = sum(win_v)/rampsPerTx;    

        scalingFactor = scalingFactor/win_v_weight;
        scalingFactor = scalingFactor.*(VELOCITY_FFT_OUTPUT_SIZE/VELOCITY_FFT_INPUT_SIZE);
    end
end
