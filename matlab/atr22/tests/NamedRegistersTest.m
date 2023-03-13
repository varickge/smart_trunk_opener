classdef NamedRegistersTest < matlab.unittest.TestCase
    
    properties
        board
        atr22
        register
    end
    
    methods(TestClassSetup)
        function connectBoard(obj)% rename to obj rename function to connect to board
            obj.board = strata.Connection.withAutoAddress();
            [vid, pid] = obj.board.getIds();
            fprintf('RBB vid = 0x%x, pid = 0x%x\n', vid, pid);
            obj.atr22 = obj.board.getComponent('IRadarAtr22',0);
            obj.atr22.reset(true)
            obj.register = strata.NamedRegister.NamedRegister(obj.atr22.getIRegisters(), 'atr22_regmap_from_essence.json');
        end
    end
    
    methods(Test)
        function testRegisterSingleName(obj)
            disp('Testcase: acces via register name: FRAME1_LIST_REP');
            
            writeVal = 128;
            obj.register.write('FRAME1_LIST_REP', writeVal);
            readVal = obj.register.read('FRAME1_LIST_REP');
            assert(isequal(readVal, writeVal));
        end
        function testRegisterSingleAddress(obj)
            disp('Testcase: acces via register address: FRAME1_LIST_REP = 0x0314');
            
            writeVal = 64;
            obj.register.write('0x0314', writeVal);
            readVal = obj.register.read(0x0314);
            assert(isequal(readVal, writeVal));
            
        end
        function testRegisterElement(obj)
            disp('Testcase: acces via element name notation: AGC.PC0_ABB_GAIN');
            
            agcGainValuePc0 = 5;
            obj.register.write("AGC.PC0_ABB_GAIN", agcGainValuePc0);
            agcGainValuePc0Read = obj.register.read('AGC.PC0_ABB_GAIN');
            assert(isequal(agcGainValuePc0, agcGainValuePc0Read));
        end
        
        function testRegisterMultiple(obj)
            disp('Testcase: access multiple registers with name notation');
            
            startAddress = 'TRIG0_CONF';
            values = {'0x000A'; '0x090A'; '0x120A'; '0x1B01'};
            obj.register.write(startAddress, values);
            readValues = obj.register.read(startAddress, length(values));
            expectedValues = strata.Conversion.toInt('uint16', values);
            assert(isequal(readValues, expectedValues));
        end
        
        function testRegisterWriteArray(obj)
            disp('Testcase: acces register as a array of name value pairs');
            
            regAddrS = {'TRIG0_CONF'; 'TRIG3_CONF'; 'SEQ_MAIN_CONF'; 'VCO_AFC_DURATION'};
            values = {'0x000B'; '0x090B'; '0x4030'; '0x0075'};
            regBatch = [regAddrS, values];
            obj.register.write(regBatch);
            readValues = obj.register.read(regAddrS);
            expectedValues = strata.Conversion.toInt('uint16', values);
            assert(isequal(readValues, expectedValues));
        end
        
        function testRegisterWriteMixedArray(obj)
            disp('Testcase: access register in mixed notations');
            
            regAddrs = {'TRIG0_CONF'; 'AGC.PC0_ABB_GAIN'; '0x0314'; 'TRIG1_CONF'};
            values = {10; 3; 64; 11};
            regBatch = [regAddrs, values];
            obj.register.write(regBatch);
            readValues = obj.register.read(regAddrs);
            expectedValues = strata.Conversion.toInt('uint16', values);
            assert(isequal(readValues, expectedValues));
            
        end
        
    end
end
