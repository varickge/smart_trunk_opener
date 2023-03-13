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
% config_easy_scenario  create register configuration set for the following
% settings
% "Small frame with low frame rate (easy) configuration"
% This is the register dump of a BGT60TR13C read out with following configuration:
%
% Number of samples per chirp: 64
% Number of chirps per frame: 16
% RX antenna mask: 0x01
% TX antenna mask: 0x01
% Frame rate: 10 Hz
% TX power level: 31
% RF gain: 33 dB
% ADC sample rate: 1000000
% Lower frequency: 60500000000 Hz
% Upper frequency: 61500000000 Hz
% Chirp repetition time: 538.61e-6 s
%
%   Usage:
%   [command_array] = config_easy_scenario;
%
%   Return values:
%   'commands' contains an array of commands to be run via
%   IProtocolAvian.execute
%

function [commands] = config_easy_scenario()
commands = [
    strata.IProtocolAvian.Write('0x00', '0x1c8270')
    strata.IProtocolAvian.Write('0x01', '0x140210')
    strata.IProtocolAvian.Write('0x04', '0xe967fd')
    strata.IProtocolAvian.Write('0x05', '0x0805b4')
    strata.IProtocolAvian.Write('0x06', '0x1021ff')
    strata.IProtocolAvian.Write('0x07', '0x0107c0')
    strata.IProtocolAvian.Write('0x08', '0x000000')
    strata.IProtocolAvian.Write('0x09', '0x000000')
    strata.IProtocolAvian.Write('0x0a', '0x000000')
    strata.IProtocolAvian.Write('0x0b', '0x000be0')
    strata.IProtocolAvian.Write('0x0c', '0x000000')
    strata.IProtocolAvian.Write('0x0d', '0x000000')
    strata.IProtocolAvian.Write('0x0e', '0x000000')
    strata.IProtocolAvian.Write('0x0f', '0x000b60')
    strata.IProtocolAvian.Write('0x10', '0x103c51')
    strata.IProtocolAvian.Write('0x11', '0x1ff41f')
    strata.IProtocolAvian.Write('0x12', '0xf7bdef')
    strata.IProtocolAvian.Write('0x16', '0x000490')
    strata.IProtocolAvian.Write('0x1d', '0x000480')
    strata.IProtocolAvian.Write('0x24', '0x000480')
    strata.IProtocolAvian.Write('0x2b', '0x000480')
    strata.IProtocolAvian.Write('0x2c', '0x11be0e')
    strata.IProtocolAvian.Write('0x2d', '0x66f40a')
    strata.IProtocolAvian.Write('0x2e', '0x00f000')
    strata.IProtocolAvian.Write('0x2f', '0x787e1e')
    strata.IProtocolAvian.Write('0x30', '0xe7cd4a')
    strata.IProtocolAvian.Write('0x31', '0x000131')
    strata.IProtocolAvian.Write('0x32', '0x0002b2')
    strata.IProtocolAvian.Write('0x33', '0x000040')
    strata.IProtocolAvian.Write('0x34', '0x000000')
    strata.IProtocolAvian.Write('0x35', '0x000000')
    strata.IProtocolAvian.Write('0x36', '0x000000')
    strata.IProtocolAvian.Write('0x37', '0x2c1310')
    strata.IProtocolAvian.Write('0x3f', '0x000100')
    strata.IProtocolAvian.Write('0x47', '0x000100')
    strata.IProtocolAvian.Write('0x4f', '0x000100')
    strata.IProtocolAvian.Write('0x55', '0x000000')
    strata.IProtocolAvian.Write('0x56', '0x000000')
    strata.IProtocolAvian.Write('0x5b', '0x000000')
    ];
end
