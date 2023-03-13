classdef IMemory < handle
    % This class provides memory accessing functionality.
    %
    % IMemory Functions:
    %    read - Reads the value at the given address
    %    write - Writes value(s) starting at the given address
    %    writeBatch - Writes single values at specific addresses
    %    setBits - Sets single bits at the given address
    %    clearBits - Clears single bits at the given address
    %    modifyBits - Sets and clears single bits at the given address
    properties (Hidden = true, SetAccess = private)
        h
    end

    properties (SetAccess = protected, GetAccess = public)
        AddressType
        ValueType
    end

    methods
        function obj = IMemory(handle, AddressType, ValueType)
            obj.h = handle;
            obj.AddressType = AddressType;
            obj.ValueType = ValueType;
        end

        function data = read(obj, address, count)
            % Reads the value at the given address
            % address: The address where to read
            % count (optional): The number of values to read
            % Returns the value(s) read
            address = strata.Conversion.toInt(obj.AddressType, address);
            if nargin == 3
                count = strata.Conversion.toInt(obj.AddressType, count);
                data = strata.wrapper_matlab(obj, 'read', address, count);
            else
                data = strata.wrapper_matlab(obj, 'read', address);
            end
        end

        function write(obj, address, data)
            % Writes value(s) starting at the given address
            % address: The address where to start writing
            % data: The value(s) to write
            address = strata.Conversion.toInt(obj.AddressType, address);
            data = strata.Conversion.toInt(obj.ValueType, data);

            strata.wrapper_matlab(obj, 'write', address, data);
        end

        function writeBatch(obj, data, optimize)
            % Writes single values at specific addresses
            % data: The values to write as matrix (list of
            % address-value-pairs)
            % optimize: Optional parameter specifying if writing shall be
            % optimized to increase performance. This can e.g. be sorting
            % the values by address. The default value is true.
            data = strata.Conversion.toInt(obj.AddressType, data);
            if nargin == 3
                strata.wrapper_matlab(obj, 'writeBatch', data, optimize);
            else
                strata.wrapper_matlab(obj, 'writeBatch', data);
            end
        end

        function setBits(obj, address, bitMask)
            % Sets single bits at the given address
            % address: The address of the value in memory to modify
            % bitMask: Value specifying which bits to set. 1 means set the bit, 0 means leave as is.
            address = strata.Conversion.toInt(obj.AddressType, address);
            bitMask = strata.Conversion.toInt(obj.ValueType, bitMask);

            strata.wrapper_matlab(obj, 'setBits', address, bitMask);
        end
        
        function clearBits(obj, address, bitMask)
            % Clears single bits at the given address
            % address: The address of the value in memory to modify
            % bitMask: Value specifying which bits to clear. 1 means clear the bit, 0 means leave as is.
            address = strata.Conversion.toInt(obj.AddressType, address);
            bitMask = strata.Conversion.toInt(obj.ValueType, bitMask);

            strata.wrapper_matlab(obj, 'clearBits', address, bitMask);
        end
        
        function modifyBits(obj, address, clearBitMask, setBitMask)
            % Sets and clears single bits at the given address
            % address: The address of the value in memory to modify
            % clearBitMask: Value specifying which bits to clear. 1 means clear the bit, 0 means leave as is.
            % setBitMask: Value specifying which bits to set. 1 means set the bit, 0 means leave as is.
            address = strata.Conversion.toInt(obj.AddressType, address);
            clearBitMask = strata.Conversion.toInt(obj.ValueType, clearBitMask);
            setBitMask = strata.Conversion.toInt(obj.ValueType, setBitMask);

            strata.wrapper_matlab(obj, 'modifyBits', address, clearBitMask, setBitMask);
        end
    end

end
