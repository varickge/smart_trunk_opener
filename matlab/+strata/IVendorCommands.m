classdef IVendorCommands < handle
    properties (Hidden = true, SetAccess = private)
        h
    end

    methods
        function obj = IVendorCommands(handle)
            obj.h = handle;
        end

        function errors = getDetailedError(obj)
            payload = strata.wrapper_matlab(obj, 'vendorRead8', uint8(129), uint16(1), uint16(0), uint16(16));
            errors = strcat('0x', dec2hex(typecast(payload, 'int32'), 4));
        end

        function data = vendorRead8(obj, bRequest, wValue, wIndex, wLength)

            bRequest = strata.Conversion.toInt('uint8', bRequest);
            wValue = strata.Conversion.toInt('uint16', wValue);
            wIndex = strata.Conversion.toInt('uint16',wIndex);
            wLength = strata.Conversion.toInt('uint16', wLength);
            
            data = strata.wrapper_matlab(obj, 'vendorRead8', bRequest, wValue, wIndex, wLength);
        end

        function vendorWrite(obj, bRequest, wValue, wIndex)

            bRequest = strata.Conversion.toInt('uint8', bRequest);
            wValue = strata.Conversion.toInt('uint16', wValue);
            wIndex = strata.Conversion.toInt('uint16', wIndex);
            
            strata.wrapper_matlab(obj, 'vendorWrite', bRequest, wValue, wIndex);
        end

        function vendorWrite8(obj, bRequest, wValue, wIndex, data)

            bRequest = strata.Conversion.toInt('uint8', bRequest);
            wValue = strata.Conversion.toInt('uint16', wValue);
            wIndex = strata.Conversion.toInt('uint16', wIndex);
            data = typecast(data, 'uint8');
            
            strata.wrapper_matlab(obj, 'vendorWrite8', bRequest, wValue, wIndex, data);
        end
    end

end

