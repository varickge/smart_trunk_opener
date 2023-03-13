classdef DataAvianTest < matlab.unittest.TestCase
    
    properties
        board
        avian
        pins
        regs
        protocol
        data
        databridge
        dataIndex
    end
    
    methods(TestClassSetup)
        function connectBoard(obj)% rename to obj rename function to connect to board
            obj.board = strata.Connection.withAutoAddress();
            [vid, pid] = obj.board.getIds();
            fprintf('RBB vid = 0x%x, pid = 0x%x\n', vid, pid);
            obj.avian = obj.board.getComponent('IRadarAvian', 0);
            obj.pins = obj.avian.getIPinsAvian();
            obj.regs = obj.avian.getIRegisters();
            obj.protocol = obj.avian.getIProtocolAvian();
            obj.data = obj.board.getIData();
            obj.databridge = obj.board.getIBridgeData();
            obj.dataIndex = obj.avian.getDataIndex();
        end
    end
    
    methods(Test)
        function testDataAvian(obj)
            % stop any ongoing data transmission
            obj.data.stop(obj.dataIndex);
            
            % reset device
            obj.pins.reset();
            
            %configure SPI high speed compensation and wait cycles
            obj.regs.write(obj.avian.SFCTL, '0x100000');
            
            % configure data readoutclear
            % get readout base address based on chipid
            readout_base = obj.avian.getReadoutBase(obj.regs.read(obj.avian.CHIP_ID));
            framesize = 1024;
            sampleSize = 2;
            
            % configure
            data_settings = strata.DataSettingsBgtRadar([readout_base framesize], 0);
            data_properties.format = strata.DataFormat.Raw16;
            
            obj.data.configure(obj.dataIndex, data_properties, data_settings);
            
            obj.databridge.setFrameBufferSize(framesize * sampleSize);
            obj.databridge.setFrameQueueSize(16);
            obj.databridge.startStreaming();
            
            obj.data.start(obj.dataIndex)
            
            % configuring device
            command_sequence = config_easy_scenario;
            obj.protocol.execute(command_sequence);
            
            % Initiating measurement sequence...
            obj.regs.modifyBits(obj.avian.MAIN, 0, 1);
            
            frames_expected = 10;
            while frames_expected > 0
                receive_buffer = obj.board.getFrame(1000);
                radar_data = typecast(receive_buffer,'uint16');
                
                % check receive frame size according to configuration
                assert(isequal(numel(radar_data), 64 * 16), ...
                    'DataAvianTest:FrameSize', ...
                    'Invalid frame size received');
                
                % check if the valid data is within 12 bits
                assert(max(radar_data) < 2^12, ...
                    'DataAvianTest:DataRange', ...
                    'Invalid data received');
                frames_expected = frames_expected - 1;
            end
            
            assert(frames_expected == 0, ...
                'DataAvianTest:numFrames', ...
                'All frames not received');
            
            % stopping measurement
            obj.regs.write(obj.avian.MAIN, '0x1e827c');
            obj.data.stop(obj.dataIndex);
            obj.databridge.stopStreaming();
        end
    end
    
end
