function [directory, info, img] = loadNII()
% Get and load input directory

[filename,directory] = uigetfile('*.nii','Select Reconstructed .nii Data');

% read them in
img = niftiread(fullfile(directory,filename));
imSize = size(img);
info = niftiinfo(fullfile(directory,filename));
pixdim = round(info.PixelDimensions(1:3),2);

% re-use info and output as smaller struct
info = [];
info.pixdim = pixdim;
info.imSize = imSize(1:3); 
info.nframes = imSize(4);

% also quickly load the MReconFlag to get relative positon
opts = delimitedTextImportOptions("NumVariables", 2);

% Specify range and delimiter
opts.DataLines = [28, 28];
opts.Delimiter = "\t";

% Specify column names and types
opts.VariableNames = ["Var1", "VarName2"];
opts.SelectedVariableNames = "VarName2";
opts.VariableTypes = ["string", "char"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["Var1", "VarName2"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["Var1", "VarName2"], "EmptyFieldRule", "auto");

% Import the data
mreconflags = dir([directory,'\*MReconFlags.dat']);
offcentre = readtable(fullfile(directory,mreconflags(1).name), opts);
offcentre = table2cell(offcentre);
numIdx = cellfun(@(x) ~isnan(str2double(x)), offcentre);
offcentre(numIdx) = cellfun(@(x) {str2double(x)}, offcentre(numIdx));
offcentre = cell2mat(offcentre);
offcentre = str2num(offcentre);
info.offcentre = offcentre;

disp('Load Data finished');
return