classdef Connection

    methods(Static)
        function checkBoardVersion(board)
            verBoard = board.getVersion();
            disp(['Board Image Version: ' verBoard]);
        end

        function board = withSerialPort(port)
            board = strata.BoardSerial.createBoardInstance(port);

            strata.Connection.checkBoardVersion(board);
        end

        function board = withEthernetIp(ipAddress)
            board = strata.BoardEthernet.createBoardInstance(ipAddress);

            strata.Connection.checkBoardVersion(board);
        end

        function board = withUsbIds(vid, pid)
            board = strata.BoardUsb.createBoardInstance(vid, pid);

            strata.Connection.checkBoardVersion(board);
        end

        function board = withAnyIds(vid, pid)
            board = strata.BoardAny.createBoardInstance(vid, pid);

            strata.Connection.checkBoardVersion(board);
        end

        function board = withEnumeration(serial, ethernet, usb)
            if nargin < 3
                usb = true;
            end
            if nargin < 2
                ethernet = true;
            end
            if nargin < 1
                serial = true;
            end
            boardManager = strata.Connection.enumerate(serial, ethernet, usb);
            board = boardManager.createBoardInstance();
            strata.Connection.checkBoardVersion(board);
        end

        function board = withAutoAddress(address)
            if nargin == 0
                address = [];
                %address = 'COM3';
                %address = [169, 254, 1, 101];
            end
            if ischar(address)
                board = strata.Connection.withSerialPort(address);
            elseif isnumeric(address) && length(address) == 4
                board = strata.Connection.withEthernetIp(address);
            else
                board = strata.Connection.withEnumeration();
            end
        end

        function board = withUuid(uuid)
            boardManager = strata.Connection.enumerate(true, true, true);
            board = boardManager.createSpecificBoardInstance(uuid);
            strata.Connection.checkBoardVersion(board);
        end
    end

    methods (Static, Access = private)
        function boardManager = enumerate(serial, ethernet, usb)
            boardManager = strata.BoardManager(serial, ethernet, usb, false);

            retries = 10;
            % retry connecting
            for i=1:retries
                count = boardManager.enumerate();
                if count > 0
                    break
                end
                fprintf('\nRe-trying connection to board... (%d/%d)\n', i, retries);
                pause(1); % wait for one second before retrying
            end
        end
    end

end
