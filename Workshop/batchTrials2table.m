function [T, varargout] = batchTrials2table()
% batchTrials2table
% Moves trial data into a table, with each row as trial
%
% SYNTAX
% T = trials2table() opens up a uigui, the user is prompted to select a 
%       data file, which should be a struct. The user is then prometed to 
%       select a conversion file, which is a cell array containing 3
%       columns. Column 1 for the new name of the variable, column 2 for
%       the old name and column 3 for an intermediate function. A table is
%       then returned with each variable as a column vector.
%
% NAME VALUE OPTIONAL IN:
% dataFile: Either a file location for a data file which must be a struct,
%       or a variable containing the data struct.
% conversionFile: Either a file location for a conversion file which must 
%       be a cell array with 3 columns, or a variable containing the 
%       cell array.

[dataFilenames, dataPathname] = uigetfile('*.mat', 'Choose Sessions',...
    'multiselect', 'on');
% stop if user cancels
if isequal(dataFilenames, 0)
    disp('User selected cancel')
    return;
end

[conversionFilename, conversionPathname] = uigetfile('*.mat',...
    'Choose Conversion Cell Array', 'multiselect', 'off');
% stop if user cancels
if isequal(conversionFilename, 0)
    disp('User selected cancel')
    return;
end
conversionFile = [conversionPathname, conversionFilename];


%%

nFiles = length(dataFilenames);

T = trials2table('dataFile', [dataPathname, dataFilenames{1}],...
    'conversionFile', conversionFile);

T = [T; table(NaN(3000 * nFiles, width(T)))];

nTrialsPerSesh = NaN(nFiles, 1);
nTrialsPerSesh(1) = T.Properties.CustomProperties.nTrials;

for i = 2:nFiles
    newT = trials2table('dataFile', [dataPathname, dataFilenames{i}],...
        'conversionFile', conversionFile);
    startIdx = sum(nTrialsPerSesh(1:i-1));
    T(startIdx: startIdx + height(newT)) = newT; 
    nTrialsPerSesh(i) = newT.Properties.CustomProperties.nTrials;
end   

T(sum(nTrialsPerSesh):end) = [];

T = addprop(T,{'nTrialsPerSession'}, {'table'});
T.Properties.CustomProperties.nTrialsPerSesh = data.nTrials;
 
varargout{1} = conversionFile;
    
end