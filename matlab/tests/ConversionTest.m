classdef ConversionTest < matlab.unittest.TestCase
    % ConversionTest unit tests

    methods(Test)
        function testToUint8(obj)
            obj.verifyError(@()strata.Conversion.toInt('uint8', -1), ?MException);
            obj.verifyError(@()strata.Conversion.toInt('uint8', '10'), ?MException);
            obj.verifyError(@()strata.Conversion.toInt('uint8', 'ab'), ?MException);
            obj.verifyEqual(strata.Conversion.toInt('uint8', 0), uint8(0));
            obj.verifyEqual(strata.Conversion.toInt('uint8', 255), uint8(255));
            obj.verifyEqual(strata.Conversion.toInt('uint8', '0xFF'), uint8(255));
            obj.verifyEqual(strata.Conversion.toInt('uint8', '0b11111111'), uint8(255));
            obj.verifyError(@()strata.Conversion.toInt('uint8', 256), ?MException);
            obj.verifyError(@()strata.Conversion.toInt('uint8', '0x100'), ?MException);
            obj.verifyError(@()strata.Conversion.toInt('uint8', '0b100000000'), ?MException);
        end
        
        function testToInt16(obj)
            obj.verifyError(@()strata.Conversion.toInt('int16', -32769), ?MException);
            obj.verifyEqual(strata.Conversion.toInt('int16', -32768), int16(-32768));
            obj.verifyEqual(strata.Conversion.toInt('int16', 32767), int16(32767));
            obj.verifyError(@()strata.Conversion.toInt('int16', 32768), ?MException);
        end

        function testToBool(obj)
            obj.verifyEqual(strata.Conversion.toBool(true), true);
            obj.verifyEqual(strata.Conversion.toBool(1), true);
            obj.verifyEqual(strata.Conversion.toBool('0x1'), true);
            obj.verifyEqual(strata.Conversion.toBool('0b1'), true);
            obj.verifyEqual(strata.Conversion.toBool(false), false);
            obj.verifyEqual(strata.Conversion.toBool(0), false);
            obj.verifyEqual(strata.Conversion.toBool('0x0'), false);
            obj.verifyEqual(strata.Conversion.toBool('0b0'), false);

            obj.verifyError(@()strata.Conversion.toBool(2), ?MException);
            obj.verifyError(@()strata.Conversion.toBool('0x3'), ?MException);
            obj.verifyError(@()strata.Conversion.toBool('0b100'), ?MException);
        end
        
        function testArrayConversion(obj)
            obj.verifyEqual(strata.Conversion.toInt('uint8', {'0b11111111', '0x12'}), [uint8(255), uint8(18)]);
            obj.verifyEqual(strata.Conversion.toInt('uint8', {'0b11111111'; '0x12'}), [uint8(255); uint8(18)]);
            obj.verifyEqual(strata.Conversion.toInt('uint8', [127, 18]), [uint8(127), uint8(18)]);
            obj.verifyEqual(strata.Conversion.toInt('uint8', [127; 18]), [uint8(127); uint8(18)]);
            obj.verifyError(@()strata.Conversion.toInt('uint8', {'0b100000000', '0x12'}), ?MException);
        end
    end
end
