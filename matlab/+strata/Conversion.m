classdef Conversion
    % Conversion can be used for type safe conversions
    %
    % Conversion Functions:
    %    toInt    - converts a value to an integer of the given type
    %    toBool   - converts a value to a boolean
    %    strToNum - cooverts a string starting with "0x" or "0b" to a number

    methods(Static)
        function num = toInt(type, value)
            % toInt converts value to an integer of type
            %   value can be a nubmer already or a string that starts with '0x' or '0b'
            %   type can be any of the MATLAB supported integer types such as 'uint8'
            num = strata.Conversion.toNumber(value);
            if max(num) > intmax(type)
                error('Invalid argument: Value(s) too large for "%s"', type);
            elseif min(num) < intmin(type)
                error('Invalid argument: Value(s) too small for "%s"', type);
            end
            num = cast(num, type);
        end

        function num = toBool(value)
            % toBool converts value to a boolean if possible
            %   value can be true/false or alternatively 0/1 or a string
            %   that is convertible to 0/1 using strToNum
            if islogical(value)
                num = value;
            else
                num = strata.Conversion.toNumber(value);
                if num > 1
                    error('Invalid argument: Expected either a boolean, or 0 or 1');
                end
                num = logical(num);
            end
        end

        function num = toNumber(varargin)
            if isnumeric(varargin{1})
                num = varargin{:};
            elseif iscell(varargin{1})
                num = strata.Conversion.strToNum(varargin{:});
            else
                num = strata.Conversion.strToNum(varargin);
            end
        end

        function num = strToNum(str)
            if ~iscell(str)
                if ~isvector(str)
                    error('Invalid argument: Strings to be converted have to be stored in a cell array');
                end
                switch str(1:2)
                    case '0x'
                        num = hex2dec(str(3:end));
                    case '0b'
                        num = bin2dec(str(3:end));
                    otherwise
                        error('Invalid argument: String to be converted has to start with "0x" or "0b"');
                end
            else
                dimensions = ndims(str);
                if dimensions > 2
                    error('Unsupported number of dimensions');
                end
                [rows, cols] = size(str);
                num = zeros(rows, cols);
                for i=1:rows
                    for j=1:cols
                        if isnumeric(str{i,j})
                            num(i,j) = str{i,j};
                        else
                            switch str{i,j}(1:2)
                                case '0x'
                                    num(i,j) = hex2dec(str{i,j}(3:end));
                                case '0b'
                                    num(i,j) = bin2dec(str{i,j}(3:end));
                                otherwise
                                    error('Invalid argument: String to be converted has to start with "0x" or "0b"');
                            end
                        end
                    end
                end
            end
        end
    end
end
