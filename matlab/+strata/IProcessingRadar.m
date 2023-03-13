classdef IProcessingRadar < handle
    properties (Hidden = true, SetAccess = private)
        h
    end

    methods
        function obj = IProcessingRadar(handle)
            obj.h = handle;
        end
        
        function configure(obj, dataSource, dataProperties, radarInfo, stages, antennaCal)
            dataSource = uint8(dataSource);
            
            dataProperties.format = strata.Conversion.toInt('uint8', dataProperties.format);
            dataProperties.rxChannels = strata.Conversion.toInt('uint8', dataProperties.rxChannels);
            dataProperties.ramps = strata.Conversion.toInt('uint16', dataProperties.ramps);
            dataProperties.samples = strata.Conversion.toInt('uint16', dataProperties.samples);
            dataProperties.channelSwapping = strata.Conversion.toInt('uint8', dataProperties.channelSwapping);
            dataProperties.bitWidth = strata.Conversion.toInt('uint8', dataProperties.bitWidth);

            radarInfo.txChannels = uint8(radarInfo.txChannels);
            radarInfo.virtualAnt = uint8(radarInfo.virtualAnt);
            radarInfo.rampsPerTx = uint16(radarInfo.rampsPerTx);
            radarInfo.maxRange = single(radarInfo.maxRange);
            radarInfo.maxVelocity = single(radarInfo.maxVelocity);

            stages = strata.IfxRsp.checkStages(stages);

            if nargin == 6
                for i = 1:size(antennaCal, 2)
                    antennaCal(i).spacing = single(antennaCal(i).spacing);
                    antennaCal(i).temperature = single(antennaCal(i).temperature);
                    antennaCal(i).fftSize = uint16(antennaCal(i).fftSize);
                    antennaCal(i).count = uint8(antennaCal(i).count);
                    antennaCal(i).indices = uint8(antennaCal(i).indices);                                        
                    antennaCal(i).coefficients = single(antennaCal(i).coefficients);
                end
                
                strata.wrapper_matlab(obj, 'configure', dataSource, dataProperties, radarInfo, stages, antennaCal);
            else
                strata.wrapper_matlab(obj, 'configure', dataSource, dataProperties, radarInfo, stages);
            end
        end

        function output = doFft(obj, input, fftSettings, samples, offset, dimension, format)
            input.size = uint32(input.size);
            input.baseAddress = strata.Conversion.toInt('uint32', input.baseAddress);
            input.stride = uint32(input.stride);
            input.rows = uint16(input.rows);
            input.cols = uint16(input.cols);
            input.pages = uint16(input.pages);
            input.format = uint8(input.format);

            fftSettings.size = uint16(fftSettings.size);
            fftSettings.acceptedBins = uint16(fftSettings.acceptedBins);
            fftSettings.window = uint8(fftSettings.window);
            fftSettings.windowFormat = uint8(fftSettings.windowFormat);
            fftSettings.exponent = uint8(fftSettings.exponent);
            fftSettings.flags = uint8(fftSettings.flags);

            samples = uint16(samples);
            offset = uint16(offset);
            dimension = uint8(dimension);
            format = uint8(format);

            output = strata.wrapper_matlab(obj, 'doFft', input, fftSettings, samples, offset, dimension, format);
        end
        
        function output = doNci(obj, input, format)
            input.size = uint32(input.size);
            input.baseAddress = strata.Conversion.toInt('uint32', input.baseAddress);
            input.stride = uint32(input.stride);
            input.rows = uint16(input.rows);
            input.cols = uint16(input.cols);
            input.pages = uint16(input.pages);
            input.format = uint8(input.format);
            
            format = uint8(format);
 
            output = strata.wrapper_matlab(obj, 'doNci', input, format);
        end
        
        function output = doThresholding(obj, input, dimension, thresholdingSettings)
            input.size = uint32(input.size);
            input.baseAddress = strata.Conversion.toInt('uint32', input.baseAddress);
            input.stride = uint32(input.stride);
            input.rows = uint16(input.rows);
            input.cols = uint16(input.cols);
            input.pages = uint16(input.pages);
            input.format = uint8(input.format);
            
            dimension = uint8(dimension);
            
            thresholdingSettings.spectrumExtension = logical(thresholdingSettings.spectrumExtension);
            thresholdingSettings.localMax.mode = uint8(thresholdingSettings.localMax.mode);
            if(thresholdingSettings.localMax.mode ~= strata.IfxRsp.LocalMaxMode.Disable)
                thresholdingSettings.localMax.threshold = uint32(thresholdingSettings.localMax.threshold);
                thresholdingSettings.localMax.windowWidth = uint8(thresholdingSettings.localMax.windowWidth);
                thresholdingSettings.localMax.combineAnd = logical(thresholdingSettings.localMax.combineAnd);
            end
            thresholdingSettings.cfarCa.algorithm = uint8(thresholdingSettings.cfarCa.algorithm);
            if(thresholdingSettings.cfarCa.algorithm ~= strata.IfxRsp.CfarCaAlgorithm.Disable)
                thresholdingSettings.cfarCa.guardCells = uint8(thresholdingSettings.cfarCa.guardCells);
                thresholdingSettings.cfarCa.windowCellsExponent = uint8(thresholdingSettings.cfarCa.windowCellsExponent);
                thresholdingSettings.cfarCa.cashSubWindowExponent = uint8(thresholdingSettings.cfarCa.cashSubWindowExponent);
                thresholdingSettings.cfarCa.betaThreshold = uint16(thresholdingSettings.cfarCa.betaThreshold);
            end
            thresholdingSettings.cfarGos.algorithm = uint8(thresholdingSettings.cfarGos.algorithm);
            if(thresholdingSettings.cfarGos.algorithm ~= strata.IfxRsp.CfarGosAlgorithm.Disable)
                thresholdingSettings.cfarGos.guardCells = uint8(thresholdingSettings.cfarGos.guardCells);
                thresholdingSettings.cfarGos.indexLead = uint8(thresholdingSettings.cfarGos.indexLead);
                thresholdingSettings.cfarGos.indexLag = uint8(thresholdingSettings.cfarGos.indexLag);
                thresholdingSettings.cfarGos.windowCells = uint8(thresholdingSettings.cfarGos.windowCells);
                thresholdingSettings.cfarGos.betaThreshold = uint16(thresholdingSettings.cfarGos.betaThreshold);
            end
            
            output = strata.wrapper_matlab(obj, 'doThresholding', input, dimension, thresholdingSettings);
        end
        
        function output = doPsd(obj, input, nFft)
            input.size = uint32(input.size);
            input.baseAddress = strata.Conversion.toInt('uint32', input.baseAddress);
            input.stride = uint32(input.stride);
            input.rows = uint16(input.rows);
            input.cols = uint16(input.cols);
            input.pages = uint16(input.pages);
            input.format = uint8(input.format);
            
            nFft = uint16(nFft);
            
            output = strata.wrapper_matlab(obj, 'doPsd', input, nFft);
        end
        
        function writeConfigRam(obj, offset, values)
            offset = strata.Conversion.toInt('uint16', offset);
            values = strata.Conversion.toInt('uint32', values);
            
            strata.wrapper_matlab(obj, 'writeConfigRam', offset, values);
        end

        function writeCustomWindowCoefficients(obj, slotNr, offset, coefficients)
            slotNr = strata.Conversion.toInt('uint8', slotNr);
            offset = strata.Conversion.toInt('uint16', offset);
            coefficients = strata.Conversion.toInt('uint32', coefficients);
            
            strata.wrapper_matlab(obj, 'writeCustomWindowCoefficients', slotNr, offset, coefficients);
        end

        function start(obj)
            strata.wrapper_matlab(obj, 'start');
        end

        function status = isBusy(obj)
            status = strata.wrapper_matlab(obj, 'isBusy');
        end

        function reinitialize(obj)
            strata.wrapper_matlab(obj, 'reinitialize');
        end

        function dataAddress = getDataAddress(obj)
            dataAddress = strata.wrapper_matlab(obj, 'getDataAddress');
        end

        function dataLength = getDataLength(obj)
            dataLength = strata.wrapper_matlab(obj, 'getDataLength');
        end
    end
end
