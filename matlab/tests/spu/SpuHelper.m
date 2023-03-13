classdef SpuHelper < handle
    %SpuHelper do operations using the given spu-handler and spu-memory
    % - Load input signal into memory
    % - Do operation
    % - Read output-signal's data
    
    properties (Hidden = true, SetAccess = private)
        spu;
        memory;
        START_ADDRESS = '0xB9000000';
        memoryAlignemntBytes = 256/8;
    end
    
    methods
        function obj = SpuHelper(spu, memory)
            obj.spu = spu;
            obj.memory = memory;
        end
        
        function [stride, alignedData] = alignToMemory(obj, signal, data, elementSize)
            unalignedStride = signal.cols * elementSize;
            stride = obj.memoryAlignemntBytes * ceil(unalignedStride / obj.memoryAlignemntBytes);
            paddingCols = (stride - unalignedStride) / elementSize;
            alignedData = [data(:,:,:) zeros(signal.rows, paddingCols, signal.pages)];
        end
        
        %Load data into memory for processing by SPU
        function signal = loadSignal(obj, data, format)
            
            %Signal description
            signal.rows = size(data, 1);
            signal.cols = size(data, 2);
            signal.pages = size(data, 3);
            signal.format = format;
            signal.baseAddress = obj.START_ADDRESS;            
            
            %Prepare data in row-major order
            switch signal.format
                case strata.DataFormat.ComplexQ15
                    elementSize = 2 * 2;
                    [signal.stride, alignedData] = obj.alignToMemory(signal, data, elementSize);
                    rawData = cast(alignedData * 2^(16-1), 'int16');       % Casting and multiply by 2^(bits-1) to scale data to -1/+1
                    rawData = permute(rawData, [2 1 3]);                   % Converting from column-major-order to row-major-order
                    xReal = real(rawData);
                    xImag = imag(rawData);
                    rawData = reshape([xReal(:)'; xImag(:)'], [], 1);
                case strata.DataFormat.ComplexQ31
                    elementSize = 4 * 2;
                    [signal.stride, alignedData] = obj.alignToMemory(signal, data, elementSize);
                    rawData = cast(alignedData * 2^(32-1), 'int32');                      
                    rawData = permute(rawData, [2 1 3]);                           
                    xReal = real(rawData);
                    xImag = imag(rawData);
                    rawData = reshape([xReal(:)'; xImag(:)'], [], 1);
                case strata.DataFormat.Q15
                    elementSize = 2;
                    [signal.stride, alignedData] = obj.alignToMemory(signal, data, elementSize);
                    rawData = cast(alignedData * 2^(16-1), 'int16');                      
                    rawData = permute(rawData, [2 1 3]); 
                    rawData = rawData(:);
                case strata.DataFormat.Q31
                    elementSize = 4;
                    [signal.stride, alignedData] = obj.alignToMemory(signal, data, elementSize);
                    rawData = cast(alignedData * 2^(32-1), 'int32');                      
                    rawData = permute(rawData, [2 1 3]); 
                    rawData = rawData(:);                                                       
                otherwise
                    error('Invalid data format');
            end
            rawData = typecast(rawData, 'uint32');
            signal.size = signal.stride * signal.rows * signal.pages;
            
            %Write it to EMEM             
            obj.memory.write(signal.baseAddress, rawData);                                           
        end
        
        %Read signal's data and convert it to double
        function data = getData(obj, signal)            
            %Read raw-data from EMEM
            rawData = obj.memory.read(signal.baseAddress, signal.size/4);
            %Convert raw-data into double
            switch signal.format
                case strata.DataFormat.ComplexQ15
                    data = typecast(rawData, 'int16');
                    data = double(data) / 2^(16-1);
                    data = complex(data(1:2:end), data(2:2:end));
                    elementSize = 2*2;
                case strata.DataFormat.ComplexQ31
                    data = typecast(rawData, 'int32');
                    data = double(data) / 2^(32-1);
                    data = complex(data(1:2:end), data(2:2:end));
                    elementSize = 2*4;
                case strata.DataFormat.Q15
                    data = typecast(rawData, 'int16');
                    data = double(data) / 2^(16-1);
                    elementSize = 2;
                case strata.DataFormat.Q31
                    data = typecast(rawData, 'int32');
                    data = double(data) / 2^(32-1);
                    elementSize = 4;
                case strata.DataFormat.Bits
                    data = typecast(rawData, 'uint32');
                    data = de2bi(data,32);
                    data = data';
                    data = data(:);
                    signal.stride = signal.stride * 8;                     %convert from bytes to bits
                    elementSize = 1;                                       %each element is one bit
                otherwise
                    error('Invalid data format');                    
            end            
            %Raw-data is stored in row-major order and 
            %it shall be reshaped as follows:
            totalColumns = signal.stride/elementSize;                      %including padding bytes
            data = reshape(data, totalColumns, signal.rows, signal.pages);
            data = data';
            data = data(:,1:signal.cols,:);                                %discarding padding bytes            
        end
        
        function waitForSpu(obj)
            timeout = 1; % [s]
            tic;
            while obj.spu.isBusy()
                if toc > timeout
                    error('Timeout waiting for processing to finish.');
                end
            end
        end
        
        function result = doFft(obj, input, inputFormat, settings, samples, offset, dim, outputFormat)
            inputSignal = obj.loadSignal(input, inputFormat);
            outputSignal = obj.spu.doFft(inputSignal, settings, samples, offset, dim, outputFormat);
            obj.waitForSpu();
            result = obj.getData(outputSignal);
        end
        
        function result = doNci(obj, input, inputFormat, outputFormat)
            inputSignal = obj.loadSignal(input, inputFormat);
            outputSignal = obj.spu.doNci(inputSignal, outputFormat);
            obj.waitForSpu();
            result = obj.getData(outputSignal);
        end
        
        function result = doThresholding(obj, input, inputFormat, dim, settings)
            inputSignal = obj.loadSignal(input, inputFormat);
            outputSignal = obj.spu.doThresholding(inputSignal, dim, settings);
            obj.waitForSpu();
            result = obj.getData(outputSignal);
        end
        
        function result = doPsd(obj, input, inputFormat, nFft)
            inputSignal = obj.loadSignal(input, inputFormat);
            outputSignal = obj.spu.doPsd(inputSignal, nFft);
            obj.waitForSpu();
            result = obj.getData(outputSignal);
        end
    end
    
end

