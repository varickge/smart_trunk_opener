classdef BoardSerial
    methods(Static)
        function board = createBoardInstance(port)
            board = strata.BoardInstance(strata.wrapper_matlab(strata.BoardSerial, 'createBoardInstance', port));
        end
    end
end
