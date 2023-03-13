classdef IRadar < handle

    properties (Hidden = true, SetAccess = private)
        h
    end

    properties(SetAccess = protected)

    end

    methods

        function obj = IRadar(handle)
            obj.h = handle;
        end

        function reset(obj, softReset)
            if nargin == 1
                softReset = true;
            end
            strata.wrapper_matlab(obj, 'reset', softReset);
        end
        
        function initialize(obj)
            strata.wrapper_matlab(obj, 'initialize');
        end

        function configure(obj, c) % not implemented yet
            % include checkConfig from IRadarRxs
            strata.wrapper_matlab(obj, 'configure', c);
        end

        function loadSequence(obj, s) % not implemented yet
            % include checkConfig from IRadarRxs
            strata.wrapper_matlab(obj, 'loadSequence', s);
        end

        function calibrate(obj) % not implemented yet
            strata.wrapper_matlab(obj, 'calibrate');
        end

        function startSequence(obj) % not implemented yet
            strata.wrapper_matlab(obj, 'startSequence');
        end

        function enableConstantFrequencyMode(obj, txMask, txPower)
            % configure RxTx chain for constant frquency
            % 
            % txMask, bit mask enabling one or more Tx
            % txPower, Tx percent 0  - 100
            txMask = strata.Conversion.toInt('uint16', txMask);
            txPower = single(txPower); 
            
            strata.wrapper_matlab(obj, 'enableConstantFrequencyMode', txMask, txPower);
        end

        function setConstantFrequency(obj, frequency)
            strata.wrapper_matlab(obj, 'setConstantFrequency', double(frequency));
        end

        function index = getDataIndex(obj)
            index = strata.wrapper_matlab(obj, 'getDataIndex');
        end

    end
end
