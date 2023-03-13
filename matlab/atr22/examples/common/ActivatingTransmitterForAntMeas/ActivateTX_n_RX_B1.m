function ActivateTX_n_RX_B1(register,tx,desiredFreq,TXPower,rx)
    % Resets the ATR22
    register.write("SEQ_MAIN_CONF", 0x0022)
    pause(1);

    if (strcmp(tx,'TX1') || strcmp(tx,'TX2') )
        RegisterSettings=convert_Presilicon2MatlabRegisters((['01_LO_' tx '_OW_A2.txt']));% register.write(RegisterSettings)
        sizeofSettings=size(RegisterSettings);
        for j=1:sizeofSettings(1)
            register.write(RegisterSettings{j,1},RegisterSettings{j,2})
        end
    else
        error('It is not Allowed TX definition it can be either TX1 or TX2')
    end
    
    if (strcmp(rx,'RX1') || strcmp(rx,'RX2') )  
        RegisterSettings=convert_Presilicon2MatlabRegisters((['02_' rx '_OW_A2.txt']));
        sizeofSettings=size(RegisterSettings);
        for j=1:sizeofSettings(1)
            register.write(RegisterSettings{j,1},RegisterSettings{j,2})
        end
        register.write("PC0_AGC", hex2dec('000E'))
        register.write("AOC_TH_0", hex2dec('015E')) 
        register.write("AOC_TH_1", hex2dec('041A'))
        register.write("AOC_STP_0", hex2dec('0001'))
        register.write("AOC_STP_1", hex2dec('0003'))
    else
        warning('It is not Allowed RX definition. RX is disabled!')
    end
    

    AFC_Dur=(double(register.read('VCO_AFC_DURATION')))/38.4e6;
%     AFC_Dur=8e-6;
%     register.write('VCO_AFC_DURATION',round((38.4e6*AFC_Dur)-2));
% i-	Decide desired Frequency on RF side: for example 24.125GHz
% Decide desired Frequency on RF side: for example 24.125GHz
% Decide AFC counting time in real time: for example: 3.028usec
% Convert this time to register value in terms of Sys Clk, 'VCO_AFC_DURATION'= 0x0073 = 115
% Find the 24 bits AFC_Ref value and divide into 2 registers.




    AFC_Ref=round(desiredFreq/(8/AFC_Dur));
    register.write("VCO_AFC_REF0", bitand(65535,AFC_Ref));
    register.write("VCO_AFC_REF1", bitshift(bitand(hex2dec('FF0000'),AFC_Ref),-16));
    if TXPower>63
        warning('You are trying to exceed max power. TX power is set to its max value "63".')
        TXPower=63;
    end

    if strcmp(tx,'TX1') 
        register.write("TX1_PC0_CONF", bitshift(TXPower,1)+1);
%         register.write("TX1_PC1_CONF", bitshift(TXPower,1)+1);
%         register.write("TX2_PC0_CONF", bitshift(TXPower,1)+0);
%         register.write("TX2_PC1_CONF", bitshift(TXPower,1)+0);
    elseif strcmp(tx,'TX2') 
%         register.write("TX1_PC0_CONF", bitshift(TXPower,1)+0);
%         register.write("TX1_PC1_CONF", bitshift(TXPower,1)+0);
        register.write("TX2_PC0_CONF", bitshift(TXPower,1)+1);
%         register.write("TX2_PC1_CONF", bitshift(TXPower,1)+1);
    end
    
%     register.write("VCO_DAC_VALUE", 0x01B8)
%     register.write("VCO_AFC_CONF", 0x020B) % AFC in tracking mode
    
%     register.write("VCO_AFC_CONF", 	0x010B) % AFC with calibration
    
    

    
    register.write("SEQ_MAIN_CONF.SEQ_EXECUTE", 1)
end