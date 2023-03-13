classdef IRadarAtr22ProtocolTest < matlab.unittest.TestCase
    
    properties
        board
        atr22
        protocol
    end
    
    methods(TestClassSetup)
        function connectBoard(obj)% rename to obj rename function to connect to board
            obj.board = strata.Connection.withAutoAddress();
            [vid, pid] = obj.board.getIds();
            fprintf('RBB vid = 0x%x, pid = 0x%x\n', vid, pid);
            obj.atr22 = obj.board.getComponent('IRadarAtr22', 0);
            obj.protocol = obj.atr22.getIProtocolAtr22();
        end
    end
    
    methods(Test)
        
        function testProtocolSingle(obj)
            disp('Testcase: write and read a single register via protocol interface');
            
            writeVal = 128;
            % writing FRAME1_LIST_REP to 128
            writeCmd = strata.IProtocolAtr22.Write('0x0314', writeVal);
            obj.protocol.executeWrite(writeCmd);
            % reading FRAME1_LIST_REP
            readCmd = strata.IProtocolAtr22.Read('0x0314');
            readValue = obj.protocol.executeRead(readCmd);
            assert(isequal(readValue, writeVal));
        end
        
        function testProtocolBurst(obj)
            disp('Testcase: write burst and read burst via protocol interface');
            
            writeCmds = [...
                strata.IProtocolAtr22.Write('0x0001', '0x000A'); ...
                strata.IProtocolAtr22.Write('0x0002', '0x090A'); ...
                strata.IProtocolAtr22.Write('0x0003', '0x1B01')];
            obj.protocol.executeWrite(writeCmds);
            readCmd = strata.IProtocolAtr22.Read('0x0001');
            readValues = obj.protocol.executeRead(readCmd, 3);
            assert(isequal(readValues(1), strata.Conversion.toInt('uint16', '0x000A')));
            assert(isequal(readValues(2), strata.Conversion.toInt('uint16', '0x090A')));
            assert(isequal(readValues(3), strata.Conversion.toInt('uint16', '0x1B01')));
        end
        
        function testSetBits(obj)
            disp('Testcase: set bits using protocol interfaces');
            
            regAddr = 0x3001;  % AGC register
            bitMask = 0x0001;
            writeCmd = strata.IProtocolAtr22.Write(regAddr, '0x0000');
            obj.protocol.executeWrite(writeCmd);
            obj.protocol.setBits(regAddr,bitMask);
            readCmd  = strata.IProtocolAtr22.Read(regAddr);
            readVal = obj.protocol.executeRead(readCmd);
            assert(isequal(bitMask, bitand(readVal, bitMask)));
        end
        
    end
end
