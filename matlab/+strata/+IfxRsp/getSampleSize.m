function sampleSize = getSampleSize(format)
    switch format
        case strata.DataFormat.Q15
            sampleSize = 2;
        case strata.DataFormat.Q31
            sampleSize = 4;
        case strata.DataFormat.ComplexQ15
            sampleSize = 4;
        case strata.DataFormat.ComplexQ31
            sampleSize = 8;
        otherwise
            error('Given format is not supported.');
    end
end
