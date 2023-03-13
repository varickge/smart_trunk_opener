function singleSensorConversion(register, sensorId)
% singleSensorConversion 
%   start the conversion of the given sensor id one singe time

    config_l = {
        'SEQ_EN_OW', 0x0063;
        'RXABB_TEST', 0x0030;
        'ADC_SENSE_CONF.CONV1_SEL', sensorId;
        'ADC_TRIG_MAP', 0x3000;
        'ADC_CONF', 0x5C49;
    };
    register.write('ADC_CONF.ADC_TRIG', 0)
    register.write(config_l)
    register.write('ADC_CONF.ADC_TRIG', 1)
end

