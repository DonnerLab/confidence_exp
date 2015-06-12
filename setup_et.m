%  open edf file for recording data from Eyelink - CANNOT BE MORE THAN 8 CHARACTERS
edfFile = sprintf('%ds%db%d.edf', setup.participant, setup.session, block);
Eyelink('Openfile', edfFile);

% send information that is written in the preamble
preamble_txt = sprintf('%s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %d', ...
    'Experiment', '2IFC RandomDots', ...
    'subjectnr', setup.participant, ...
    'edfname', edfFile, ...
    'screen_hz', window.frameRate, ...
    'screen_resolution', window.rect, ...
    'date', datestr(now),...
    'screen_distance', window.dist);
Eyelink('command', 'add_file_preamble_text ''%s''', preamble_txt);

% Calibrate the eye tracker
EyelinkDoTrackerSetup(el);

% start recording eye position
Eyelink('StartRecording');
% record a few samples before we actually start displaying
WaitSecs(0.1);
% mark zero-plot time in data file
Eyelink('message', 'Start recording Eyelink');