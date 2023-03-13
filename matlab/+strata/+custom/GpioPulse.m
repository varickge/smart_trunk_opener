classdef GpioPulse

    properties (Hidden = true, SetAccess = private)
        protocol
    end

    methods
        function obj = GpioPulse(board)
            obj.protocol = board.getIVendorCommands();
        end
        
        function configure(obj, gpioId, count, duration, delay, period)
            bRequest = '0x30';  %CMD_CUSTOM
            wValue ='0x01';     %CMD_CUSTOM_GPIO_PULSE_CONFIGURE
            wIndex = gpioId;    %output pin
            parameters(1) = single(count);
            parameters(2) = single(duration);
            parameters(3) = single(delay);
            parameters(4) = single(period);
            obj.protocol.vendorWrite8(bRequest, wValue, wIndex, parameters);
        end
        
        function start(obj)
            bRequest = '0x30';  %CMD_CUSTOM
            wValue ='0x02';     %CMD_CUSTOM_GPIO_PULSE_START_STOP
            wIndex = 1;         %start
            obj.protocol.vendorWrite(bRequest, wValue, wIndex);
        end
        
        function stop(obj)
            bRequest = '0x30';  %CMD_CUSTOM
            wValue ='0x02';     %CMD_CUSTOM_GPIO_PULSE_START_STOP
            wIndex = 0;         %stop
            obj.protocol.vendorWrite(bRequest, wValue, wIndex);
        end
    end
end

