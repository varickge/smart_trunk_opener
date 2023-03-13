classdef RegisterList < handle
    % RegisterList
    %   class representing a list of device registers
    %   a handle class providing a list of register from json file
    %
    %   methods:
    %   [regStruct, elementStruct] = find(obj, addressInfo)
    %   output = getListOfRegisterName(obj)
    %
    %   methods(Static):
    %   output = createListFromJson(jsonFileName)
    %   [regName, elementName] = processAddressInfo(address)
    
    properties
        registerList    % list of register in structure array
    end
    
    methods
        function obj = RegisterList(json_file_name)
            % RegisterList 
            %   Construct an instance of this class
            obj.registerList = obj.createListFromJson(json_file_name);
        end
        
        function [regStruct, elementStruct] = find(obj, addressInfo)
            % find 
            %   search register list and return register that matches
            %   
            %   Usage:
            %   [regStruct, elementStruct] =  obj.find('0x0001')
            %   [regStruct, elementStruct] =  obj.find('TRIG0_CONF')
            %   [regStruct, elementStruct] =  obj.find(0x0001)
            %
            %   Input:
            %   'addressInfo': address or name of the reigster or element
            %   to find
            %
            %   Return value:
            %   'regStruct': corresponding register struct array
            %   'elementStruct': corresponding element struct
            
            [regName, elementName] = obj.processAddressInfo(addressInfo);
            if isnumeric(regName)
                % addressInfo contains register with address as numeric
                for index = 1:length(obj.registerList)
                    if regName == obj.registerList(index).address
                        regStruct = obj.registerList(index);
                        elementStruct = {};
                        return
                    end
                end
            else
                % addressInfo contains register with name as string
                for i = 1:length(obj.registerList)
                    if strcmp(obj.registerList(i).name, regName)
                        regStruct = obj.registerList(i);
                    end
                end
                if isempty(elementName)
                    % addressInfo contains only register name
                    elementStruct = {};
                    return
                else
                    % addressInfo contains element name: Reg.Element
                    for i = 1:length(regStruct.bslices)
                        if strcmp(elementName, regStruct.bslices(i).name)
                            elementStruct = regStruct.bslices(i);
                            return
                        end
                    end
                end
            end
            
            error('address not found');
        end
        
        function output = getListOfRegisterName(obj)
            % getListOfRegisterName 
            %   get name list of all available registers
            %
            %   Usage:
            %   output = obj.getListOfRegisterName()
            %
            %   Input:
            %   'addressInfo': address or name of the reigster or element
            %
            %   Return value:
            %   'output':  array containing all register names
            
            output = extractfields(obj.registerList, 'name');
        end
    end
    
    methods(Static)
        function output = createListFromJson(jsonFileName)
            % createListFromJson 
            %   parses json file and create register list
            %
            %   Usage:
            %   output = obj.createListFromJson()
            %
            %   Input:
            %   'jsonFileName': path or name of the json file to parse
            %
            %   Return value:
            %   'output':  list of register
            fid = fopen(jsonFileName);
            raw = fread(fid,inf);
            jsonStr = char(raw');
            fclose(fid);
            jsonRegView = jsondecode(jsonStr);
            output = jsonRegView.units.registers;
        end
        
        function [regName, elementName] = processAddressInfo(address)
            % processAddressInfo 
            %   parse the register address info
            %
            %   Usage:
            %   output = obj.processAddressInfo(address)
            %
            %   Input:
            %   'address': address or name of the register and element
            %
            %   Return value:
            %   'regName':  name or address of the reigster
            %   'elementName': name of the element if available
            
            if isnumeric(address)
                % notation = 0x1234;
                regName = address;
                elementName = {};
            elseif ischar(address)
                switch address(1:2)
                    case '0x'
                        % notation = '0x1234'
                        regName = hex2dec(address(3:end));
                        elementName = {};
                    otherwise
                        % notation = 'Reg.Element'
                        nameSplit = strsplit(address, '.');
                        if length(nameSplit) > 1
                            regName = nameSplit{1, 1};
                            elementName = nameSplit{1, 2};
                        else
                            regName = nameSplit;
                            elementName = {};
                        end
                end
            elseif isstring(address)
                % notation = "Reg.Element"
                nameSplit = strsplit(address, '.');
                if length(nameSplit) > 1
                    regName = nameSplit{1, 1};
                    elementName = nameSplit{1, 2};
                else
                    regName = nameSplit;
                    elementName = {};
                end
            else
                error('wrong address format')
            end
            
        end
    end
    
end

