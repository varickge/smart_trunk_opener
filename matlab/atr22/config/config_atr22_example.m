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
% config_atr22_example() create register configuration set for ATR22

%   Usage:
%   [command_array] = config_atr22_example();
%
%   Return values:
%   'commands' contains an array of commands to be run via
%   IRegister.write
%


function [commands] = config_atr22_example()

commands = {
    'TRIG0_CONF', 0x0023;
    'TRIG1_CONF', 0x1023;
    'TRIG2_CONF', 0x1201;
    'TRIG3_CONF', 0x1B01;
    'IR_STATUS', 0x0000;
    'IR_EN', 0x1100;
    'IR_CLEAR', 0x0000;
    'IR_TRIG_MAP', 0x000A;
    'CLK_CONF', 0x0048;
    'XOSC_CLK_CONF', 0x0008;
    'RC_CLK_CONF', 0x0000;
    'RC_T_TRIM', 0x0180;
    'RC_TRIM_VAL', 0x0000;
    'TEST', 0x0000;
    'I2C_CONF', 0x3333;
    'I2C_SPEED', 0x0000;
    'CHIP_TYPE', 0x0000;
    'CHIP0_UID', 0x0000;
    'CHIP1_UID', 0x0000;
    'CHIP2_UID', 0x0000;
    'TEMP0_CAL', 0x0000;
    'TEMP1_CAL', 0x0000;
    'CHIP_FUSING0_UID', 0x0000;
    'CHIP_FUSING1_UID', 0x0000;
    'CHIP_FUSING2_UID', 0x0000;
    'TEMP_FUSING0_CAL', 0x0000;
    'TEMP_FUSING1_CAL', 0x0000;
    'EFUSE', 0xC000;
    'EFUSE_DIV', 0x0000;
    'SEQ_MAIN_CONF', 0x0020;
    'FRAME_COUNTER', 0x000F;
    'FRAME_REP_CONF', 0x0000;
    'FRAME0_TIME', 0x926D;
    'FRAME0_LIST_REP', 0x0080;
    'FRAME0_HEATING', 0x0002;
    'FRAME0_LIST0_CONF', 0x0001;
    'FRAME0_LIST1_CONF', 0x0000;
    'FRAME0_LIST2_CONF', 0x0000;
    'FRAME0_LIST3_CONF', 0x0000;
    'FRAME1_TIME', 0x0000;
    'FRAME1_LIST_REP', 0x0000;
    'FRAME1_HEATING', 0x0000;
    'FRAME1_LIST0_CONF', 0x0000;
    'FRAME1_LIST1_CONF', 0x0000;
    'FRAME1_LIST2_CONF', 0x0000;
    'FRAME1_LIST3_CONF', 0x0000;
    'PC_CONF0_TIME', 0x9605;
    'PC_CONF0_AVG', 0x0000;
    'PC_CONF1_TIME', 0x0000;
    'PC_CONF1_AVG', 0x0000;
    'PC_CONF2_TIME', 0x0000;
    'PC_CONF2_AVG', 0x0000;
    'PC_CONF3_TIME', 0x0000;
    'PC_CONF3_AVG', 0x0000;
    'T_BOOT_VCO_FS', 0x0F00;
    'T_BOOT_TXCHAIN', 0x000A;
    'T_BOOT_RXCHAIN', 0x0032;
    'T_BOOT_ADC', 0x02BC;
    'T_BOOT_BANDGAP', 0x1140;
    'T_BOOT_REF_CLK', 0x728E;
    'T_BOOT_EXT_LDO', 0x5DC7;
    'T_REBOOT', 0x0028;
    'T_AFC', 0x03C4;
    'SEQ_TRIG_MAP_IRQ', 0x0400;
    'SEQ_TRIG_MAP_AP', 0x0000;
    'SEQ_TRIG_MAP_LDO', 0x0000;
    'SEQ_TRIG_MAP_BT', 0x0000;
    'SEQ_EN_OW', 0x0060;
    'VCO_T_RAMP_DN', 0x0009;
    'VCO_T_DAC', 0x012C;
    'VCO_TRIG_MAP', 0x0000;
    'VCO_PC0_DAC_OFFSET', 0x0000;
    'VCO_PC1_DAC_OFFSET', 0x0000;
    'VCO_PC2_DAC_OFFSET', 0x0000;
    'VCO_PC3_DAC_OFFSET', 0x0000;
    'VCO_DAC_VALUE', 0x01B0;
    'VCO_AFC_CONF', 0x010B;
    'VCO_AFC_DURATION', 0x0073;
    'VCO_AFC_CNT0', 0x2398;
    'VCO_AFC_CNT1', 0x0000;
    'VCO_AFC_REF0', 0x2397;
    'VCO_AFC_REF1', 0x0000;
    'VCO_AFC_TH0', 0x0103;
    'VCO_AFC_TH1', 0x030A;
    'VCO_TEST0', 0x0000;
    'VCO_TEST1', 0x0044;
    'ADC_GLOB_CONF', 0x1000;
    'ADC_CONF', 0x5C49;
    'ADC_T_SAMPLE', 0x0014;
    'ADC_T_SENSOR', 0x00A4;
    'ADC_SENSE_CONF', 0x0000;
    'ADC_ENV_CHK_S1_REF', 0x0000;
    'ADC_ENV_CHK_S2_REF', 0x0000;
    'ADC_ENV_CHK_S1_DRIFT', 0x0000;
    'ADC_ENV_CHK_S2_DRIFT', 0x0000;
    'ADC_TRIG_MAP', 0x0000;
    'ADC_TEST_IN', 0x0000;
    'ADC_TEST0_OUT', 0x0004;
    'TX_T_BIAS', 0x0002;
    'TX_T_BUF', 0x0001;
    'TX_T_RF', 0x0003;
    'TX_T_RAMP_DN', 0x0008;
    'TX_TRIG_MAP', 0x0000;
    'TX1_PC0_CONF', 0x0065;
    'TX1_PC1_CONF', 0x0000;
    'TX1_PC2_CONF', 0x0000;
    'TX1_PC3_CONF', 0x0000;
    'TX2_PC0_CONF', 0x0000;
    'TX2_PC1_CONF', 0x0000;
    'TX2_PC2_CONF', 0x0000;
    'TX2_PC3_CONF', 0x0000;
    'TX_CONF', 0x0073;
    'TX1_TEST', 0x0010;
    'TX2_TEST', 0x0010;
    'RX_T_BIAS', 0x0005;
    'RX_T_RF', 0x0007;
    'RX_T_MIX', 0x0006;
    'RX1_PC0_CONF', 0x0000;
    'RX1_PC1_CONF', 0x0000;
    'RX1_PC2_CONF', 0x0000;
    'RX1_PC3_CONF', 0x0000;
    'RX2_PC0_CONF', 0x0001;
    'RX2_PC1_CONF', 0x0000;
    'RX2_PC2_CONF', 0x0000;
    'RX2_PC3_CONF', 0x0000;
    'RX_TRIG_MAP', 0x0000;
    'RX1_TEST', 0x0000;
    'RX2_TEST', 0x0000;
    'RX_MIX_TEST', 0x0000;
    'RX_TEST', 0x0000;
    'RX_BITE0', 0x0000;
    'RX_BITE1', 0x0000;
    'RXABB_T_BIAS', 0x0001;
    'RXABB_HF_DELAY', 0x0007;
    'RXABB_HF_ON_T', 0x0270;
    'RXABB_PC0_CONF', 0x0001;
    'RXABB_PC1_CONF', 0x0001;
    'RXABB_PC2_CONF', 0x0001;
    'RXABB_PC3_CONF', 0x0001;
    'RXABB_TEST', 0x0000;
    'RXABB_TRIG_MAP', 0x0000;
    'IMBALANCE_COMP', 0x0000;
    'AGC', 0x000A;
    'AGC_TH_MIN', 0x0200;
    'AGC_TH_MAX', 0x0E00;
    'AGC_TH_DIFF', 0x0320;
    'AOC_CONF', 0x0055;
    'AOC_PC0_OFFSET_I', 0x003C;
    'AOC_PC0_OFFSET_Q', 0x0010;
    'AOC_PC1_OFFSET_I', 0x0000;
    'AOC_PC1_OFFSET_Q', 0x0000;
    'AOC_PC2_OFFSET_I', 0x0000;
    'AOC_PC2_OFFSET_Q', 0x0000;
    'AOC_PC3_OFFSET_I', 0x0000;
    'AOC_PC3_OFFSET_Q', 0x0000;
    'AOC_TH_STP_0', 0x2578;
    'AOC_TH_STP_1', 0x7068;
    'FT0_CONF', 0x108F;
    'FT1_CONF', 0x008C;
    'FT2_CONF', 0x008C;
    'FT3_CONF', 0x008C;
    'FT_TEST', 0x0000;
    'FT0_EXCLUDE', 0xFFFF;
    'FT1_EXCLUDE', 0xFFFF;
    'FT2_EXCLUDE', 0xFFFF;
    'FT3_EXCLUDE', 0xFFFF;
    'FT4_EXCLUDE', 0xFFFF;
    'FT5_EXCLUDE', 0xFFFF;
    'FT6_EXCLUDE', 0xFFFF;
    'FT7_EXCLUDE', 0xFFFF;
    'THRESHOLD0_CONF', 0x0030;
    'THRESHOLD0_MANUAL', 0x01F4;
    'THRESHOLD0_ADAPTIVE', 0x0000;
    'THRESHOLD0_RESULT', 0x0000;
    'THRESHOLD1_CONF', 0x0000;
    'THRESHOLD1_MANUAL', 0x01F4;
    'THRESHOLD1_ADAPTIVE', 0x0000;
    'THRESHOLD1_RESULT', 0x0000;
    'THRESHOLD2_CONF', 0x0000;
    'THRESHOLD2_MANUAL', 0x01F4;
    'THRESHOLD2_ADAPTIVE', 0x0000;
    'THRESHOLD2_RESULT', 0x0000;
    'THRESHOLD3_CONF', 0x0000;
    'THRESHOLD3_MANUAL', 0x01F4;
    'THRESHOLD3_ADAPTIVE', 0x0000;
    'THRESHOLD3_RESULT', 0x0000;
    'DRDP_FNOISE0_CONST', 0x0000;
    'DRDP_FNOISE1_CONST', 0x0000;
    'DRDP_FNOISE2_CONST', 0x0000;
    'DRDP_FNOISE3_CONST', 0x0000;
    'DRDP_FNOISE4_CONST', 0x0000;
    'DRDP_FNOISE5_CONST', 0x0000;
    'DRDP_FNOISE6_CONST', 0x0000;
    'DRDP_FNOISE7_CONST', 0x0000;
    'MEM_RAW', 0x0000;
    'MEM_RAW2', 0x0000;
    'MEM_FT', 0x0100;
    'MEM_TRG', 0x0200;
    'MEM_SENS', 0x0280;
    'DRDP_TRIG_MAP_TRG', 0x0001;
    'DRDP_TRIG_MAP_CF', 0x0008;
    'WINDOW0', 0x0000;
    'WINDOW1', 0x0000;
    'WINDOW2', 0x0000;
    'WINDOW3', 0x0000;
    'WINDOW4', 0x0000;
    'WINDOW5', 0x0000;
    'WINDOW6', 0x0000;
    'WINDOW7', 0x0000;
    'WINDOW8', 0x0000;
    'WINDOW9', 0x0000;
    'WINDOW10', 0x0000;
    'WINDOW11', 0x0000;
    'WINDOW12', 0x0000;
    'WINDOW13', 0x0000;
    'WINDOW14', 0x0000;
    'WINDOW15', 0x0000;
    'WINDOW16', 0x0000;
    'WINDOW17', 0x0000;
    'WINDOW18', 0x0000;
    'WINDOW19', 0x0000;
    'WINDOW20', 0x0000;
    'WINDOW21', 0x0000;
    'WINDOW22', 0x0000;
    'WINDOW23', 0x0000;
    'WINDOW24', 0x0000;
    'WINDOW25', 0x0000;
    'WINDOW26', 0x0000;
    'WINDOW27', 0x0000;
    'WINDOW28', 0x0000;
    'WINDOW29', 0x0000;
    'WINDOW30', 0x0000;
    'WINDOW31', 0x0000;
    'MBIST', 0x0000;
    };
end
