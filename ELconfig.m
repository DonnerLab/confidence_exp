function [el, options] = ELconfig(window, subject, options)
screenNum = max(Screen('Screens')); % will use the main screen when single-monitor setup
res = Screen('Resolution', screenNum);
% setup the Eyelink initialization at the beginning of each block
% code from Hannah, UKE

dummymode = 1; % set to 1 to run in dummymode (using mouse as pseudo-eyetracker)
[IsConnected, IsDummy] = EyelinkInit(dummymode);
if IsDummy, warning('SetupEL:dummy','EyeLink in dummy mode!'); end
if ~IsConnected
    warning('SetupEL:noInit','Failed to initialize EyeLink!');
    return
end

[v, vs ]    = Eyelink('GetTrackerVersion');
fprintf('Running experiment on a ''%s'' tracker.\n', vs );

el = EyelinkInitDefaults(window);

% % SEND SCREEN SIZE TO EL SO THAT VISUAL ANGLE MEASUREMENTS ARE CORRECT
rv = []; % collect return values from eyetracker commands

rv(end+1) = Eyelink('command', ...
    'screen_pixel_coords = %ld %ld %ld %ld', 0, 0, res.width, res.height); %rv 1

% BENQ Screen is 535mm wide and 300mm high
rv(end+1) = Eyelink('command', 'screen_phys_coords = %ld %ld %ld %ld' ....
    , -floor(10*options.width/2) ... %half width
    ,  floor(10*options.height/2) ... %half height
    ,  floor(10*options.width/2) ... %half width
    , -floor(10*options.height/2));   %half height %rv 2

rv(end+1) = Eyelink('command', 'screen_distance = %ld %ld', ...
    10*options.dist, 10*options.dist); %rv 3

% Write the display configuration as message into the file
Eyelink('message', ...
    'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, res.width, res.height);
Eyelink('message', 'SCREEN_PHYS_COORDS %ld %ld %ld %ld' ....
    , -floor(10*options.width/2) ... %half width
    ,  floor(10*options.height/2) ... %half height
    ,  floor(10*options.width/2) ... %half width
    , -floor(10*options.height/2));   %half height

% make sure we get the right data from eyelink - all of it!
Eyelink('command', 'link_sample_data = LEFT,RIGHT,GAZE,AREA,GAZERES,HREF,PUPIL,INPUT,STATUS,BUTTON');
Eyelink('command', 'link_event_data = GAZE,GAZERES,HREF,AREA,VELOCITY,STATUS');
Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK, MESSAGE, INPUT,BUTTON');
Eyelink('command', 'file_sample_data = LEFT,RIGHT,GAZE,AREA,GAZERES,HREF,PUPIL,STATUS,BUTTON,INPUT,HTARGET');
Eyelink('command', 'file_event_data = GAZE,GAZERES,HREF,AREA,VELOCITY');
Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
Eyelink('command', 'calibration_type = HV9');

EyelinkUpdateDefaults(el);

%  open edf file for recording data from Eyelink - CANNOT BE MORE THAN 8 CHARACTERS
options.edfFile = sprintf('%ds%db%d.edf', subject.initials);
Eyelink('Openfile', options.edfFile);

% send information that is written in the preamble
preamble_txt = sprintf('%s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %d', ...
    'Experiment', 'CNFDNC', ...
    'subjectnr', subject.initials, ...
    'edfname', options.edfFile, ...
    'screen_hz', options.frameRate, ...
    'screen_resolution', options.window_rect, ...
    'date', datestr(now),...
    'screen_distance', options.dist);
Eyelink('command', 'add_file_preamble_text ''%s''', preamble_txt);

end