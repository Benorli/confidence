function spk2times2txt(filename, spks)
% SPK2TIMES2TXT(filename, spks)
%
% spk2times2txt(filename, spks) takes a filename and column vector of spike
% times in seconds and creates a text file with a single coulmn of spike 
% times with the given in filename. The text file is in the correct format
% to be imported to spike2


validateattributes(filename, {'char', 'string'}, {'nonempty'});
validateattributes(spks, {'numeric'}, {'nonempty', 'column'})

fileID = fopen([filename '.txt'], 'w');
fprintf(fileID, '%.6f\n', spks);
fclose(fileID);

end