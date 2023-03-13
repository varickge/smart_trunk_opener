classdef ISpi < handle
    properties (Hidden = true, SetAccess = private)
        h
    end

    methods

        function obj = ISpi(handle)
            obj.h = handle;
        end

        function maxTransfer = getMaxTransfer(obj)
            maxTransfer = strata.wrapper_matlab(obj, 'getMaxTransfer');
        end

        function configure(obj, devId, flags, wordSize, clockSpeed)
            devId = strata.Conversion.toInt('uint8', devId);
            flags = strata.Conversion.toInt('uint8', flags);
            wordSize = strata.Conversion.toInt('uint8', wordSize);
            clockSpeed = strata.Conversion.toInt('uint32', clockSpeed);
            
            strata.wrapper_matlab(obj, 'configure', devId, flags, wordSize, clockSpeed);
        end

        function data = read8(obj, devId, count, keepSel)
            if nargin < 4
                keepSel = false;
            end
            devId = strata.Conversion.toInt('uint8', devId);
            count = strata.Conversion.toInt('uint32', count);
            keepSel = logical(keepSel);
            
            data = strata.wrapper_matlab(obj, 'read8', devId, count, keepSel);
        end

        function data = read16(obj, devId, count, keepSel)
            if nargin < 4
                keepSel = false;
            end
            devId = strata.Conversion.toInt('uint8', devId);
            count = strata.Conversion.toInt('uint32', count);
            keepSel = logical(keepSel);
           
            data = strata.wrapper_matlab(obj, 'read16', devId, count, keepSel);
        end

        function data = read32(obj, devId, count, keepSel)
            if nargin < 4
                keepSel = false;
            end
            devId = strata.Conversion.toInt('uint8', devId);
            count = strata.Conversion.toInt('uint32', count);
            keepSel = logical(keepSel);
            
            data = strata.wrapper_matlab(obj, 'read32', devId, count, keepSel);
        end

        function write8(obj, devId, data, keepSel)
            if nargin < 4
                keepSel = false;
            end
            devId = strata.Conversion.toInt('uint8', devId);
            data = strata.Conversion.toInt('uint8', data);
            keepSel = logical(keepSel);
            
            strata.wrapper_matlab(obj, 'write8', devId, data, keepSel);
        end

        function write16(obj, devId, data, keepSel)
            if nargin < 4
                keepSel = false;
            end
            devId = strata.Conversion.toInt('uint8', devId);
            data = strata.Conversion.toInt('uint16', data);
            keepSel = logical(keepSel);
           
            strata.wrapper_matlab(obj, 'write16', devId, data, keepSel);
        end

        function write32(obj, devId, data, keepSel)
            if nargin < 4
                keepSel = false;
            end
            devId = strata.Conversion.toInt('uint8', devId);
            data = strata.Conversion.toInt('uint32', data);
            keepSel = logical(keepSel);
            
            strata.wrapper_matlab(obj, 'write32', devId, data, keepSel);
        end

        function dataRead = transfer8(obj, devId, dataWrite, keepSel)
            if nargin < 4
                keepSel = false;
            end
            devId = strata.Conversion.toInt('uint8', devId);
            dataWrite = strata.Conversion.toInt('uint8', dataWrite);
            keepSel = logical(keepSel);
            
            dataRead = strata.wrapper_matlab(obj, 'transfer8', devId, dataWrite, keepSel);
        end

        function dataRead = transfer16(obj, devId, dataWrite, keepSel)
            if nargin < 4
                keepSel = false;
            end
            devId = strata.Conversion.toInt('uint8', devId);
            dataWrite = strata.Conversion.toInt('uint16', dataWrite);
            keepSel = logical(keepSel);
           
            dataRead = strata.wrapper_matlab(obj, 'transfer16', devId, dataWrite, keepSel);
        end

        function dataRead = transfer32(obj, devId, dataWrite, keepSel)
            if nargin < 4
                keepSel = false;
            end
            devId = strata.Conversion.toInt('uint8', devId);
            dataWrite = strata.Conversion.toInt('uint32', dataWrite);
            keepSel = logical(keepSel);
            
            dataRead = strata.wrapper_matlab(obj, 'transfer32', devId, dataWrite, keepSel);
        end

    end

end
