function stages = checkStages(stages)
    stages.fftSteps = uint8(stages.fftSteps);
    stages.virtualChannels = uint8(stages.virtualChannels);
    % check parameters here: e.g. if stages.fftSteps > 2 ...
    if (stages.fftSteps > 0)
        if size(stages.fftSettings, 2) < stages.fftSteps
            error('invalid size of fftSettings');
        end
        stages.fftFormat = uint8(stages.fftFormat);
        if stages.fftSteps == 2
            stages.nciFormat = uint8(stages.nciFormat);
            if stages.nciFormat ~= strata.DataFormat.Q15 && stages.nciFormat ~= strata.DataFormat.Q31 && stages.nciFormat ~= strata.DataFormat.Disabled
                error('nciFormat can only be Disabled or Q15 or Q31!');
            end
        end
        for i = 1:stages.fftSteps
            stages.fftSettings(i).size = uint16(stages.fftSettings(i).size);
            stages.fftSettings(i).window = uint8(stages.fftSettings(i).window);
            stages.fftSettings(i).windowFormat = uint8(stages.fftSettings(i).windowFormat);
            stages.fftSettings(i).exponent = uint8(stages.fftSettings(i).exponent);
            stages.fftSettings(i).acceptedBins = uint16(stages.fftSettings(i).acceptedBins);
            stages.fftSettings(i).flags = uint8(stages.fftSettings(i).flags);
        end
        
        if (stages.fftSteps > 1)
            if (stages.nciFormat)
                stages.detectionSettings.maxDetections = uint16(stages.detectionSettings.maxDetections);
                if(stages.detectionSettings.maxDetections > 0)
                    stages.detectionSettings.fftSize = uint16(stages.detectionSettings.fftSize);
                    stages.detectionSettings.flags = uint8(stages.detectionSettings.flags);
                    for i = 1:2
                        stages.detectionSettings.thresholdingSettings(i).spectrumExtension = logical(stages.detectionSettings.thresholdingSettings(i).spectrumExtension);
                        stages.detectionSettings.thresholdingSettings(i).localMax.mode = uint8(stages.detectionSettings.thresholdingSettings(i).localMax.mode);
                        if(stages.detectionSettings.thresholdingSettings(i).localMax.mode ~= strata.IfxRsp.LocalMaxMode.Disable)
                            stages.detectionSettings.thresholdingSettings(i).localMax.threshold = uint32(stages.detectionSettings.thresholdingSettings(i).localMax.threshold);
                            stages.detectionSettings.thresholdingSettings(i).localMax.windowWidth = uint8(stages.detectionSettings.thresholdingSettings(i).localMax.windowWidth);
                            stages.detectionSettings.thresholdingSettings(i).localMax.combineAnd = logical(stages.detectionSettings.thresholdingSettings(i).localMax.combineAnd);
                        end
                        stages.detectionSettings.thresholdingSettings(i).cfarCa.algorithm = uint8(stages.detectionSettings.thresholdingSettings(i).cfarCa.algorithm);
                        if(stages.detectionSettings.thresholdingSettings(i).cfarCa.algorithm ~= strata.IfxRsp.CfarCaAlgorithm.Disable)
                            stages.detectionSettings.thresholdingSettings(i).cfarCa.guardCells = uint8(stages.detectionSettings.thresholdingSettings(i).cfarCa.guardCells);
                            stages.detectionSettings.thresholdingSettings(i).cfarCa.windowCellsExponent = uint8(stages.detectionSettings.thresholdingSettings(i).cfarCa.windowCellsExponent);
                            stages.detectionSettings.thresholdingSettings(i).cfarCa.cashSubWindowExponent = uint8(stages.detectionSettings.thresholdingSettings(i).cfarCa.cashSubWindowExponent);
                            stages.detectionSettings.thresholdingSettings(i).cfarCa.betaThreshold = uint16(stages.detectionSettings.thresholdingSettings(i).cfarCa.betaThreshold);
                        end
                        stages.detectionSettings.thresholdingSettings(i).cfarGos.algorithm = uint8(stages.detectionSettings.thresholdingSettings(i).cfarGos.algorithm);
                        if(stages.detectionSettings.thresholdingSettings(i).cfarGos.algorithm ~= strata.IfxRsp.CfarGosAlgorithm.Disable)
                            stages.detectionSettings.thresholdingSettings(i).cfarGos.guardCells = uint8(stages.detectionSettings.thresholdingSettings(i).cfarGos.guardCells);
                            stages.detectionSettings.thresholdingSettings(i).cfarGos.indexLead = uint8(stages.detectionSettings.thresholdingSettings(i).cfarGos.indexLead);
                            stages.detectionSettings.thresholdingSettings(i).cfarGos.indexLag = uint8(stages.detectionSettings.thresholdingSettings(i).cfarGos.indexLag);
                            stages.detectionSettings.thresholdingSettings(i).cfarGos.windowCells = uint8(stages.detectionSettings.thresholdingSettings(i).cfarGos.windowCells);
                            stages.detectionSettings.thresholdingSettings(i).cfarGos.betaThreshold = uint16(stages.detectionSettings.thresholdingSettings(i).cfarGos.betaThreshold);
                        end
                    end
                end
            end
            for i = 1:2
                stages.dbfSetting(i).angles = uint8(stages.dbfSetting(i).angles);
                if (stages.dbfSetting(i).angles)
                    stages.dbfSetting(i).coefficientFormat = uint8(stages.dbfSetting(i).coefficientFormat);
                    stages.dbfSetting(i).format = uint8(stages.dbfSetting(i).format);
                    stages.dbfSetting(i).centerAngle = single(stages.dbfSetting(i).centerAngle);
                    stages.dbfSetting(i).angularSpacing = single(stages.dbfSetting(i).angularSpacing);
                    stages.dbfSetting(i).thresholding.spectrumExtension = logical(stages.dbfSetting(i).thresholding.spectrumExtension);
                    stages.dbfSetting(i).thresholding.localMax.mode = uint8(stages.dbfSetting(i).thresholding.localMax.mode);
                    stages.dbfSetting(i).thresholding.localMax.threshold = uint32(stages.dbfSetting(i).thresholding.localMax.threshold);
                    stages.dbfSetting(i).thresholding.localMax.windowWidth = uint8(stages.dbfSetting(i).thresholding.localMax.windowWidth);
                    stages.dbfSetting(i).thresholding.localMax.combineAnd = logical(stages.dbfSetting(i).thresholding.localMax.combineAnd);
                    stages.dbfSetting(i).thresholding.cfarCa.algorithm = uint8(stages.dbfSetting(i).thresholding.cfarCa.algorithm);
                    stages.dbfSetting(i).thresholding.cfarCa.guardCells = uint8(stages.dbfSetting(i).thresholding.cfarCa.guardCells);
                    stages.dbfSetting(i).thresholding.cfarCa.windowCellsExponent = uint8(stages.dbfSetting(i).thresholding.cfarCa.windowCellsExponent);
                    stages.dbfSetting(i).thresholding.cfarCa.cashSubWindowExponent = uint8(stages.dbfSetting(i).thresholding.cfarCa.cashSubWindowExponent);
                    stages.dbfSetting(i).thresholding.cfarCa.betaThreshold = uint16(stages.dbfSetting(i).thresholding.cfarCa.betaThreshold);
                    stages.dbfSetting(i).thresholding.cfarGos.algorithm = uint8(stages.dbfSetting(i).thresholding.cfarGos.algorithm);
                    stages.dbfSetting(i).thresholding.cfarGos.guardCells = uint8(stages.dbfSetting(i).thresholding.cfarGos.guardCells);
                    stages.dbfSetting(i).thresholding.cfarGos.indexLead = uint8(stages.dbfSetting(i).thresholding.cfarGos.indexLead);
                    stages.dbfSetting(i).thresholding.cfarGos.indexLag = uint8(stages.dbfSetting(i).thresholding.cfarGos.indexLag);
                    stages.dbfSetting(i).thresholding.cfarGos.windowCells = uint8(stages.dbfSetting(i).thresholding.cfarGos.windowCells);
                    stages.dbfSetting(i).thresholding.cfarGos.betaThreshold = uint16(stages.dbfSetting(i).thresholding.cfarGos.betaThreshold);
                end
            end
        end
    end
end
