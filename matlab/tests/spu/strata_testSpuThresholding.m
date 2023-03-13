function strata_testSpuThresholding(spu_helper, dim)
    %Input signal
    rows = 128;
    cols = 32;
    threshold = hex2dec('4000');
    thresholdScaled = (threshold + 1) / 2^(32-1); %convert to a value between -1.0 and 1.0
    x=zeros(rows,cols);
    x(1,     :) = thresholdScaled;
    x(rows/2,:) = thresholdScaled;
    x(rows,  :) = thresholdScaled;
        
    %Default settings
    thresholdingSettings.spectrumExtension     = 1;
    thresholdingSettings.localMax.mode         = strata.IfxRsp.LocalMaxMode.ThresholdOnly; %ThresholdOnly, LocalMaxOnly, Both, Disable
    thresholdingSettings.localMax.threshold    = threshold;
    thresholdingSettings.localMax.windowWidth  = 2;
    thresholdingSettings.localMax.combineAnd   = 0;
    
    thresholdingSettings.cfarCa.algorithm             = strata.IfxRsp.CfarCaAlgorithm.Disable; %Ca or Disable
    thresholdingSettings.cfarCa.guardCells            = 0;
    thresholdingSettings.cfarCa.windowCellsExponent   = 3;
    thresholdingSettings.cfarCa.cashSubWindowExponent = 3;
    thresholdingSettings.cfarCa.betaThreshold         = threshold;
    
    thresholdingSettings.cfarGos.algorithm     = strata.IfxRsp.CfarGosAlgorithm.Disable; %Gosca or Disable
    thresholdingSettings.cfarGos.guardCells    = 0;
    thresholdingSettings.cfarGos.windowCells   = 8;
    thresholdingSettings.cfarGos.indexLag      = 5;
    thresholdingSettings.cfarGos.indexLead     = 5;
    thresholdingSettings.cfarGos.betaThreshold = threshold;

    %Do Thresholding along every row
    inputFormat = strata.DataFormat.Q31;
    y = spu_helper.doThresholding(x, inputFormat, dim, thresholdingSettings);

    imagesc(y);
    y = double(y) .* thresholdScaled;
    if(~isequal(x,y))
        error('Thresholding does not match the expected value');
    end
end

