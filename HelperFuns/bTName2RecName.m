function [recordingName] = bTName2RecName(bTName)
% BTNAME2RECNAME take a behaviour table name (bT.RatSession) and return a
%   string in the format used in recording data. ONLY for PMA sessions
%
%   [recordingName] = bTName2RecName(bTName)

bTName = char(bTName);
assert(isequal(bTName(1:3), 'PMA'),...
    'Input must be letters starting with PMA');

bTDate = datetime(bTName(end-10:end),...
    "InputFormat", "dd-MMM-yyyy", "Format", "yyMMdd");
recordingName = [bTName(1:5), ' ', char(bTDate)];

end