classdef IBridgeData < handle
    properties (Hidden = true, SetAccess = private)
        h
    end

    methods

        function obj = IBridgeData(handle)
            obj.h = handle;
        end

        function setFrameBufferSize(obj, size)
            size = strata.Conversion.toInt('uint32', size);
            strata.wrapper_matlab(obj, 'setFrameBufferSize', size);
        end

        function setFrameQueueSize(obj, count)
            count = strata.Conversion.toInt('uint16', count);
            strata.wrapper_matlab(obj, 'setFrameQueueSize', count);
        end

        function clearFrameQueue(obj)
            strata.wrapper_matlab(obj, 'clearFrameQueue');
        end

        function startStreaming(obj)
            strata.wrapper_matlab(obj, 'startStreaming');
        end

        function stopStreaming(obj)
            strata.wrapper_matlab(obj, 'stopStreaming');
        end

    end
end
