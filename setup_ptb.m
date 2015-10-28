AssertOpenGL;
KbName('UnifyKeyNames');

%PsychDefaultSetup(2);
timings = {};
screenNumber = min(Screen('Screens'));
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
grey = white / 2;
% Open the screen
t[window, windowRect] = Screen('OpenWindow', screenNumber, grey);
options.window_rect = windowRect;
% You definetly want to set a custom look up table.
% gamma is the look up table
%if exist('gamma_lut', 'var') == 0 && length(gamma_lut) == 256
%    throw(MException('EXP:Quit', 'variable gamma not in workspace; no gamma lut loaded'));
%end
%Screen('LoadNormalizedGammaTable', window, gamma_lut*[1 1 1]);

% Set the display parameters 'frameRate' and 'resolution'
options.frameDur     = Screen('GetFlipInterval',window); %duration of one frame
options.frameRate    = 1/options.frameDur; %Hz

HideCursor(screenNumber)
Screen('Flip', window);

% Make gabortexture
gabortex = make_gabor(window, 'gabor_dim_pix', options.gabor_dim_pix);

% make Kb Queue
keyList = zeros(1, 256); keyList(KbName({'1!', '2@', '3#', '4$', 'ESCAPE','SPACE', 'LeftArrow', 'RightArrow',...
    'a', 's', 'd', 'f'})) = 1; % only listen to those keys!
% first four are the buttons in mode 001, escape and space are for
% the experimenter, rest is for esting
PsychHID('KbQueueCreate', [], keyList);
PsychHID('KbQueueStart');
WaitSecs(.1);
PsychHID('KbQueueFlush');

%% now the audio setup

InitializePsychSound(1);
devices = PsychPortAudio('GetDevices');

% UA-25 is the sound that's played in the subject's earbuds
for i = 1:length(devices)
    if strcmp(devices(i).DeviceName, 'OUT (UA-25)')
        break
    end
end

% check that we found the low-latency audio port
assert(strfind(devices(i).DeviceName, 'UA-25') > 0, 'could not detect the right audio port! aborting')
audio = [];
%i = 10; % for the EEG lab

audio.i = devices(i).DeviceIndex;
audio.freq = devices(i).DefaultSampleRate;
audio.device = devices(i);
audio.h = PsychPortAudio('Open',audio.i,1,1,audio.freq,2);
PsychPortAudio('RunMode',audio.h,1);

% Maximum priority level
topPriorityLevel = MaxPriority(window);