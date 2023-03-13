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
classdef IProtocolAtr22 < handle
    % IProtocolAtrww interface class, controlling an Atr22 on a board directly
    properties (Hidden = true, SetAccess = private)
        h
    end
    
    methods
        
        function obj = IProtocolAtr22(handle)
            obj.h = handle;
        end
        
        function executeWrite(obj, commands)
            strata.wrapper_matlab(obj, 'executeWrite', commands);
        end
        
        function result = executeRead(obj, command, count)
            if nargin < 3
                count = 1;
            end
            result = strata.wrapper_matlab(obj, 'executeRead', command, uint16(count));
        end
        
        function setBits(obj, regAddr, bitmask)
            strata.wrapper_matlab(obj, 'setBits', uint16(regAddr), uint16(bitmask));
        end
        
    end
    
    methods(Static)
        
        function command = Write(regAddr, value)
            regAddr = strata.Conversion.toInt('uint16', regAddr);
            value = strata.Conversion.toInt('uint16', value);
            command = strata.wrapper_matlab('strata.IProtocolAtr22', 'Write', regAddr, value);
        end
        
        function command = Read(regAddr)
            regAddr = strata.Conversion.toInt('uint16', regAddr);
            command = strata.wrapper_matlab('strata.IProtocolAtr22', 'Read', regAddr);
        end
        
    end
    
end
