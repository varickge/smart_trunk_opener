classdef IRadarAtr22RegistersTest < matlab.unittest.TestCase
    
    properties
        board
        atr22
        registers
    end
    
    methods(TestClassSetup)
        function connectBoard(obj)% rename to obj rename function to connect to board
            obj.board = strata.Connection.withAutoAddress();
            [vid, pid] = obj.board.getIds();
            fprintf('RBB vid = 0x%x, pid = 0x%x\n', vid, pid);
            obj.atr22 = obj.board.getComponent('IRadarAtr22', 0);
            obj.registers = obj.atr22.getIRegisters();
        end
    end
    
    methods(Test)
        
        function testRegisterSingle(obj)
            disp('Testcase: write and read single registers via register interface');
            
            writeVal = 128;
            % writing FRAME1_LIST_REP to 128
            obj.registers.write('0x0314', writeVal);
            % reading FRAME1_LIST_REP
            readVal = obj.registers.read('0x0314');
            assert(isequal(readVal, writeVal));
        end
        
        function testRegisterBurst(obj)
            disp('Testcase: burst write and burst read registers via register interface');
            
            startAddress = 0x0001;
            values = {'0x000A'; '0x090A'; '0x120A'; '0x1B01'};
            obj.registers.write(startAddress, values);
            readValues = obj.registers.read(startAddress, length(values));
            expectedValues = strata.Conversion.toInt('uint16', values);
            assert(isequal(readValues, expectedValues));
            
        end
        
        function testRegisterBatch(obj)
            disp('Testcase: batch write and burst read registers via register interface');
            
            regAddrs = {'0x0001'; '0x0003'; '0x0300'; '0x1033'};
            values = {'0x000B'; '0x090B'; '0x4030'; '0x0075'};
            regBatch = [regAddrs, values];
            obj.registers.writeBatch(regBatch);
            readValues = obj.registers.readBatch(regAddrs);
            expectedValues = strata.Conversion.toInt('uint16', values);
            assert(isequal(readValues, expectedValues));
            
        end
        
        function testSetAndClearBits(obj)
            disp('Testcase: set and clear bits using register interfaces');
            
            regAddr = 0x3001;  % AGC register
            bitMask = 0x0001;
            % set bits
            obj.registers.setBits(regAddr, bitMask);
            readVal = obj.registers.read(regAddr);
            assert(isequal(1, bitand(readVal, bitMask)));
            % clear bits
            obj.registers.clearBits(regAddr, bitMask);
            readVal = obj.registers.read(regAddr);
            assert(isequal(0, bitand(readVal, bitMask)));
        end
        
        function testModifyBits(obj)
            disp('Testcase: modify bits using register interfaces');
            regAddr = 0x3001;  % AGC register
            clearBitMask = 0xAAAA;
            setBitMask = 0x1111;
            % modify bits
            obj.registers.modifyBits(regAddr, clearBitMask, setBitMask);
            readVal = obj.registers.read(regAddr);
            assert(isequal(setBitMask, bitand(readVal, setBitMask)));
        end
        
    end
end
