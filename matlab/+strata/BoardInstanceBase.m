classdef BoardInstanceBase < handle
    % This class represents an instance of a board.
    % It contains all base functionality common to all specific BoardInstances.
    %
    % BoardInstanceBase Functions:
    %    getVersion - Get the version of this board as string
    %    getIds - Get the VID and PID of this board
    %    getUuid - Get the unique identifier of this board
    %    setFrameListener - Register a listener to receive frames
    %    getFrame - Get the next received frame
    %    getIData - Get the interface for controlling the data transfer
    %    getIMemory - Get the interface for accessing memory
    %    getIGpio - Get the interface to acces GPIO pins
    %    getISpi - Get the interface to do SPI communication
    %    getII2c - Get the interface to do I2C communication
    %    getIVendorCommands - Get the vendor commands interface to do low level communication with the board
    %    getComponent - Get the component with the provided type and id
    %    getModule - Get the module with the provided type and id
    %    getBridgeSpecificInterface - Obtain the specific interface of a bridge to allow access to its implementation.

    properties (Hidden = true, SetAccess = private)
        h
    end

    methods
        function obj = BoardInstanceBase(handle)
            obj.h = handle;
        end

        function delete(obj)
            strata.wrapper_matlab(obj, 'delete');
        end

        function version = getVersion(obj)
            % Get the version of this board as string
            version = strata.wrapper_matlab(obj, 'getVersion');
        end

        function [vid, pid] = getIds(obj)
            % Get the VID and PID of this board
            [vid, pid] = strata.wrapper_matlab(obj, 'getIds');
        end

        function uuid = getUuid(obj)
            % Get the unique identifier of this board
            uuid = strata.wrapper_matlab(obj, 'getUuid');
        end

        function setFrameListener(obj, callbackFunction)
            % Register a listener to receive frames
            strata.wrapper_matlab(obj, 'setFrameListener', callbackFunction);
        end

        function [data, timestamp, virtualChannel] = getFrame(obj, timeout)
            % Get the next received frame
            switch nargin
                case 1
                    [data, timestamp, virtualChannel] = strata.wrapper_matlab(obj, 'getFrame');
                case 2
                    [data, timestamp, virtualChannel] = strata.wrapper_matlab(obj, 'getFrame', uint16(timeout));
                otherwise
                    error('invalid number of arguments');
            end
        end

        function IBridgeData = getIBridgeData(obj)
            % Get the interface to access the data bridge
            IBridgeData = strata.IBridgeData(strata.wrapper_matlab(obj, 'getIBridgeData'));
        end

        function IData = getIData(obj)
            % Get the interface for controlling the data transfer
            IData = strata.IData(strata.wrapper_matlab(obj, 'getIData'));
        end

        function IMemory = getIMemory(obj)
            % Get the interface for accessing memory
            IMemory = strata.IMemory(strata.wrapper_matlab(obj, 'getIMemory'), 'uint32', 'uint32');
        end

        function IGpio = getIGpio(obj)
            % Get the interface to access GPIO pins
            IGpio = strata.IGpio(strata.wrapper_matlab(obj, 'getIGpio'));
        end

        function ISpi = getISpi(obj)
            % Get the interface to do SPI communication
            ISpi = strata.ISpi(strata.wrapper_matlab(obj, 'getISpi'));
        end

        function II2c = getII2c(obj)
            % Get the interface to do I2C communication
            II2c = strata.II2c(strata.wrapper_matlab(obj, 'getII2c'));
        end

        function IVendorCommands = getIVendorCommands(obj)
            % Get the vendor commands interface to do low level communication with the board
            IVendorCommands = strata.IVendorCommands(strata.wrapper_matlab(obj, 'getIVendorCommands'));
        end

        function Component = getComponent(obj, type, id)
            handle = strata.wrapper_matlab(obj, 'getComponent', type, uint8(id)); %#ok<NASGU> used in eval()
            Component = eval(['strata.' type '(handle)']);
        end

        function Module = getModule(obj, type, id)
            handle = strata.wrapper_matlab(obj, 'getModule', type, uint8(id)); %#ok<NASGU> used in eval()
            Module = eval(['strata.' type '(handle)']);
        end

        function specificInterface = getBridgeSpecificInterface(obj, interfaceType)
            % Obtain the specific interface of a bridge to allow access to
            % its implementation.
            % interfaceType: The exact name of the interface to obtain
            % Returns the specific interface of the bridge or null if there
            %   is none.
            handle = strata.wrapper_matlab(obj, 'getBridgeSpecificInterface', interfaceType); %#ok<NASGU> used in eval()
            specificInterface = eval(['strata.' interfaceType '(handle)']);
        end

    end
end
