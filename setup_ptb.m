AssertOpenGL;
KbName('UnifyKeyNames');

%PsychDefaultSetup(2);
timings = {};
screenNumber = min(Screen('Screens'));
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
grey = white / 2;
% Open the screen
Screen('Preference', 'SkipSyncTests', 1);
[window, windowRect] = Screen('OpenWindow', screenNumber, grey);
%[window, windowRect] = Screen('OpenWindow', screenNumber, grey, [0, 0, 400, 400]);
options.window_rect = windowRect;
% Switch color specification to use the 0.0 - 1.0 range instead of the 0 -
% 255 range. This is more natural for these kind of stimuli:
Screen('ColorRange', window, 1);

% You definetly want to set a custom look up table.
% gamma is the look up table
load projector_calib_20151111.mat
if exist('gammaTables1', 'var') == 0 && length(gammaTables1) == 256
    throw(MException('EXP:Quit', 'variable gamma not in workspace; no gamma lut loaded'));
end
old_gamma_table = Screen('LoadNormalizedGammaTable', window, gammaTables1);


% Set the display parameters 'frameRate' and 'resolution'
options.frameDur     = Screen('GetFlipInterval',window); %duration of one frame
options.frameRate    = 1/options.frameDur; %Hz

HideCursor(screenNumber)
Screen('Flip', window);


    %% Set up Eye Tracker
    [el, options] = ELconfig(window, subject, options, screenNumber);
    
    % Calibrate the eye tracker
    EyelinkDoTrackerSetup(el);
    

% Make gabortexture
%gabortex = make_gabor(window, 'gabor_dim_pix', options.gabor_dim_pix);
ringtex = make_circular_grating(window, options.ringwidth);
% make Kb Queue: Need to specify the device to query button box
% Find the keyboard + MEG buttons.
[idx, names, all] = GetKeyboardIndices();
options.kbqdev = [idx(strcmpi(names, 'ATEN USB KVMP w. OSD')), idx(strcmpi(names, 'Current Designs, Inc. 932')),...
    idx(strcmpi(names, 'Apple Internal Keyboard / Trackpad')), idx(strcmpi(names, ''))];

keyList = zeros(1, 256);
keyList(KbName({'ESCAPE','SPACE', 'LeftArrow', 'RightArrow',...
    '1', '2', '3', '4', 'b', 'g', 'y', 'r', '1!', '2@', '3#', '4$'})) = 1; % only listen to those keys!
% first four are the buttons in mode 001, escape and space are for
% the experimenter, rest is for esting
for kbqdev = options.kbqdev
    PsychHID('KbQueueCreate', kbqdev, keyList);
    PsychHID('KbQueueStart', kbqdev);
    WaitSecs(.1);
    PsychHID('KbQueueFlush', kbqdev);
end

%% now the audio setup

InitializePsychSound(1);
devices = PsychPortAudio('GetDevices');

% UA-25 is the sound that's played in the subject's earbuds
for i = 1:length(devices)
    if strcmp(devices(i).DeviceName,'EDIROL UA-25: USB Audio (hw:1,0)') %UA-25: USB Audio (hw:1,0)')
        break
    end
end
devices(i)
% check that we found the low-latency audio port
%assert(numel(strfind(devices(i).DeviceName, 'UA-25')) > 0, 'could not detect the right audio port! aborting')
audio = [];

%i = 10; % for the EEG lab
audio.i = devices(i).DeviceIndex;
audio.freq = devices(i).DefaultSampleRate;
audio.device = devices(i);
audio.h = PsychPortAudio('Open',audio.i,1,1,audio.freq,2);
PsychPortAudio('RunMode',audio.h,1);

% Maximum priority level
topPriorityLevel = MaxPriority(window);
