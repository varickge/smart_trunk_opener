%**************************************************************************
%                        IMPORTANT NOTICE
%**************************************************************************
% THIS SOFTWARE IS PROVIDED "AS IS". NO WARRANTIES, WHETHER EXPRESS,
% IMPLIED OR STATUTORY, INCLUDING, BUT NOT LIMITED TO, IMPLIED WARRANTIES
% OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE APPLY TO THIS
% SOFTWARE. INFINEON SHALL NOT, IN ANY CIRCUMSTANCES, BE LIABLE FOR SPECIAL,
% INCIDENTAL, OR CONSEQUENTIAL DAMAGES, FOR ANY REASON WHATSOEVER.
%**************************************************************************

close all
clearvars
clc

run('../addStrataPath.m')
addpath('spu') % Add test subfunctions to path

%% connect to board and get access to its processing module
board = strata.Connection.withAutoAddress();
memory = board.getIMemory();
spu = board.getComponent('IProcessingRadar', 0);
spu_helper = SpuHelper(spu, memory);

%%Spu-tests for all boards
strata_testSpuFft(spu_helper, strata.DataFormat.ComplexQ31, strata.DataFormat.ComplexQ31);
strata_testSpuFft(spu_helper, strata.DataFormat.ComplexQ31, strata.DataFormat.ComplexQ15);
strata_testSpuFft(spu_helper, strata.DataFormat.ComplexQ15, strata.DataFormat.ComplexQ31);
strata_testSpuFft(spu_helper, strata.DataFormat.ComplexQ15, strata.DataFormat.ComplexQ15);

strata_testSpuNci(spu_helper, 4, strata.DataFormat.ComplexQ31, strata.DataFormat.Q31);
strata_testSpuNci(spu_helper, 12, strata.DataFormat.ComplexQ31, strata.DataFormat.Q31);
strata_testSpuNci(spu_helper, 24, strata.DataFormat.ComplexQ31, strata.DataFormat.Q31);

strata_testSpuThresholding(spu_helper, 1);
strata_testSpuThresholding(spu_helper, 2);

strata_testSpuPsd(spu_helper);

%%Spu-tests only for boards with a B-step Aurix
%strata_testSpuFft(spu_helper, strata.DataFormat.ComplexQ31, strata.DataFormat.Q31);    %check accuracy of output
%strata_testSpuFft(spu_helper, strata.DataFormat.ComplexQ31, strata.DataFormat.Q15);    %check accuracy of output
%strata_testSpuFft(spu_helper, strata.DataFormat.ComplexQ15, strata.DataFormat.Q31);    %check accuracy of output
%strata_testSpuFft(spu_helper, strata.DataFormat.ComplexQ15, strata.DataFormat.Q15);    %check accuracy of output
%strata_testSpuFft(spu_helper, strata.DataFormat.Q31, strata.DataFormat.ComplexQ31);
%strata_testSpuFft(spu_helper, strata.DataFormat.Q31, strata.DataFormat.ComplexQ15);
%strata_testSpuFft(spu_helper, strata.DataFormat.Q31, strata.DataFormat.Q31);    %check accuracy of output
%strata_testSpuFft(spu_helper, strata.DataFormat.Q31, strata.DataFormat.Q15);    %check accuracy of output
%%FFT input format with real16 isn't allowed when FFT addressing mode is transpose
%strata_testSpuFft(spu_helper, strata.DataFormat.Q15, strata.DataFormat.ComplexQ31); %illegal input format
%strata_testSpuFft(spu_helper, strata.DataFormat.Q15, strata.DataFormat.ComplexQ15); %illegal input format
%strata_testSpuFft(spu_helper, strata.DataFormat.Q15, strata.DataFormat.Q31);    %illegal input format
%strata_testSpuFft(spu_helper, strata.DataFormat.Q15, strata.DataFormat.Q15);    %illegal input format

%strata_testSpuNci(spu_helper, 12, strata.DataFormat.ComplexQ31, strata.DataFormat.Q15);
%strata_testSpuNci(spu_helper, 12, strata.DataFormat.ComplexQ15, strata.DataFormat.Q15);
%strata_testSpuNci(spu_helper, 12, strata.DataFormat.ComplexQ15, strata.DataFormat.Q15);
%strata_testSpuNci(spu_helper, 12, strata.DataFormat.ComplexQ31, strata.DataFormat.Q15);
%strata_testSpuNci(spu_helper, 12, strata.DataFormat.ComplexQ15, strata.DataFormat.Q15);
%strata_testSpuNci(spu_helper, 12, strata.DataFormat.ComplexQ15, strata.DataFormat.Q15);
%strata_testSpuNci(spu_helper, 4, strata.DataFormat.ComplexQ15, strata.DataFormat.Q15);
%strata_testSpuNci(spu_helper, 24, strata.DataFormat.ComplexQ15, strata.DataFormat.Q15);

close all;
disp('All SPU-tests done!');

