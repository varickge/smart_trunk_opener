classdef IGpio < handle
    properties (Hidden = true, SetAccess = private)
        h
    end
    
    properties(Constant)
        % Values for GPIO name
        GPIO_NAME_NONE                  = 65535;
        GPIO_NAME                       = 32768;

        GPIO_NAME_RESET                 = 32768 + 1;
        GPIO_NAME_STANDBY               = 32768 + 2;
        GPIO_NAME_TRIGGER               = 32768 + 3;
        GPIO_NAME_STATUS                = 32768 + 4;

        GPIO_NAME_RESET_0               = 32768 + 1;
        GPIO_NAME_RESET_1               = 32768 + 16;
        GPIO_NAME_STATUS_0              = 32768 + 4;
        GPIO_NAME_STATUS_1              = 32768 + 17;

        % Values for GPIO config flags
        GPIO_FLAG_OUTPUT_INITIAL_HIGH   = 1;     % For output, set initial output value to 1 = otherwise it will be 0;
        GPIO_FLAG_OUTPUT_DRIVE_LOW      = 2;     % For output, drive a low signal
        GPIO_FLAG_OUTPUT_DRIVE_HIGH     = 4;     % For output, drive a high signal
        GPIO_FLAG_INPUT_ENABLE          = 8;     % Enable to read in signal
        GPIO_FLAG_PULL_UP               = 16;    % If the signal is not driven, pull it to high
        GPIO_FLAG_PULL_DOWN             = 32;    % If the signal is not driven, pull it to low

        % Values for GPIO config modes
        GPIO_MODE_INPUT                         = 8;
        GPIO_MODE_INPUT_PULL_DOWN               = 8 + 32;
        GPIO_MODE_INPUT_PULL_UP                 = 8 + 16;
        GPIO_MODE_OUTPUT_OPEN_DRAIN             = 2;
        GPIO_MODE_OUTPUT_OPEN_DRAIN_PULL_UP     = 2 + 16;
        GPIO_MODE_OUTPUT_OPEN_SOURCE            = 4;
        GPIO_MODE_OUTPUT_OPEN_SOURCE_PULL_DOWN  = 4 + 32;
        GPIO_MODE_OUTPUT_PUSH_PULL              = 2 + 4;
    end

    methods(Static)
        function id = GPIO_ID(port, pin)
            % #define GPIO_ID(port, pin) ((port << 8) | pin)
            port = strata.Conversion.toNumber(port);
            pin  = strata.Conversion.toNumber(pin);

            id = bitor(bitshift(port, 8), pin);
        end
    end


    methods

        function obj = IGpio(handle)
            obj.h = handle;
        end

        function configurePin(obj, id, flags)
            id    = strata.Conversion.toInt('uint16', id);
            flags = strata.Conversion.toInt('uint8', flags);

            strata.wrapper_matlab(obj, 'configurePin', id, flags);
        end

        function state = getPin(obj, id)
            id = strata.Conversion.toInt('uint16', id);

            state = strata.wrapper_matlab(obj, 'getPin', id);
        end

        function setPin(obj, id, state)
            id    = strata.Conversion.toInt('uint16', id);
            state = strata.Conversion.toBool(state);

            strata.wrapper_matlab(obj, 'setPin', id, state);
        end

        function configurePort(obj, id, flags, mask)
            id    = strata.Conversion.toInt('uint16', id);
            flags = strata.Conversion.toInt('uint8', flags);
            mask  = strata.Conversion.toInt('uint32', mask);

            strata.wrapper_matlab(obj, 'configurePort', id, flags, mask);
        end

        function state = getPort(obj, id)
            id = strata.Conversion.toInt('uint16', id);

            state = strata.wrapper_matlab(obj, 'getPort', id);
        end

        function setPort(obj, id, state, mask)
            id    = strata.Conversion.toInt('uint16', id);
            state = strata.Conversion.toInt('uint32', state);
            mask  = strata.Conversion.toInt('uint32', mask);

            strata.wrapper_matlab(obj, 'setPort', id, state, mask);
        end

    end
end
