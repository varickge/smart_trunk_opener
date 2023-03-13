classdef IRadarAvianTest < matlab.unittest.TestCase
    
    properties
        board
        avian
    end
    
    methods(TestClassSetup)
        function connectBoard(obj)% rename to obj rename function to connect to board
            obj.board = strata.Connection.withAutoAddress();
            [vid, pid] = obj.board.getIds();
            fprintf('RBB vid = 0x%x, pid = 0x%x\n', vid, pid);
            obj.avian = obj.board.getComponent('IRadarAvian', 0);
        end
    end
    
    methods(Test)
        function testResetPin(obj)
            pins = obj.avian.getIPinsAvian();
            pins.reset();
        end
        
        function testSetReset(obj)
            pins = obj.avian.getIPinsAvian();
            registers = obj.avian.getIRegisters();
            pins.setResetPin(false);
            pause(0.01);
            obj.verifyError(@()registers.read(obj.avian.CHIP_ID), ?MException);
            pins.setResetPin(true);
            pause(0.01);
        end
        
        function testRegisterAccess(obj)
            registers = obj.avian.getIRegisters();
            supported_chips = [ strata.Conversion.toInt('uint32', '0x303'), ... % BGT60TR13C
                strata.Conversion.toInt('uint32', '0x504'), ... % BGT60ATR24C
                ];
            % configure SPI high speed compensation and wait cycles
            registers.write(obj.avian.SFCTL, '0x100000');
            % check read write and modify bits register access
            backup_value = registers.read(obj.avian.CSI_0);
            registers.write(obj.avian.CSI_0, '0x1234');
            registers.modifyBits(obj.avian.CSI_0, 0, 1);
            
            obj.verifyEqual(registers.read(obj.avian.CSI_0), strata.Conversion.toInt('uint32', '0x1235'));
            % restore value
            registers.write(obj.avian.CSI_0, 0);
            obj.verifyEqual(registers.read(obj.avian.CSI_0), backup_value);
            
            %read and compare chip id
            assert(ismember(registers.read(obj.avian.CHIP_ID), supported_chips), ...
                'IRadarAvianTest:testRegisters', ...
                'Invalid chip ID read from register');
        end
        
        function testProtocol(obj)
            protocol = obj.avian.getIProtocolAvian();
            pins = obj.avian.getIPinsAvian();
            
            command_sequence = config_easy_scenario();
            %configure device
            protocol.execute(command_sequence);
            
            %check irq status
            obj.verifyEqual(false, pins.getIrqPin());
            
            %Initiating measurement sequence
            protocol.setBits(obj.avian.MAIN, 1);
            pause(0.2);
            
            %check new irq status
            obj.verifyEqual(pins.getIrqPin(), true);
            
            % stop measurement sequence
            protocol.execute(strata.IProtocolAvian.Write(obj.avian.MAIN, '0x1e827c'));
            pause(0.1);
            
            %check new irq status
            obj.verifyEqual(false, pins.getIrqPin());
        end
    end
end
