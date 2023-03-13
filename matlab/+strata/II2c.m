classdef II2c < handle
    % This class provides access to the I2C bus.
    %
    % You can use different I2C buses, also 7 and 10 bit I2c addresses
    % are supported. The I2C_ADDR/I2C_10_BIT_ADDR functions convert the bus
    % ID and the device address to a I2C device ID understood by Strata.
    % You have to use these functions when you use 10 bit addressing or
    % have multiple I2C buses.
    %
    % You can read/write at most getMaxTransfer bytes in one call.
    % There are functions with and without prefixes.
    % In practice the prefix is often the address to read from/write to.
    % For example, a register or a location in EEPROM.
    %
    % II2c Functions:
    %    I2C_ADDR - Provides I2C device IDs to be used by the other functions
    %    I2C_10_BIT_ADDR - Provides 10 bit I2C device IDs to be used by the other functions
    %    getMaxTransfer - Maximum number of bytes that can be transferred
    %    readWith8BitPrefix
    %    readWith16BitPrefix
    %    readWithoutPrefix
    %    writeWith8BitPrefix
    %    writeWith16BitPrefix
    %    writeWithoutPrefix
    %    configureBusSpeed - Set the bus speed to Hz
    properties (Hidden = true, SetAccess = private)
        h
    end

    methods

        function obj = II2c(handle)
            obj.h = handle;
        end

        function i2cDevId = I2C_ADDR(obj, busId, devAddr)
            % Combines the I2C bus ID and the 7 bit I2C device address into a I2C device ID understood by Strata.
            % Use this together with the read/write functions.
            % For example:
            %   busId = 2;
            %   devAddr = hex2dec('58');
            %   bytesToRead = 12;
            %   i2c.readWithoutPrefix(i2c.I2C_ADDR(busId, devAddr), bytesToRead)
            %
            % busId: the I2C bus to use.
            %        Hand in 0 when your board only has one bus.
            % devAddr: the 7 bit I2C address of the device you want to
            %          communicate with via I2c
            % Note: If you have just one bus (busId = 0) then you do not
            %       need to use this function.
            busId = strata.Conversion.toInt('uint8', busId);
            devAddr = strata.Conversion.toInt('uint8', devAddr);
            i2cDevId = strata.wrapper_matlab(obj, 'I2C_ADDR', busId, devAddr);
        end

        function i2cDevId = I2C_10_BIT_ADDR(obj, busId, devAddr)
            % Combines the I2C bus ID and the 10 bit I2C device address into a I2C device ID understood by Strata.
            % Use this together with the read/write functions.
            % For example:
            %   busId = 2;
            %   devAddr = hex2dec('258');
            %   bytesToRead = 12;
            %   i2c.readWithoutPrefix(i2c.I2C_10_BIT_ADDR(busId, devAddr), bytesToRead)
            %
            % busId: the I2C bus to use.
            %        Hand in 0 when your board only has one bus.
            % devAddr: the 10 bit I2C address of the device you want to
            %          communicate with via I2c
            busId = strata.Conversion.toInt('uint8', busId);
            devAddr = strata.Conversion.toInt('uint16', devAddr);
            i2cDevId = strata.wrapper_matlab(obj, 'I2C_10_BIT_ADDR', busId, devAddr);
        end

        function maxTransfer = getMaxTransfer(obj)
            % Return the maximum number of bytes that can be read/written in one read/write call.
            % Note: If you want to transfer more bytes then you have to
            %       create multiple transfers with smaller chunks.
            maxTransfer = strata.wrapper_matlab(obj, 'getMaxTransfer');
        end

        function data = readWith8BitPrefix(obj, devAddr, prefix, length)
            % Read length bytes from the device with devAddr and send a 8 bit prefix first.
            % devAddr: the device to communicate with, can also be a device
            %          ID see I2C_ADDR and I2C_10_BIT_ADDR
            % prefix: 8 bit prefix, e.g. an 8 bit register address
            % length: number of bytes to read
            % Returns the values read
            devAddr = strata.Conversion.toInt('uint16', devAddr);
            prefix = strata.Conversion.toInt('uint8', prefix);
            length = strata.Conversion.toInt('uint16', length);
            
            data = strata.wrapper_matlab(obj, 'readWith8BitPrefix', devAddr, prefix, length);
        end

        function data = readWith16BitPrefix(obj, devAddr, prefix, length)
            % Read length bytes from the device with devAddr and send a 16 bit prefix first.
            % devAddr: the device to communicate with, can also be a device
            %          ID see I2C_ADDR and I2C_10_BIT_ADDR
            % prefix: 16 bit prefix, e.g. a 16 bit register address
            % length: number of bytes to read
            % Returns the values read
            devAddr = strata.Conversion.toInt('uint16', devAddr);
            prefix = strata.Conversion.toInt('uint16', prefix);
            length = strata.Conversion.toInt('uint16', length);
            
            data = strata.wrapper_matlab(obj, 'readWith16BitPrefix', devAddr, prefix, length);
        end

        function data = readWithoutPrefix(obj, devAddr, length)
            % Read length bytes from the device with devAddr without sending a prefix first.
            % devAddr: the device to communicate with, can also be a device
            %          ID see I2C_ADDR and I2C_10_BIT_ADDR
            % length: number of bytes to read
            % Returns the values read
            %
            % On some devices this reads from the current register.
            devAddr = strata.Conversion.toInt('uint16', devAddr);
            length = strata.Conversion.toInt('uint16', length);
            
            data = strata.wrapper_matlab(obj, 'readWithoutPrefix', devAddr, length);
        end

        function writeWith8BitPrefix(obj, devAddr, prefix, data)
            % Write data to the device with devAddr and send a 8 bit prefix first.
            % devAddr: the device to communicate with, can also be a device
            %          ID see I2C_ADDR and I2C_10_BIT_ADDR
            % prefix: 8 bit prefix, e.g. an 8 bit register address
            % data: the bytes to write to the device
            devAddr = strata.Conversion.toInt('uint16', devAddr);
            prefix = strata.Conversion.toInt('uint8', prefix);
            data = strata.Conversion.toInt('uint8', data);
            
            strata.wrapper_matlab(obj, 'writeWith8BitPrefix', devAddr, prefix, data);
        end

        function writeWith16BitPrefix(obj, devAddr, prefix, data)
            % Write data to the device with devAddr and send a 16 bit prefix first.
            % devAddr: the device to communicate with, can also be a device
            %          ID see I2C_ADDR and I2C_10_BIT_ADDR
            % prefix: 16 bit prefix, e.g. an 16 bit register address
            % data: the bytes to write to the device
            devAddr = strata.Conversion.toInt('uint16', devAddr);
            prefix = strata.Conversion.toInt('uint16', prefix);
            data = strata.Conversion.toInt('uint8', data);
            
            strata.wrapper_matlab(obj, 'writeWith16BitPrefix', devAddr, prefix, data);
        end

        function writeWithoutPrefix(obj, devAddr, data)
            % Write data to the device with devAddr without sending a prefix first.
            % devAddr: the device to communicate with, can also be a device
            %          ID see I2C_ADDR and I2C_10_BIT_ADDR
            % data: the bytes to write to the device
            %
            % On some devices this writes starting with the current
            % register.
            devAddr = strata.Conversion.toInt('uint16', devAddr);
            data = strata.Conversion.toInt('uint8', data);
            
            strata.wrapper_matlab(obj, 'writeWithoutPrefix', devAddr, data);
        end

        function configureBusSpeed(obj, devAddr, speed)
            % Set the bus speed for the bus that is used by devAddr to speed Hz.
            % This is always valid for the complete bus, so all connected devices must support it.
            % devAddr: the device to communicate with, can also be a device
            %          ID see I2C_ADDR and I2C_10_BIT_ADDR.
            % speed: specifies the bus speed in Hz
            devAddr = strata.Conversion.toInt('uint16', devAddr);
            speed = strata.Conversion.toInt('uint32', speed);
            
            strata.wrapper_matlab(obj, 'configureBusSpeed', devAddr, speed);
        end

    end

end
