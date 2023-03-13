classdef DataAtr22Test < matlab.unittest.TestCase
    
    properties
        board
        atr22
        register
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
            obj.atr22 = obj.board.getComponent('IRadarAtr22', 0);
            obj.register = strata.NamedRegister.NamedRegister(obj.atr22.getIRegisters(), 'atr22_regmap_from_essence.json');
            obj.protocol = obj.atr22.getIProtocolAtr22();
            obj.data = obj.board.getIData();
            obj.databridge = obj.board.getIBridgeData();
            obj.dataIndex = 0;
            
            % stop any ongoing data transmission
            obj.data.stop(obj.dataIndex);
            
        end
    end
    
    methods(Test)
        function testDataAtr22(obj)
            %% configure data readout
            memoryStartAddress = 0x3800;
            rawDataReadcount = 256 * 2;
            RegSizeInBytes = 2;
            dataSettings = strata.DataSettingsBgtRadar([memoryStartAddress rawDataReadcount], 0);
            data_properties.format = 0;
            obj.data.configure(obj.dataIndex, data_properties, dataSettings);
            
            frameBufferSize = rawDataReadcount * RegSizeInBytes;
            obj.databridge.setFrameBufferSize(frameBufferSize);
            obj.databridge.setFrameQueueSize(16);
            obj.databridge.startStreaming();
            
            obj.data.start(obj.dataIndex)
            
            %% configuring device
            obj.register.write(config_atr22_example())
            
            %% start sequencer
            obj.register.write("SEQ_MAIN_CONF.SEQ_EXECUTE", 1)
            
            %% receive data
            
            frames_expected = 25;
            while frames_expected > 0
                frame = obj.board.getFrame(400);
                framData = typecast(frame,'uint16');
                
                % check receive frame size according to configuration
                assert(isequal(numel(framData), 512), ...
                    'DataAtr22Test:FrameSize', ...
                    'Invalid frame size received');
                frames_expected = frames_expected -1;
            end
            
            assert(frames_expected == 0, ...
                'DataAtr22Test:numFrames', ...
                'All frames not received');
            
            %% stop sequencer
            obj.register.write("SEQ_MAIN_CONF.SEQ_EXECUTE", 1)
            
            %% stop any ongoing data transmission
            obj.data.stop(obj.dataIndex);
            obj.databridge.stopStreaming();
            
        end
    end
    
end
