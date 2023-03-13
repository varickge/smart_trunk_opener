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
% avian_data()  test configure avian device using strata, receive and plot data.


close all;
clearvars;
clc;
run('../../addStrataPath.m');
addpath('../config/');
avian_board = strata.Connection.withAutoAddress();
[vid, pid] = avian_board.getIds();
fprintf('RBB vid = 0x%x, pid = 0x%x\n', vid, pid);
avian = avian_board.getComponent('IRadarAvian', 0);
pins = avian.getIPinsAvian();
regs = avian.getIRegisters();
protocol = avian.getIProtocolAvian();
data = avian_board.getIData();
databridge = avian_board.getIBridgeData();
dataIndex = avian.getDataIndex();

data.stop(dataIndex);

% reset device
pins.reset();

%configure SPI high speed compensation and wait cycles
regs.write(avian.SFCTL, '0x100000');

% configure data readoutclear
% get readout base address based on chipid
readout_base = avian.getReadoutBase(regs.read(avian.CHIP_ID));

framesize = 1024;
sampleSize = 2;

% configure
data_settings = strata.DataSettingsBgtRadar([readout_base framesize], 0);
data_properties.format = strata.DataFormat.Raw16;

data.configure(dataIndex, data_properties, data_settings);

databridge.setFrameBufferSize(framesize * sampleSize);
databridge.setFrameQueueSize(16);
databridge.startStreaming();

data.start(dataIndex)

% configuring device
command_sequence = config_easy_scenario;
protocol.execute(command_sequence);

% Configure plot
hfig.fig = figure;
hfig.surf = handle(surf(NaN(2)));
view(106, 16);
axis([0 16 0 64 1600 2100]);
hfig.fig.NumberTitle = 'off';
hfig.fig.Name = 'Avian Shield Data: Close plot window to stop device';
frame_count = 0;
disp('Close plot window to stop device');

% Initiating measurement sequence...
regs.modifyBits(avian.MAIN, 0, 1);

while ishandle(hfig.fig)
    receive_buffer = avian_board.getFrame(1000);
    radar_data = typecast(receive_buffer, 'uint16');
    radar_data = reshape(radar_data, 64, 16);
    set(hfig.surf, 'ZData', radar_data);
    title(sprintf('Frame Count = %d', frame_count));
    drawnow();
    frame_count = frame_count + 1;
end
hfig.surf.delete();


% stopping measurement
regs.write(avian.MAIN, '0x1e827c');
data.stop(dataIndex);
databridge.stopStreaming();
