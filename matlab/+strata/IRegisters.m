classdef IRegisters < handle
    properties (Hidden = true, SetAccess = protected)
        h
    end

    properties (SetAccess = protected, GetAccess = public)
        AddressType
        ValueType
        register_list
    end
    
    methods(Static)
        function saveRegisterList(registerList, varargin)
            % Store register list to a *.mat file.
            date_str = datestr(now, 'dd_mmm_yyyy_HH_MM_SS');
            if nargin > 1
                filename = [varargin{1}, '.mat'];
            else
                filename = ['RegisterList_', date_str, '.mat'];
            end
            save(filename, 'registerList', 'date_str');
        end
        
        function diffTable = compareRegisterLists(regList1, regList2)
            diff = ~strcmp(regList1.Content, regList2.Content);
            diffTable = regList1(diff, :);
            diffTable.Properties.VariableNames{3} = 'Content1';
            diffTable.Content2 = regList2.Content(diff);
        end
    end
   
    methods
        function obj = IRegisters(handle, AddressType, ValueType)
            obj.h = handle;
            obj.AddressType = AddressType;
            obj.ValueType = ValueType;
        end
        
        function address = toAddress(obj, regAddr)
            if ~isnumeric(regAddr) && ((regAddr(1) < '0') || (regAddr(1) > '9'))
                if isempty(obj.register_list)
                    error('XML Register Name List not found. Writing registers by name is not supported!');
                end
                regAddr = obj.register_list.Address{regAddr};
            end
            address = strata.Conversion.toInt(obj.AddressType, regAddr);
        end

        function val = read(obj, regAddr, count)
            regAddr = obj.toAddress(regAddr);
            if nargin == 3
                if length(regAddr) > 1
                    error('count can only be specified for a single read address');
                end
                count = strata.Conversion.toInt(obj.AddressType, count);
                val = strata.wrapper_matlab(obj, 'read', regAddr, count);
            else
                val = strata.wrapper_matlab(obj, 'read', regAddr);
            end
        end

        function write(obj, regAddr, val)
            if (length(regAddr) > 1) && (iscell(regAddr) || ~isa(regAddr, 'char'))
                % batch
                regVals = [obj.toAddress(regAddr(:, 1)), strata.Conversion.toInt(obj.ValueType, regAddr(:, 2))];
                if nargin == 3
                    optimize = val;
                    strata.wrapper_matlab(obj, 'writeBatch', regVals, optimize);
                else
                    strata.wrapper_matlab(obj, 'writeBatch', regVals);
                end
            else
                regAddr = obj.toAddress(regAddr);
                val = strata.Conversion.toInt(obj.ValueType, val);
               
                strata.wrapper_matlab(obj, 'write', regAddr, val);
            end
        end

        function setBits(obj, regAddr, bitmask)
            regAddr = obj.toAddress(regAddr);
            bitmask = strata.Conversion.toInt(obj.ValueType, bitmask);
            
            strata.wrapper_matlab(obj, 'setBits', regAddr, bitmask);
        end

        function clearBits(obj, regAddr, bitmask)
            regAddr = obj.toAddress(regAddr);
            bitmask = strata.Conversion.toInt(obj.ValueType, bitmask);
            
            strata.wrapper_matlab(obj, 'clearBits', regAddr, bitmask);
        end

        function modifyBits(obj, regAddr, clearBitmask, setBitmask)
            regAddr = obj.toAddress(regAddr);
            clearBitmask = strata.Conversion.toInt(obj.ValueType, clearBitmask);
            setBitmask = strata.Conversion.toInt(obj.ValueType, setBitmask);
            
            strata.wrapper_matlab(obj, 'modifyBits', regAddr, clearBitmask, setBitmask);
        end

        % Matlab convenience functions

        function writeVerify(obj, regAddr, value)
            regAddr = obj.toAddress(regAddr);
            value = strata.Conversion.toInt(obj.ValueType, value);
            
            obj.write(regAddr, value);
            verifyValue = obj.read(regAddr);

            if (value ~= verifyValue)
                warning('Read-back value does not match written value!');
            end
        end

        function registerList = getRegisterList(obj)
            % Reads all MMIC registers
            %
            % returns Table containing register address, default value and current content

            skipRegisters = {'CU_CALL_FIFO_REG'; 'CU_STATUS_FIFO_REG'};
            registerList = obj.register_list(~ismember(obj.register_list.Properties.RowNames, skipRegisters), :);

            count = height(registerList);
            Content = cell(count, 1);
            fprintf('  0%%');
            for i = 1 : count
                Content{i} = sprintf('0x%04X', obj.read(registerList.Address{i}));
                fprintf('\b\b\b\b%3d%%', round(100 * i / count));
            end
            fprintf('\n');
            
            registerList.Content = Content;
        end
        
        function map = getMemoryMap(obj, startAddress, stopAddress, skip)
            % Get memory dump of a specified memory region.
            %
            % startAddress First address of the memory area which should be dumped
            % stopAddress Last address of the memory area which should be dumped
            % skip Array of memory addresses which should be ignored
            %
            % returns cell array with two columns containing the dump in hexadecimal format

            startAddress = strata.Conversion.toNumber(startAddress);
            stopAddress = strata.Conversion.toNumber(stopAddress);
            if nargin < 4
                skip = [];
            else
                skip = strata.Conversion.toNumber(skip);
            end
            
            count = (stopAddress - startAddress + 2 - length(skip)) / 2;
            map = cell(count, 2);
            next = 1;
            for address = startAddress:2:stopAddress
                if ~any(skip == address)
                    map{next, 1} = sprintf('0x%04X', address);
                    map{next, 2} = sprintf('0x%04X', obj.read(address));
                    next = next + 1;
                end
            end
        end

        function loadRegisterInfo(obj, xmlFile)
            % Load register addresses and names from xml file.

            Names = {};
            Address = [];
            Default  = [];

            % Read xml file
            xDoc = xmlread(xmlFile);

            % Get register list
            addressBlockObj = xDoc.getElementsByTagName('addressblock');


            for addrBlockIdx = 0:addressBlockObj.getLength-1
                % Get base address of address block
                hexVal = char(addressBlockObj.item(addrBlockIdx).getAttribute('base'));
                regOffset = hex2dec(hexVal(3:end));

                % Get registers in address block
                registersObj = addressBlockObj.item(addrBlockIdx).getElementsByTagName('register');

                for registerIdx = 0:registersObj.getLength-1
                    registerObj = registersObj.item(registerIdx);

                    % Get name and address
                    name = char(registerObj.getElementsByTagName('name').item(0).getFirstChild.getData);
                    hexVal = char(registerObj.getElementsByTagName('address').item(0).getFirstChild.getData);
                    address = hex2dec(hexVal(3:end)) + regOffset;

                    % Determine default value through bitfields
                    bitfieldsObj = registerObj.getElementsByTagName('bitfields').item(0).getElementsByTagName('bitfield');
                    defaultValue = 0;
                    for bitfieldIdx = 0:bitfieldsObj.getLength-1
                        bitfieldObj = bitfieldsObj.item(bitfieldIdx);

                        position = str2double(char(bitfieldObj.getElementsByTagName('low').item(0).getFirstChild.getData));
                        resetValue = char(bitfieldObj.getElementsByTagName('reset_value').item(0).getFirstChild.getData);

                        % Check for different number formats
                        if (length(resetValue)) > 1
                            if resetValue(1:2) == '0b'
                                resetValue  = bin2dec(resetValue(3:end));
                            elseif resetValue(1:2) == '0x'
                                resetValue  = hex2dec(resetValue(3:end));
                            else
                                resetValue  = str2double(resetValue);
                            end
                        else
                            resetValue  = str2double(resetValue);
                        end

                        defaultValue = bitor(defaultValue, bitshift(resetValue, position));
                    end

                    Names{end+1, 1} = upper(name);
                    Address{end+1, 1} = sprintf('0x%04X', address);
                    Default{end+1, 1} = sprintf('0x%04X', defaultValue);
                end

            end

            obj.register_list = table(Address, Default, 'RowNames', Names);
        end

    end
end
