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

function kick_detection_recording(varargin)
   
    disp("Starting offline kick prediction!");
    args = parseArguments(varargin{:});
    disp(args);

    if ~isdeployed
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
    
    disp("Loading recording!");
    recording_path = args.rec;
    if ~exist(recording_path, 'file')
        fprintf("Error: Recording not found: %s \n", recording_path)
        return
    end

    file_data = parse_npy_to_mat(recording_path);
    file_data.frame_count = round(length(file_data.Frame));

        
    %=========================================================================
    isKickValid=0;  
    count = 0;
    
    for i = 1:file_data.frame_count

        trg_rec_data = reshape(file_data.Frame(i).Raw_data, [], 1);

        targetDataRaw(count+1, 1:(4*targetLen))=double(trg_rec_data);
        

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
                            patchKick = false;
                        end
                        fprintf('{"frame": %d, "yagi_kick": %d, "patch_kick": %d, "kick_start": %d}\n', i, int8(yagiKick), int8(patchKick), int64(kick_start(end)));
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
     
    clear mex;
    
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
    close all;
end

function args = parseArguments(varargin)
    p = inputParser;
    addRequired(p, 'rec');
    parse(p, varargin{:});
    args = p.Results;
end