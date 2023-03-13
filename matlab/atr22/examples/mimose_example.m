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
% atr22_data  test configure atr22 device using strata, receive and plot data.


close all;
clearvars;
clc;
run('../../addStrataPath.m');
addpath('../config/');
addpath('common');

%% connect to device
board = strata.Connection.withAutoAddress();
[vid, pid] = board.getIds();
fprintf('RBB vid = 0x%x, pid = 0x%x\n', vid, pid);

%% obtain Atr22 device interfaces
radarAtr22 = board.getComponent('IRadarAtr22', 0);
register = strata.NamedRegister.NamedRegister(radarAtr22.getIRegisters(), 'atr22_regmap_from_essence.json');
databridge = board.getIBridgeData();
data = board.getIData();
dataIndex = 0;
% stop any ongoing data transmission
data.stop(dataIndex);

%% configure data readout
memoryStartAddress = 0x3800;
memRawOffset = 0; % default value;
memFtOffset = 256; % default value;

memRawDataStatAddress = memoryStartAddress;
rawDataReadcount = 128 * 2;

memFtDataStartAddress = memoryStartAddress + memFtOffset*2;
ftDataReadCount = 128 * 2;

readout =[
    memRawDataStatAddress rawDataReadcount;
    memFtDataStartAddress ftDataReadCount
    ];

dataSettings = strata.DataSettingsBgtRadar(readout, 0);
data_properties.format = 0;
data.configure(dataIndex, data_properties, dataSettings);

regSizeInBytes = 2;
frameBufferSize = (rawDataReadcount + ftDataReadCount) * regSizeInBytes ;
databridge.setFrameBufferSize(frameBufferSize);
databridge.setFrameQueueSize(16);
databridge.startStreaming();

data.start(dataIndex)


%% configuring device registers

FileName='common/TargetData_Patch_128samples_prt1ms_frame200ms_FFT128points_B1.txt';
FileName='common/TargetData_Yagi_128samples_prt1ms_frame200ms_FFT128points_B1.txt';
% FileName=['Pzthon working.txt'];
RegisterSettings=convert_Presilicon2MatlabRegisters(FileName);
 

% register.write(RegisterSettings)
sizeofSettings=size(RegisterSettings);
for j=1:sizeofSettings(1)
    register.write(RegisterSettings{j,1},RegisterSettings{j,2})
end

%% start sequencer
register.write("SEQ_MAIN_CONF.SEQ_EXECUTE", 1)

%% fetch data
%default sample size is 128
sampleSize = 128;
hfig = figure;
count = 1;
while ishandle(hfig)
    measurement = board.getFrame(1000);
    if ~isempty(measurement)
        measurement16 = typecast(measurement,'uint16');
        % readout data
        memRawData = measurement16(1:rawDataReadcount);
        memFtData = measurement16((rawDataReadcount+1):(rawDataReadcount+ftDataReadCount));
        % parsing data
        real_samples = memRawData(1:2:sampleSize*2);
        imag_samples = memRawData(2:2:sampleSize*2);

         % FT data parsing with 8 bit phase and 16 bit magnitude
        low_part_ft_data = uint32(memFtData(1:2:sampleSize*2));
        high_part_ft_data = uint32( memFtData(2:2:sampleSize*2));
        phase_ft_data = bitshift(high_part_ft_data,-4);
        magnitude_ft_data = bitshift(bitand(high_part_ft_data, uint32(0xF)),12) + low_part_ft_data;
        
        subplot(2,1,1);
        raw_plt_handle = plot([real_samples imag_samples], 'LineWidth',1.25);
        axis([1 128 0 4096]);
        title('ATR22 Strata Data Example');
        legend('I Data', 'Q Data');
        xlabel(sprintf('Frame Number: %d', count));
        
        subplot(2,1,2);
        ft_plt_handle = plot(magnitude_ft_data, 'LineWidth',1.25);
        axis([1 128 0 4096]);
        legend('Magnitude');
       

        drawnow();
        count = count+1;
    end
end

%% stop sequencer
register.write("SEQ_MAIN_CONF.SEQ_EXECUTE", 0)

%% stop any ongoing data transmission
data.stop(dataIndex);
databridge.stopStreaming();

clear mex;
