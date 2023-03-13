classdef IPowerSupply < handle
    % Class for accessing the register interface of the power supply
    %

    properties (Hidden = true, SetAccess = private)
        h
    end

    methods
        function obj = IPowerSupply(handle)
            obj.h = handle;
        end

    end

end
