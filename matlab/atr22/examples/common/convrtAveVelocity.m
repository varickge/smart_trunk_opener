function [averageVelocity]= convrtAveVelocity(TargetData, numofTarget, TH, N_FFT, PRT,lambda,numofTargetfromATR22)
    
   
    for PulseConf=1:2 % PC0 and PC1
        Target_MaxLocations=0;  % Number of frequency bin of the strangest target from atr22      
        rawTarget=TargetData(((PulseConf-1)*2*numofTargetfromATR22)+(1:2*numofTarget)); % PC0 and PC1
        rawTarget=[1 rawTarget];
        counterTHexceedingTarget=0;
        for j0 =1:1:numofTarget
            temp=(bitshift(rawTarget(j0*2),12)+rawTarget(j0*2+1));
            %Target_MaxValue: FFT result magnitude of corresponding freq bin
            Target_MaxValue(j0)=bitshift(bitand(hex2dec('00FF'),rawTarget(j0*2+1)),4)+bitshift(bitand(hex2dec('FF00'),rawTarget(j0*2)),-8);
            if Target_MaxValue(j0)>TH 
                counterTHexceedingTarget=counterTHexceedingTarget+1;
                Target_MaxLocations(j0)=bitand(hex2dec('00FF'),rawTarget(j0*2));
                if Target_MaxLocations(j0)>N_FFT/2
                    Target_MaxLocations(j0)=Target_MaxLocations(j0)-N_FFT;
                end
       
            end
      
        end
        
        if counterTHexceedingTarget
            averageVelocity(PulseConf)=1*mean(Target_MaxLocations(1:counterTHexceedingTarget))* lambda/2/PRT/(N_FFT-1);
        else
            averageVelocity(PulseConf)=0;
        end
    end

end