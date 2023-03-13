classdef NamedRegister < handle
    % NamedRegister
    %   class providing named access to registers
    %   a handle class providing a register access with names
    %
    %   methods:
    %   output = read(obj, address, count)
    %   write(obj, address, value)
    %
    %   methods(Static):
    %   output = getClearBitMask(elementStruct)
    %   output = getElementValue(elementStruct, regVal)
    %   output = getValueBitMask(elementStruct, setValue)
    %   output = valueRangeCheck(elementStruct, setValue)
    
    properties (SetAccess = protected, GetAccess = public)
        registers       %handle of an IRegister object
        registerList    %handle of a regsterList object
    end
    
    methods
        function obj = NamedRegister(registers, json_file_name)
            % NamedRegister
            %   Construct an instance of this class
            obj.registers = registers;
            obj.registerList = strata.NamedRegister.RegisterList(json_file_name);
        end
        
        function output = read(obj, address, count)
            % read
            %   read given adddess
            %
            %   Usage:
            %   output = obj.read('TRIG0_CONF', 3)
            %   output = obj.read('AGC.PC0_GAIN')
            %   output = obj.read(0x0001)
            %   output = obj.read({'AGC', 'TRIG0_CONF',...})
            %
            %   Input:
            %   'address': one or more address or name register to read
            %
            %   Return value:
            %   'output':  values of the register
            
            if iscell(address)
                % create read batch list
                readBatchSize = length(address);
                readBatchList = cell(readBatchSize, 1);
                currentIndex = 1;
                % create output list
                outputVal = zeros(length(address), 1);
                outIndex = 1;
                for index = 1:length(address)
                    name = address{index};
                    [regStruct, elementStruct] = obj.registerList.find(name);
                    if isempty(elementStruct)
                        % simple read, so just add to batch list
                        readBatchList(currentIndex,:) = {regStruct.address};
                        currentIndex = currentIndex + 1;
                    else
                        % if there are some batch reads accumulated, execute them now to preserve the order,
                        % and clear the list
                        if (currentIndex > 1)
                            batchToRead = readBatchList(1: currentIndex - 1, 1);
                            readVals = obj.registers.readBatch(batchToRead);
                            newIndex = outIndex + length(readVals);
                            outputVal(outIndex:newIndex-1, 1) = readVals;
                            outIndex = newIndex;
                            % empty readbatch list
                            readBatchSize = readBatchSize - currentIndex - 1;
                            readBatchList = cell(readBatchSize, 1);
                            % reset index
                            currentIndex = 1;
                        end
                        % if element access is needed we have to read register and get element for the element
                        regVal = obj.registers.read(regStruct.address);
                        outputVal(outIndex, 1) = obj.getElementValue(elementStruct, regVal);
                        outIndex = outIndex + 1;
                    end
                end
                if currentIndex > 1
                    batchToRead = readBatchList(1: currentIndex - 1, 1);
                    % empty readbatch contains something readBatch
                    readVals = obj.registers.readBatch(batchToRead);
                    newIndex = outIndex + length(readVals);
                    outputVal(outIndex:newIndex-1, 1)= readVals;
                end
                output = outputVal;
            else
                [regStruct, elementStruct] = obj.registerList.find(address);
                if isempty(elementStruct)
                    if nargin == 3
                        output = obj.registers.read(regStruct.address, count);
                    else
                        output = obj.registers.read(regStruct.address);
                    end
                else
                    regVal = obj.registers.read(regStruct.address);
                    output = obj.getElementValue(elementStruct, regVal);
                end
            end
        end
        
        function write(obj, address, value)
            % write
            %   write value to given adddess
            %
            %   Usage:
            %   output = obj.write('TRIG0_CONF', '0x1111')
            %   output = obj.write(0x0001, '0x1111')
            %   output = obj.write('AGC.PC0_GAIN', 3)
            %   output = obj.write({'AGC.PC0_GAIN', 3; 'TRIG0_CONF', '0x1111';...})
            %
            %   Input:
            %   'address': an address or an array of address and value pairs to write
            %   'value': value to write, not used if address is a cell array
            
            if iscell(address)
                % max size of writeBatch
                writeBatchSize = length(address);
                writeBatchList = cell(writeBatchSize, 2);
                % index of where to add batch in the writeBatchList
                currentIndex = 1;
                for index = 1:length(address)
                    name = address{index, 1};
                    value = address{index, 2};
                    [regStruct, elementStruct] = obj.registerList.find(name);
                    if isempty(elementStruct)
                        % simple write, so just add to batch list
                        writeBatchList(currentIndex,:) = {regStruct.address, value};
                        currentIndex = currentIndex + 1;
                    else
                        % if there are some batch writes accumulated, execute them now to preserve the order,
                        % and clear the list
                        if (currentIndex > 1)
                            batchToWrite = writeBatchList(1:currentIndex-1, :);
                            obj.registers.writeBatch(batchToWrite, false)
                            writeBatchSize = writeBatchSize - currentIndex - 1;
                            writeBatchList = cell(writeBatchSize, 2);
                            currentIndex = 1;
                        end
                        % if element access is needed we have to read, modify, write for the element
                        if obj.valueRangeCheck(elementStruct, value)
                            valueBitMask = obj.getValueBitMask(elementStruct, value);
                            clearBitMask = obj.getClearBitMask(elementStruct);
                            obj.registers.modifyBits(regStruct.address, clearBitMask, valueBitMask);
                        end
                    end
                end
                if currentIndex > 1
                    % at the end if there are some batch writes accumulated execute them
                    batchToWrite = writeBatchList(1:currentIndex-1, :);
                    obj.registers.writeBatch(batchToWrite, false)
                end
            else
                [regStruct, elementStruct] = obj.registerList.find(address);
                if isempty(elementStruct)
                    obj.registers.write(regStruct.address, value);
                else
                    if obj.valueRangeCheck(elementStruct, value)
                        valueBitMask = obj.getValueBitMask(elementStruct, value);
                        clearBitMask = obj.getClearBitMask(elementStruct);
                        obj.registers.modifyBits(regStruct.address, clearBitMask, valueBitMask);
                    end
                end
            end
        end
    end
    
    methods(Static)
        function output = getClearBitMask(elementStruct)
            % getClearBitMask
            %   get clear bit mask of element of the register
            %
            %   Usage:
            %   output = obj.getClearBitMask(elementStruct)
            %
            %   Input:
            %   'elementStruct': structure array representing an element
            %
            %   Return value:
            %   'output': register value that bitmask the given element
            
            output = bitshift(bitshift(1, elementStruct.width) - 1, elementStruct.offset);
        end
        
        function output = getElementValue(elementStruct, regVal)
            % getElementValue
            %   get value of the element from a register value
            %
            %   Usage:
            %   output = obj.getElementValue(elementStruct, 0x1234)
            %
            %   Input:
            %   'elementStruct': structure array representing an element
            %
            %   Return value:
            %   'output': value of the element from given register value
            
            clearBitMask = strata.NamedRegister.NamedRegister.getClearBitMask(elementStruct);
            output = bitshift(bitand(regVal, clearBitMask), -1*elementStruct.offset);
        end
        
        function output = getValueBitMask(elementStruct, setValue)
            % getValueBitMask
            %   get bit mask of register to set the element to
            %
            %   Usage:
            %   output = obj.getValueBitMask(elementStruct, 3)
            %
            %   Input:
            %   'elementStruct': structure array representing an element
            %
            %   Return value:
            %   'output': register bitmaks to write the value of the element
            
            output = bitshift(bitand(setValue, (bitshift(1, elementStruct.width) - 1)), elementStruct.offset);
        end
        
        function output = valueRangeCheck(elementStruct, setValue)
            % valueRangeCheck
            %   check if the elemnt value is allowed from the
            %   desciption of the element structure
            %
            %   Usage:
            %   output = obj.valueRangeCheck(elementStruct, 3)
            %
            %   Input:
            %   'elementStruct': structure array representing an element
            %
            %   Return value:
            %   'output': true, if value is supported
            
            if isempty(elementStruct.enums)
                if bitshift(1, elementStruct.width) > setValue && setValue >= 0
                    output = true;
                    return
                end
            else
                for index = 1 : length(elementStruct.enums)
                    if elementStruct.enums(index).value == setValue
                        output = true;
                        return
                    end
                end
            end
            error('setValue not within supported range')
        end
    end
end
