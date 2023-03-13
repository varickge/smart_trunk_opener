classdef IData < handle
    properties (Constant)
        CHANNEL_SWAPPING_RX_MIRROR = (1)  % mirror: swap 0-3 and 1-2
        CHANNEL_SWAPPING_RX_FLIP   = (2)  % flip: swap 0-1 and 2-3
        CHANNEL_SWAPPING_TX_MIRROR = (3)  % mirror: swap 0-2 for 3TX, or 0-1 or 1-2 for 2TX
        
        FLAGS_LSB_FIRST   = (1)  % specifies whether LSB is transmitted first (otherwise MSB first)
        FLAGS_CRC_ENABLED = (2)  % enable transmission and check of CRC
    end

    properties (Hidden = true, SetAccess = private)
        h
    end

    methods
        function obj = IData(handle)
            obj.h = handle;
        end

        function configure(obj, index, properties, settings)
            if ~isfield(properties, 'rxChannels')
                properties.rxChannels = 0;
            end
            if ~isfield(properties, 'ramps')
                properties.ramps = 0;
            end
            if ~isfield(properties, 'samples')
                properties.samples = 0;
            end
            if ~isfield(properties, 'channelSwapping')
                properties.channelSwapping = 0;
            end
            if ~isfield(properties, 'bitWidth')
                properties.bitWidth = 0;
            end
            properties.format = strata.Conversion.toInt('uint8', properties.format);
            properties.rxChannels = strata.Conversion.toInt('uint8', properties.rxChannels);
            properties.ramps = strata.Conversion.toInt('uint16', properties.ramps);
            properties.samples = strata.Conversion.toInt('uint16', properties.samples);
            properties.channelSwapping = strata.Conversion.toInt('uint8', properties.channelSwapping);
            properties.bitWidth = strata.Conversion.toInt('uint8', properties.bitWidth);

            if isfield(settings, 'flags')
                % support for legacy structs
                settings = [settings.flags, 0, 0, 0];
            end
            settings = strata.Conversion.toInt('uint8', settings);

            strata.wrapper_matlab(obj, 'configure', uint8(index), properties, settings);
        end

        function calibrate(obj, index)
            strata.wrapper_matlab(obj, 'calibrate', uint8(index));
        end

        function start(obj, index)
            strata.wrapper_matlab(obj, 'start', uint8(index));
        end

        function stop(obj, index)
            strata.wrapper_matlab(obj, 'stop', uint8(index));
        end

        function result = getStatusFlags(obj, index)
            result = strata.wrapper_matlab(obj, 'getStatusFlags', uint8(index));
        end

        % Matlab convenience functions

        function isRequired = calibrationRequired(obj, index, dataRate)
            if(dataRate >= 200e6)
                isRequired = true;
            else
                isRequired = false;
            end
        end

    end
end
