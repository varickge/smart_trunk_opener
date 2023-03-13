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
classdef IProtocolAvian < handle
    % IProtocolAvian interface class, controlling an Avian on a board directly
    properties (Hidden = true, SetAccess = private)
        h
    end

    properties (Constant, Hidden = true)
        value_width = 24;
    end

    methods

        function obj = IProtocolAvian(handle)
            obj.h = handle;
        end

        function status = execute(obj, commands)
            status = strata.wrapper_matlab(obj, 'execute', commands);
        end

        function setBits(obj, address, bitmask)
            strata.wrapper_matlab(obj, 'setBits', strata.Conversion.toInt('uint8', address), strata.Conversion.toInt('uint32', bitmask));
        end

    end

    methods(Static)
        function command = Write(address, value)
            address = strata.Conversion.toInt('uint32', address);
            value = strata.Conversion.toInt('uint32', value);

            address_bits = bitshift(address, strata.IProtocolAvian.value_width + 1);
            write_bit = bitshift(1, strata.IProtocolAvian.value_width);

            value_mask = bitshift(1, strata.IProtocolAvian.value_width) - 1;
            value_bits = bitand(value, value_mask);

            command = uint32(address_bits + write_bit + value_bits);
        end

        function command = Read(address)
            address = strata.Conversion.toInt('uint32', address);

            command = uint32(bitshift(address, strata.IProtocolAvian.value_width + 1));
        end
    end
end
