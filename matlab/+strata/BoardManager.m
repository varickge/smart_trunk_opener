classdef BoardManager < handle
    % BoardManager class to enumerate and create board instances
    %
    % Functions
    %     BoardManager - Create a BoardManager instance and define the
    %                    interfaces for enumerating boards
    %     enumerate - Enumerate (collect) all boards on the activated
    %                    interfaces
    %     createBoardInstance - Get one of the enumerated boards
    %     createSpecificBoardInstance - Get the board identified by the
    %                    provided UUID

    properties (Hidden = true, SetAccess = private)
        h
    end

    methods
        % Create a BoardManager instance and define the interfaces for
        % enumerating boards. The parameters are all optional. See their
        % description for the default values.
        % serial: Defines whether boards on the serial ports shall be
        %           enumerated, Default True
        % ethernet: Defines whether boards connected via ethernet shall be
        %           enumerated, Default True
        % usb: Defines whether boards on the USB ports shall be enumerated,
        %           Default True
        % wiggler: Defines whether boards on the wiggler interface shall be
        %           enumerated, Default False
        function obj = BoardManager(serial, ethernet, usb, wiggler)
            if nargin < 4
                wiggler = false;
            end
            if nargin < 3
                usb = true;
            end
            if nargin < 2
                ethernet = true;
            end
            if nargin < 1
                serial = true;
            end
            obj.h = strata.wrapper_matlab(obj, 'BoardManager', logical(serial), logical(ethernet), logical(usb), logical(wiggler));
        end
        
        % Enumerate (collect) all boards on the activated interfaces (see
        % constructor)
        % maxCount: Maximum number of boards to enumerate. If more boards
        %           are connected, they are ignored.
        % Returns The number of boards found on all active interfaces
        function count = enumerate(obj, maxCount)
            switch nargin
                case 1
                    count = strata.wrapper_matlab(obj, 'enumerate');
                case 2
                    count = strata.wrapper_matlab(obj, 'enumerate', uint16(maxCount));
                otherwise
                    error('Invalid number of arguments.');
            end
        end

        function delete(obj)
            strata.wrapper_matlab(obj, 'delete');
        end

        % Get one of the enumerated boards.
        % Which board will be returned depends on the number and type of
        % the provided parameters.
        % No parameter: The first unused board from the enumerated list
        % One numeric parameter: The board with the provided index in the
        %               enumerated list
        % One string parameter: The first unused board of a type specified
        %               by the provided name
        % Two numeric parameters: The first unused board of a type
        %               specified by the provided VID and PID
        % Returns the board instance if the specified board was found and
        %               is unused, otherwise throws an exception
        function board = createBoardInstance(obj, varargin)
            switch nargin
                case 1
                    board = strata.BoardInstance(strata.wrapper_matlab(obj, 'createBoardInstance'));
                case 2
                    if isnumeric(varargin{1})
                        board = strata.BoardInstance(strata.wrapper_matlab(obj, 'createBoardInstance', uint8(varargin{1})));
                    else
                        board = strata.BoardInstance(strata.wrapper_matlab(obj, 'createBoardInstance', varargin{1}));
                    end
                case 3
                    board = strata.BoardInstance(strata.wrapper_matlab(obj, 'createBoardInstance', uint16(varargin{1}), uint16(varargin{2})));
                otherwise
                    error('Invalid number of arguments.');
            end
        end

        % Get the board identified by the provided UUID
        % The UUID identifies only one board instance, even if there are
        % multiple boards of the same type.
        % uuid: The ID of the board to connect to
        % Returns the board instance if the specified board was found,
        %       otherwise throws an exception
        function board = createSpecificBoardInstance(obj, uuid)
            uuid = strata.Conversion.toInt('uint8', uuid);
            board = strata.BoardInstance(strata.wrapper_matlab(obj, 'createSpecificBoardInstance', uuid));
        end
    end
end
