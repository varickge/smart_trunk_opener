classdef BoardEthernet
    methods(Static)
        function board = createBoardInstance(ipAddr)
		    if ~isnumeric(ipAddr)
                ipAddr = hex2dec(ipAddr);
            end
            board = strata.BoardInstance(strata.wrapper_matlab(strata.BoardEthernet, 'createBoardInstance', uint8(ipAddr)));
        end
    end
end
