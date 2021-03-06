function [T, varargout] = trials2table(varargin)
% TRIALS2TABLE
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

% set defaults
defaultDatafile = [];
defaultConversionFile = [];

isFileLoc = @(x) ischar(x) || isstring(x) || iscellstr(x);
validConversionArrayOrFile = @(x) isFileLoc(x) ||...
    (iscell(x) && size(x, 2) == 3) || isempty(x) ;
validStructOrFile = @(x) isFileLoc(x) ||...
    isstruct(x) || isempty(x);

p = inputParser;
addParameter(p, 'dataFile', defaultDatafile, validStructOrFile);
addParameter(p, 'conversionFile', defaultConversionFile,...
    validConversionArrayOrFile);
parse(p, varargin{:});

dataFile = p.Results.dataFile;
conversionFile = p.Results.conversionFile;
clear p

start_directory = cd;

% if no input, select files with gui
if ~isstruct(dataFile) && isempty(dataFile)
    [filename, pathname] = uigetfile('*.mat',...
        'Choose Session to Analyse', 'multiselect', 'off');
    % stop if user cancels
    if isequal(filename, 0)
        disp('User selected cancel')
        return;
    end
    dataFile = [pathname, filename];
end

if isFileLoc(dataFile) % if input is file location
    data = load(dataFile);
    data = data.(subsref(fieldnames(data), substruct('{}',{1}))); % unwrap
    assert(isstruct(data), 'The data file for trials must be a struct')
else % if input is data struct
    data = dataFile;
end

% if no input, select files with gui
if ~iscell(conversionFile) && isempty(conversionFile)
    [filename, pathname] = uigetfile('*.mat',...
        'Choose Conversion Cell Array', 'multiselect', 'off');
    % stop if user cancels
    if isequal(filename, 0)
        disp('User selected cancel')
        return;
    end
    conversionFile = [pathname, filename];
end

if isFileLoc(conversionFile) % if input is file location   
    conversion = load(conversionFile);
    conversion = conversion.(subsref(fieldnames(conversion),...
        substruct('{}',{1}))); % unwrap
    assert(validConversionArrayOrFile(conversion), ['Conversion array must ',...
        'be a cell array with 3 columns'])
else % if input is conversion cell array
    conversion = conversionFile;
end

% Special case for adjusting Dual2AFCBen files
if contains(conversionFile,'Dual2AFCBen')        
    customFields = fieldnames(data.Custom);
    for fieldI = 1:length(customFields)
        data.(customFields{fieldI}) = data.Custom.(customFields{fieldI});
        
    end
    temp = [data.TrialSettings.GUI];
    GUIFields = fieldnames(temp);
    for fieldI = 1:length(GUIFields)
        data.(GUIFields{fieldI}) = [temp.(GUIFields{fieldI})];
    end
    % Fix trial number
    if data.nTrials > length(data.ST) 
        data.nTrials = length(data.ST);
    end
end

clear conversionFile dataFile

% move data into data table
T = table((1:data.nTrials)', 'VariableNames', {'trialNumber'});
T = addprop(T,{'nTrials'}, {'table'});
T.Properties.CustomProperties.nTrials = data.nTrials;

for i = 1: size(conversion, 1)
    newName = conversion{i, 1};
    oldName = conversion{i, 2};
    convFun = conversion{i, 3};
    T.(newName) = convFun(data.(oldName), data);
end

varargout{1} = conversion;
varargout{2} = data;

cd(start_directory)
    
end