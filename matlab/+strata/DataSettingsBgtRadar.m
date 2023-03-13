% DATASETTINGSBGTRADAR  get Data settings bytes for BGT radar configuration
%   Usage:
%   [settings] = DataSettingsBgtRadar(readouts, aggregation)
%
%   'readouts' is in the form of a vector with 'n' pairs of values
%   formatted as a matrix with each row containing one pair
%               [ readoutAddress_1 readoutCount_1 ; ...
%                 readoutAddress_2 readoutCount_2 ; ...
%                 ...
%                 readoutAddress_n readoutCount_n ]
%   'aggregation' is expected as a single 16-bit value 
%
%   Return values:
%   'settings' byte vector derived from the inputs
%
function settings = DataSettingsBgtRadar(readouts, aggregation)
    settings = strata.wrapper_matlab('strata.DataSettingsBgtRadar', uint16(readouts), uint16(aggregation));
end
