function [T, varargout] = batchTrials2table()
% batchTrials2table
% Moves trial data into a table, with each row as trial
%
% SYNTAX
% T = batchTrials2table() opens up a uigui, the user is prompted to select  
%       a data file, which should be a struct. The user is then prometed to 
%       select a conversion file, which is a cell array containing 3
%       columns. Column 1 for the new name of the variable, column 2 for
%       the old name and column 3 for an intermediate function. A table is
%       then returned with each variable as a column vector.


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

[T, ~, data] = trials2table('dataFile', [dataPathname, dataFilenames{1}],...
    'conversionFile', conversionFile);
T = combineTrialConditions(T);
T = extractRawData(data, T);

T = [table('Size', [height(T), 3],...
           'VariableTypes', {'uint16', 'datetime', 'categorical'},...
           'VariableNames', {'sessionNumber', 'date', 'rat'}),...
     T];
T.sessionNumber(1:height(T)) = 1; 
filenameSections = split(dataFilenames{1}, '_'); 
T.date(1:height(T)) = datetime([filenameSections{3}(1:3)...
                                ' '...
                                filenameSections{3}(4:end)...
                                ', '...
                                filenameSections{4}]);
T.rat(1:height(T)) = categorical(filenameSections(1));

varTypes = table2cell(varfun(@class, T));
T = [T; table('Size', [3000 * nFiles, width(T)],...
    'VariableTypes', varTypes,...
    'VariableNames', T.Properties.VariableNames)];

%user props? Custom doesn't work for this
nTrialsPerSesh = NaN(nFiles, 1);
nTrialsPerSesh(1) = T.Properties.CustomProperties.nTrials; 

for i = 2:nFiles
    [newT, ~, data] = trials2table('dataFile', [dataPathname, dataFilenames{i}],...
        'conversionFile', conversionFile);
    newT = combineTrialConditions(newT);
    newT = extractRawData(data, newT);
    
    newT = [table('Size', [height(newT), 3],...
            'VariableTypes', {'uint16', 'datetime', 'categorical'},...
            'VariableNames', {'sessionNumber', 'date', 'rat'}),...
            newT];
    newT.sessionNumber(1:height(newT)) = i;
    filenameSections = split(dataFilenames{i}, '_'); 
    newT.date(1:height(newT)) = datetime([filenameSections{3}(1:3)...
        ' '...
        filenameSections{3}(4:end)...
        ', '...
        filenameSections{4}]);
    newT.rat(1:height(newT)) = categorical(filenameSections(1));
    
    startIdx = sum(nTrialsPerSesh(1:i-1)) + 1;
    T(startIdx : startIdx + height(newT) - 1, :) = newT;
    nTrialsPerSesh(i) = newT.Properties.CustomProperties.nTrials;
end

T = rmmissing(T, 'DataVariables', 'date');

T.Properties.CustomProperties.nTrials = sum(nTrialsPerSesh);
T = addprop(T, {'nTrialsPerSession'}, {'table'});
T.Properties.CustomProperties.nTrialsPerSession = nTrialsPerSesh;
 
varargout{1} = conversionFile;
    
end