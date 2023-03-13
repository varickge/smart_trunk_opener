% ===========================================================================
% Copyright (C) 2022 Infineon Technologies AG
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

function mimose_example_kickdetection_demo()
    close all;
    clearvars;
    clc;
    if ~isdeployed
        run('../../addStrataPath.m');
        addpath('../config/');
        addpath('common/');
    end
    
    
    % guiObj = gui_app;
    
    PRT = 0.500e-3;
    numPCs=2;
    N_FFT=32; %number of point of FFT on IC
    selectedWindow=6;
    c=3e8;
    fc=24.2e9;
    lambda=c/fc;
    
    sampleSize = 32;
    TH=100;
    targetLen=2;
    FrameTime=40e-3;
    Fsamp=1/PRT;
    TimeAxis=[];
    time_avg_len=12;
    
    % SysClck='RC_Clk';
    SysClck='XTAL';
    
    AveVelocities=zeros(10000,2);
    MovAveVelocities=zeros(10000,2);
    acceleration=zeros(10000,2);
    MovAveAcc=zeros(10000,2);
    
    %% Kick detection variables
    kick_stop=0;
    kick_stopgraph=0;
    kick_stopWarnGraph=0;
    kick_start=1;
    kick_detectedVec=[];
    kick_detectedVecPatch=[];
    kick_detected=0;
    detection_speed=1/40; % m/s
    %% Figure Creation
    hfig = figure('units','normalized','outerposition',[0 0 1 1]);
    subplot(2,1,1)
    yyaxis('left');
    hSub1_MovAve = plot(0,0, 'LineWidth', 1.5);
    ylim([-3,3]);
    ylabel('Velocity,m/s')
    yyaxis('right');
    hSub1_Acc = plot(0,0, 'LineWidth',1.5);
    % legend('Mov Ave Velocity','Mov Ave Acceleration')
    ylim([-10,10]);
    title('PC0(Patch) Average Velocity from Target Data values');
    xlabel('Time (s)')       
    ylabel('Acceleration,m/s^2')
    grid on; 
    grid minor; 
    subplot(2,1,2)
    yyaxis('left');
    hSub2_MovAve = plot(0,0, 'LineWidth', 1.5);
    ylim([-1.8,1.8]);       
    ylabel('Velocity,m/s')
    yyaxis('right');
    hSub2_Acc = plot(0,0, 'LineWidth',1.5);
    % legend('Mov Ave Velocity','Mov Ave Acceleration')
    ylim([-3.5,3.5]);
    title('PC1(Yagi) Average Velocity from Target Data values');
    grid on; 
    grid minor; 
    xlabel('Time (s)')            
    ylabel('Acceleration,m/s^2')
    
    set(hfig,'color', [0.5 0.5 0.5]);
    
    
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
    memTargetOffset = 512; % default value;
    
    memRawDataStatAddress = memoryStartAddress;
    rawDataReadcount = 64 * 2;
    
    memFtDataStartAddress = memoryStartAddress + memFtOffset * 2;
    ftDataReadCount = 256 * 2;
    
    memTargetDataStartAddress=memoryStartAddress + memTargetOffset*2;
    trgtDataReadCount = 2*targetLen* 2;
    
    % Read "FRAME_COUNTER"
    FrameCounterAdd=hex2dec('0301');
    FrameCounterReadCount=1;
    readout =[
    %      memRawDataStatAddress rawDataReadcount;
    %     memFtDataStartAddress ftDataReadCount;
        memTargetDataStartAddress trgtDataReadCount
        FrameCounterAdd        FrameCounterReadCount
        ];
    
    dataSettings = strata.DataSettingsBgtRadar(readout, 0);
    data_properties.format = 0;
    data.configure(dataIndex, data_properties, dataSettings);
    
    regSizeInBytes = 2;
    frameBufferSize = sum(readout(:,2)) * regSizeInBytes ;
    databridge.setFrameBufferSize(frameBufferSize);
    databridge.setFrameQueueSize(16);
    databridge.startStreaming();
    
    data.start(dataIndex)
    
    %% configuring device registers
    % register.write(config_atr22_example())
    % FileName='VT_Reg_list_2_shortened.txt';
    % FileName='TargetData_Patch_plus_Yagi_Strongest4targets_32samples_prt500us_frame20ms.txt';
    % FileName='TargetData_Patch_plus_Yagi_Strongest2targets_16samples_prt1ms_frame22ms_zeroPadded32fft.txt';
    if strcmp(SysClck,'XTAL')
        FileName=['common/TargetData_Patch_plus_Yagi_Strongest' num2str(targetLen) 'targets_' num2str(sampleSize) 'samples_prt500us_frame' num2str(round(FrameTime*1000)) 'ms_FFT' num2str(N_FFT) 'points_B1.txt'] ;
    elseif strcmp(SysClck,'RC_Clk')
        FileName=['common/TargetData_Patch_plus_Yagi_Strongest' num2str(targetLen) 'targets_' num2str(sampleSize) 'samples_prt500us_frame' num2str(round(FrameTime*1000)) 'ms_FFT' num2str(N_FFT) 'points_B1_RC_CLK10MHz.txt'] ;
    end
    % FileName=['Pzthon working.txt'];
    RegisterSettings=convert_Presilicon2MatlabRegisters(FileName);
     
    
    register.write(RegisterSettings{1,:})
    
    % sizeofSettings=size(RegisterSettings);
    % for j=1:sizeofSettings(1)
    %     register.write(RegisterSettings{j,1},RegisterSettings{j,2})
    % end
    
    
    sizeofSettings=size(RegisterSettings);
    for j=1:sizeofSettings(1)
        register.write(RegisterSettings{j,:})
    end
    
    
    % register.write(0x001, 20)
    %default sample size is 128
    
    %% Output power arrangement
    % You can change
    PatchAntennaPowerIndex=60; % Power index could be between 0 (min): 63 (max)  
    YagiAntennaPowerIndex=45; % Power index could be between 0 (min): 63 (max)  
    
    register.write('TX1_PC0_CONF', 0x0001+bitshift(PatchAntennaPowerIndex,1));
    register.write('TX2_PC1_CONF', 0x0001+bitshift(YagiAntennaPowerIndex,1));
    
    
    %% Baseband gain settings 
    % You can change
    register.write('PC0_AGC', 0xE); % BaseBand gain settings 
    register.write('PC1_AGC', 0xE); % BaseBand gain settings 
    register.write('PC2_AGC', 0x0); % BaseBand gain settings 
    register.write('PC3_AGC', 0x0); % BaseBand gain settings 
    %0x0000: All BB Gain indices are 0
    %0x2222: All BB Gain indices are 1
    %0x4444: All BB Gain indices are 2
    %0x6666: All BB Gain indices are 3
    %0x8888: All BB Gain indices are 4
    %0xAAAA: All BB Gain indices are 5
    %0xCCCC: All BB Gain indices are 6
    %0xEEEE: All BB Gain indices are 7
    
    
    % register.write('TX1_TEST', 0x000C);
    % register.write('TX2_TEST', 0x000C);
    
    %% fetch data
    %  figure('Renderer', 'painters', 'Position',  [2500 250 800 450])
    % ==========================Commented for GUI=============================
    % figure,
    % subplot(2,1,1)
    % yyaxis left
    % hSub1_MovAve=plot(0,0,'Linewidth',1.5);
    % ylim([-3 3])
    % yyaxis right
    % hSub1_Acc=plot(0,0,'Linewidth',1.5);
    % title('PC0(Patch) Average Velocity from Target Data values')
    % grid on; grid minor;
    % 
    % subplot(2,1,2)
    % yyaxis left
    % clc
    
    % hSub2_MovAve=plot(0,0,'Linewidth',1.5);
    % ylim([-3 3])
    % yyaxis right
    % hSub2_Acc=plot(0,0,'Linewidth',1.5);
    % title('PC1(Yagi) Average Velocity from Target Data values')
    % 
    % grid on; grid minor;
    % ========================================================================
    
    
    
        
    %=========================================================================
    isKickValid=0;
    pause(3)
    %% start sequencer
    disp('acquisition is starting!!!')
    
    count = 0;
    register.write("SEQ_MAIN_CONF.SEQ_EXECUTE", 1) % starts ATR22
    while (count<=3023)
        measurement = board.getFrame(500);
        if ~isempty(measurement)
            
            measurement16 = typecast(measurement,'uint16');
            % readout data        
            memRawData = measurement16(1:trgtDataReadCount);
            FramePerRead(count+1)=double(measurement16(trgtDataReadCount+1));
    
            targetDataRaw(count+1, 1:(4*targetLen))=double(memRawData');
            
            count = count+1;
            t(count)=(count-1)*FrameTime;
            considertargetLen=2;
            % Target data converted to average velocities
            AveVelocities(count,1:2)= convrtAveVelocity(targetDataRaw(count,1:(4*targetLen)), considertargetLen, TH, N_FFT, PRT,lambda,targetLen);
    
    
            
            if count>=time_avg_len
                localIndex=count-round(0.5*(time_avg_len));
                MovAveVelocities(localIndex,1)=1.5*mean(AveVelocities(count-time_avg_len+1:1:count,1));
                MovAveVelocities(localIndex,2)=1.5*mean(AveVelocities(count-time_avg_len+1:1:count,2));
                %accelaration from MOVing average velocities
                acceleration(localIndex,1)=(MovAveVelocities(localIndex,1)-MovAveVelocities(localIndex-1,1))/FrameTime;
                acceleration(localIndex,2)=(MovAveVelocities(localIndex,2)-MovAveVelocities(localIndex-1,2))/FrameTime;
            end
            if count>(time_avg_len*2)
                localIndices_acc=(count-round(1.5*(time_avg_len)))+(1:1:time_avg_len);
                localIndex=count-1*time_avg_len;
                MovAveAcc(localIndex,1)=1.5*mean(acceleration(localIndices_acc,1));
                MovAveAcc(localIndex,2)=1.5*mean(acceleration(localIndices_acc,2));
                %% Plot and Background refresh
                set(hSub1_MovAve,'YData',MovAveVelocities(1:1:count-1,1));
                set(hSub1_MovAve,'XData',FrameTime*(0:1:count-1-1));
                set(hSub1_Acc,'YData',MovAveAcc(1:1:count-1,1));
                set(hSub1_Acc,'XData',FrameTime*(0:1:count-1-1));
    
                set(hSub2_MovAve,'YData',MovAveVelocities(1:1:count-1,2));
                set(hSub2_MovAve,'XData',FrameTime*(0:1:count-1-1));
                set(hSub2_Acc,'YData',MovAveAcc(1:1:count-1,2));
                set(hSub2_Acc,'XData',FrameTime*(0:1:count-1-1));
                if (((kick_stopgraph(end)-localIndex)>-28)&&localIndex>100) 
                    set(hfig,'color', [0 1 0]);
                elseif (((kick_stopWarnGraph(end)-localIndex)>-28)&&localIndex>100) 
                    set(hfig,'color', [1 1 0]);
                else
                    set(hfig,'color', [1 1 1]);
                end
                            
                pause(0.0001)
                %%
                
                
                %% Check if Kick is Valid
                
                if (kick_start(end) == 1)
                    if (abs(MovAveVelocities(localIndex,2)) > detection_speed)
                        kick_start(end) = localIndex;
                    end
                else
                    if (kick_stop(end) == 0) % && (count > 3) % check kick stop
                        if ((sum((abs(MovAveVelocities(localIndex-(0:1:4),2)) < detection_speed))>3)&& (localIndex-kick_start(end)>3))
                            kick_stop(end) = localIndex-3;
                            % Check if Kick is valid!!! 
                            kick_detected_patch=0;
                            % Check if Kick is valid!!!
                            kick_detected=validateKick(kick_start(end),kick_stop(end),t,MovAveVelocities(:,2),MovAveAcc(:,2),time_avg_len);
                           
                            if kick_detected
    %                             fprintf(1,['\n' num2str(length(kick_detectedVec)+1) 'th kick is valid at Yagi Side! Patch is being checked!!!'])
                                kick_detected_patch=validateKick(kick_start(end),kick_stop(end),t,MovAveVelocities(:,1),MovAveAcc(:,1),time_avg_len);
                                yagiKick = true; % Added for gui
                                if kick_detected_patch
    %                                 fprintf(1,[' >> ' num2str(length(kick_detectedVec)+1) 'th kick is valid also with Patch\n'])
                                    patchKick = true; % Added for gui
                                    kick_stopgraph=[kick_stopgraph kick_stop];
                                else
    %                                  fprintf(2,[' >> ' num2str(length(kick_detectedVec)+1) 'th kick is NOT valid with Patch\n'])
                                     patchKick = false; % Added for gui
                                     kick_stopWarnGraph=[kick_stopWarnGraph kick_stop];
                                end
                            else
    %                             fprintf(2,['\n' num2str(length(kick_detectedVec)+1) 'th kick is NOT valid on Yagi Side\n'])
                                yagiKick = false; % Added for gui
                            end
                            % ==========================Added for GUI=============================
                            %updateGraphs(guiObj, MovAveVelocities, MovAveAcc, count, FrameTime);
                            %updateLog(guiObj, yagiKick, patchKick);
                            yagiKick = false;
                            patchKick = false;
                            %======================================================================
                            kick_detectedVec=[kick_detectedVec kick_detected];
                            kick_detectedVecPatch=[kick_detectedVecPatch kick_detected_patch];
                            kick_start=[kick_start 1];
                            kick_stop=[kick_stop 0];
                            
                        end
                    end
                end
                
                
            end
    
        end
    end
    
    
    %% stop sequencer
    register.write("SEQ_MAIN_CONF.SEQ_EXECUTE", 0);
    disp('acquisition is stopped!!!')
    
    
    subplot(2,1,1);
    yyaxis('left');
    yLim_max=max(abs(MovAveVelocities(1:1:count-1,1)));
    ylim([-yLim_max,yLim_max]);  
    yyaxis('right');
    yLim_max=max(abs(MovAveAcc(1:1:count-1,1)));
    ylim([-yLim_max,yLim_max]); 
    
    subplot(2,1,2);
    yyaxis('left');
    yLim_max=max(abs(MovAveVelocities(1:1:count-1,2)));
    ylim([-yLim_max,yLim_max]);  
    yyaxis('right');
    yLim_max=max(abs(MovAveAcc(1:1:count-1,2)));
    ylim([-yLim_max,yLim_max]); 
    %========================================================================= 
    %[validKicks, totalKicks] = getValidAndTotalKicks(guiObj);
    %save('raw_data', 'MovAveAcc', 'MovAveVelocities', 'FrameTime', 'count', 'validKicks', 'totalKicks');
    
    %% Plotting Green and Red lines on the Graph
    PlotGreenRed_Kick = 0;
    if PlotGreenRed_Kick
      for kickAttempt=1:1:length(kick_detectedVec)
         kickPositions=[(kick_start(kickAttempt)-1)+(0:0) (kick_stop(kickAttempt)-1)-(0:-1:0)];
            if kick_detectedVec(kickAttempt)
                 subplot(2,1,2)
                 hold on;
                 area(FrameTime*(kickPositions),100*ones(1,length(kickPositions)),'edgecolor',[0.4 0.85 0.1],'facecolor','none','LineWidth',3);
                 area(FrameTime*(kickPositions),-100*ones(1,length(kickPositions)),'edgecolor',[0.4 0.85 0.1],'facecolor','none','LineWidth',3);
            else
                 subplot(2,1,2)
                 hold on;
                 area(FrameTime*(kickPositions),100*ones(1,length(kickPositions)),'edgecolor',[0.9 0.1 0.1],'facecolor','none','LineWidth',3);
                 area(FrameTime*(kickPositions),-100*ones(1,length(kickPositions)),'edgecolor',[0.9 0.1 0.1],'facecolor','none','LineWidth',3);
            end
            if kick_detectedVecPatch(kickAttempt)
                 subplot(2,1,1)
                 hold on;
                 area(FrameTime*(kickPositions),100*ones(1,length(kickPositions)),'edgecolor',[0.4 0.85 0.1],'facecolor','none','LineWidth',3);
                 area(FrameTime*(kickPositions),-100*ones(1,length(kickPositions)),'edgecolor',[0.4 0.85 0.1],'facecolor','none','LineWidth',3);
            else
                 subplot(2,1,1)
                 hold on;
                 area(FrameTime*(kickPositions),100*ones(1,length(kickPositions)),'edgecolor',[0.9 0.1 0.1],'facecolor','none','LineWidth',3);
                 area(FrameTime*(kickPositions),-100*ones(1,length(kickPositions)),'edgecolor',[0.9 0.1 0.1],'facecolor','none','LineWidth',3);
            end
      end
    end 
    %%
    % ==========================Commented for GUI=============================
    % subplot(2,1,1)
    % yyaxis right;
    % legend('Mov Ave Velocity','Mov Ave Acceleration')
    % lim_y=max(abs(min(MovAveAcc(1:1:count-1,1))) , max(MovAveAcc(1:1:count-1,1)) );
    % ylim([-lim_y-1 +lim_y+1])
    % 
    % subplot(2,1,2)
    % yyaxis right;
    % legend('Mov Ave Velocity','Mov Ave Acceleration')
    % lim_y=max(abs(min(MovAveAcc(1:1:count-1,2))) , max(MovAveAcc(1:1:count-1,2)) );
    % ylim([-lim_y-1 +lim_y+1])
    % ========================================================================
    %%
      if (abs(length(FramePerRead)-1-FramePerRead(end)+FramePerRead(1))~=0)
         disp([num2str(abs(length(FramePerRead)-1-FramePerRead(end)+FramePerRead(1))) ' Frames missed due to communication!'])
      end
    
    
    %% stop any ongoing data transmission
    data.stop(dataIndex);
    databridge.stopStreaming();
    
    
    clear mex;
    
    targetDataRaw_FreqBin=targetDataRaw;
    for j=1:height(targetDataRaw)
        targetDataRaw_FreqBin(j,1)=bitand(double(targetDataRaw(j,1)), 255);
        targetDataRaw_FreqBin(j,2)=bitand(double(targetDataRaw(j,3)), 255);
        targetDataRaw_FreqBin(j,3)=bitand(double(targetDataRaw(j,5)), 255);
        targetDataRaw_FreqBin(j,4)=bitand(double(targetDataRaw(j,7)), 255);
        targetDataRaw_FreqBin(j,5)=0;
        targetDataRaw_FreqBin(j,6)=0;
        targetDataRaw_FreqBin(j,7)=0;
        targetDataRaw_FreqBin(j,8)=0;
        
    end
    
    
    function isKick_valid=validateKick(kick_start,kick_stop,t,avg_speeds,avg_acceleration,time_avg_len)
        isKick_valid = 1;
        kick_start_acc=kick_start-round(time_avg_len/2);
        kick_stop_acc=kick_stop+round(time_avg_len/2);
        if (t(kick_stop) - t(kick_start) < 0.5) % minimum kick duration 500 ms
    %          disp('minimum kick duration 500 ms');
            isKick_valid = 0;
        end
        if (t(kick_stop) - t(kick_start) > 2) % maximum kick duration 2 s
    %          disp('maximum kick duration 2 s');
            isKick_valid = 0;
        end
        if (min(avg_speeds(kick_start:round((kick_stop-kick_start)/3+kick_start))) < 0)
            isKick_valid = 0;  % first third of the kick need to approach radar
    %          disp('first third of the kick need to approach radar');
        end
        if (max(avg_speeds(round(kick_stop-(kick_stop-kick_start)/3):kick_stop)) > 0)
            isKick_valid = 0;  % last third of the kick need to depart from radar
    %          disp('last third of the kick need to depart from radar');
        end
    %     if (min(avg_acceleration(kick_start_acc:round((kick_stop_acc-kick_start_acc)/6+kick_start_acc))) < 0)
    %         isKick_valid = 0;  % first sixth of the kick need to accelerate towards radar
    %          disp('first sixth of the kick need to accelerate towards radar');
    %     end
        if (min(avg_acceleration(round(kick_stop_acc-(kick_stop_acc-kick_start_acc)/6):kick_stop_acc)) < 0)
            isKick_valid = 0;  % last sixth of the kick need to accelerate towards radar (brake)
    %          disp('last sixth of the kick need to accelerate towards radar (brake)');
        end
        if (max(avg_acceleration(round(kick_start_acc+(kick_stop_acc-kick_start_acc)*3.9/8):round(kick_stop_acc-(kick_stop_acc-kick_start_acc)*3.9/8))) > 0)
            isKick_valid = 0;  % mid third of the kick need to accelerate away from radar
    %          disp('mid third of the kick need to accelerate away from radar');
        end
        %% Check for patch antenna
         if (sum(abs(avg_speeds(kick_start:kick_stop)~= 0))<(0.80*(kick_stop-kick_start-1)))
            isKick_valid = 0;  % first third of the kick need to approach radar
    %          disp('more than %80 of frame data is 0 !!!');
        end
    end
end