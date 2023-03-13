classdef IPowerSupplyMax20430Pec < strata.IPowerSupply
    % Class for accessing the register interface of the power supply
    %
    % IPowerSupplyMax20430Pec Functions:
    %   getIRegisters - Returns the register interface for configuring the power supply

    methods
        function obj = IPowerSupplyMax20430Pec(handle)
            obj@strata.IPowerSupply(handle);
        end

        function IRegisters = getIRegisters(obj)
            % Returns the register interface for configuring the power supply
            [handle, AddressType, ValueType] = strata.wrapper_matlab(obj, 'getIRegisters');
            IRegisters = strata.IRegisters(handle, AddressType, ValueType);
        end
    end

end
