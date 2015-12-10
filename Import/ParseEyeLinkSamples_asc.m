function samples = ParseEyeLinkSamples_asc(filename,lineFormat,outFields)

% Read in sample column values from an EyeLink .asc samples file.
%
% INPUTS:
% -filename is a string indicating the EyeLink samples file (as imported by
% the edf2asc converter) that you want to parse. 
% -lineFormat is a string to be used as inp;ut to textscan when reading the
% file. [default: '%d%f%f%f%*f%*s']
% - outFields is an n-element cell array of strings indicating the field
% that each column corresponds to. If two have the same name, they will be
% appended as columns.
% 
% OUTPUTS:
% -samples is a struct with fields position (the x and y position of the
% eye at each sample), time (the eyelink time of each samplem, in ms), and
% PD (the size of the pupil at each sample).
%
% Created 12/8/15 by DJ. 

% Declare defaults
if ~exist('lineFormat','var') || isempty(lineFormat)
    lineFormat = '%f%f%f%f%*f%*s';
end
if ~exist('outFields','var') || isempty(outFields)
    outFields = {'time','position','position','PD'};
end


% Read in full file
fprintf('Reading EyeLink samples from file %s...\n',filename)
fid = fopen(filename);
C = textscan(fid,lineFormat,'delimiter',' ','MultipleDelimsAsOne',true,'TreatAsEmpty','.');

%% Translate info into events struct
fprintf('Translating into samples struct...\n');
samples = struct();
for i=1:numel(outFields)
    if ~isfield(samples,outFields{i}) % if it's a new field...
        samples.(outFields{i}) = C{i}; % set to the contents of this cell
    else % if it's an additional instance of an existing field
        samples.(outFields{i}) = cat(2,samples.(outFields{i}),C{i}); % append columns
    end
end

fprintf('Done!\n')