classdef BoardInstance < strata.BoardInstanceBase
    % This class represents an instance of a board
    %
    % BaseClass Functions:
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
    %
    % Extended BoardInstance functions:
    %    None

    methods
        function obj = BoardInstance(handle)
            obj@strata.BoardInstanceBase(handle);
        end
        
    end
end
