% ===========================================================================
% Copyright (C) 2021 Infineon Technologies AG
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
% 1. Redistributions of source code must retain the above copyright notice,
%    this list of conditions and the following disclaimer.
% 2. Redistributions in binary form must reproduce the above copyright
%    notice, this list of conditions and the following disclaimer in the
%    documentation and/or other materials provided with the distribution.
% 3. Neither the name of the copyright holder nor the names of its
%    contributors may be used to endorse or promote products derived from
%    this software without specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.
% ===========================================================================
classdef IRadarAvian < strata.IRadar
    properties (Constant)
        %Avian Register addresses
        MAIN = 0;     % Main register
        CHIP_ID = 2;  % Digital and RF version
        SFCTL = 6;    % SPI and FIFO Control
        CSI_0 = 8;    % Channel set idle mode
    end

    methods

        function obj = IRadarAvian(handle)
            obj@strata.IRadar(handle);
        end

        function IRegisters = getIRegisters(obj)
            [handle, AddressType, ValueType] = strata.wrapper_matlab(obj, 'getIRegisters');
            IRegisters = strata.IRegisters(handle, AddressType, ValueType);
        end

        function IPinsAvian = getIPinsAvian(obj)
            IPinsAvian = strata.IPinsAvian(strata.wrapper_matlab(obj, 'getIPinsAvian'));
        end

        function IProtocolAvian = getIProtocolAvian(obj)
            IProtocolAvian = strata.IProtocolAvian(strata.wrapper_matlab(obj, 'getIProtocolAvian'));
        end

    end

    methods(Static)

        function output = getReadoutBase(chipId)
            switch chipId
                case (strata.Conversion.toInt('uint32', '0x303')) % BGT60TR13C
                    output = strata.Conversion.toInt('uint16', '0x60');
                case (strata.Conversion.toInt('uint32', '0x504')) % BGT60ATR24C
                    output = strata.Conversion.toInt('uint16', '0x62');
                otherwise
                    error('Invalid Avian Chip ID!');
            end
        end

    end
end
