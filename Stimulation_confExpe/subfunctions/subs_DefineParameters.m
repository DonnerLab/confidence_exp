
% -- GET STIMULATION SOFTWARE --
% ==============================
try
    IsOctave;
catch
    IsOctave = 0;
end

% -- DEFINE PARAMETERS FOR THE TASK --
% ====================================

fullscreen              = 1;                % 1 for fullscreen; 0 otherwise

% define if the session is an fMRI session
IsfMRI                  = 1;

NamePrefix              = 'LumiConf';
PathSave                = 'data/';          % where to save data

% Psychophysic parameters
nFramePerImg            = 3;                % 3 frames @ 60Hz = 50ms
nImage                  = 8;                % number of image per trial
nBar                    = 4;                % number of bars in a patch
distSD                  = 0.1;              % variance of the luminance distribution. should correspond to 10 cd/m2
prob                    = 0.75;             % expected fraction of correct (for Quest procedure)
initialThd_Quest        = 0.55;             % initial threshold for Quest (mean of the target distribution)
bg                      = 0.5;              % background color (and mean of the non-target distribution)

% select display parameters
colText                 = 0.8*[1 1 1];      % text color.

% Data for the patches
patch.w                 = 20;               % width of the patch
patch.h                 = 20;               % height of the patch
patch.cx                = 32;               % distance of the CENTER of the patch from the center of the screen in px

% fixation point
fix.dur                 = 0.5;              % duration in s
fix.w                   = 10;               % diameter of the fixation dot in pixels
fix.in                  = 4;                % diameter of the inner circle

% feedback
fb.ColPosFB             = [0 bg/0.7 0];
fb.ColNegFB             = [bg/0.2 0 0];
fb.FBsize               = 20;
fb.post                 = 0.5;              % duration post FB

% select between 2 settings
setting = 1;
if setting == 1                             % Setting 1: long delay
    nTrial                  = 65;
    tDelay                  = 5.1;          % delay between offset of last stim and go signal
    tDelayJit               = 0;
    tITI                    = 5.5;
    tITIJit                 = 1;
    go.col                  = [0 0 0.4];    % color of go signal
    fix.col                 = [0.2 0 0];    % color of fixation
    fb.pre                  = 0;            % duration pre FB
    iti.compensate          = 1;            % 1: compensate RT during ITI
    iti.mini                = 0.5;          % minimal duration of ITI when compensation.
    
    % NB: a 'fast' formula for the luminance of a RGB image is: 
    % l = [2*R 5*G 1*B]/8
    
elseif setting == 2                         % Setting 2: short delay
    nTrial                  = 110;
    tDelay                  = 0;            % delay between offset of last stim and go signal
    tDelayJit               = 0;
    tITI                    = 3.5;
    tITIJit                 = 1;
    go.col                  = [0 0 0.4];    % color of go signal
    fix.col                 = [0 0 0.4];    % color of fixation
    fb.pre                  = 0.5;          % duration pre FB
    iti.compensate          = 0;            % 1: compensate RT during ITI
    
else                                        % Setting 3: for testing (fast)
    nTrial                  = 60;
    tDelay                  = 0;            % delay between offset of last stim and go signal
    tDelayJit               = 0;
    tITI                    = 2.5;
    tITIJit                 = 1;
    go.col                  = [0 0 0.4];    % color of go signal
    fix.col                 = [0 0 0.4];    % color of fixation
    fb.pre                  = 0;            % duration pre FB
    iti.compensate          = 1;            % 1: compensate RT during ITI
    iti.mini                = 0.5;          % minimal duration of ITI when compensation.
end

% fMRI parameters
% FORT buttons: the one on top corresponds to 'b', and the one on the side
% correspond (from top to bottom) to 'y', 'g', 'r', ',' (last is the
% comma).
key_scanOnset           = 't'; % standard key for the TTL machine
key_LhHc_fMRI           = ',<';
key_LhLc_fMRI           = 'r';
key_RhLc_fMRI           = 'g';
key_RhHc_fMRI           = 'y'; % this is the comma key, after 'UnifyKeyNames
dummy_scans             = 4; % number of dummy scans (before the T0)

% key to run without fMRI
key_LhHc_beh            = 'a';
key_LhLc_beh            = 'z';
key_RhLc_beh            = 'o';
key_RhHc_beh            = 'p'; % this is the comma key, after 'UnifyKeyNames

% gamme correction
Gamma_correction        = 2.2; % FOR THE MOMENT, THIS IS ONLY A GUESS, NOT A MEASURE!!

% -- COMPLETE SETTINGS --
% =======================
if IsfMRI
    key_LhHc = key_LhHc_fMRI;
    key_LhLc = key_LhLc_fMRI;
    key_RhLc = key_RhLc_fMRI;
    key_RhHc = key_RhHc_fMRI;
else
    key_LhHc = key_LhHc_beh;
    key_LhLc = key_LhLc_beh;
    key_RhLc = key_RhLc_beh;
    key_RhHc = key_RhHc_beh;
end

% compute bar width & height
bar.w = patch.w/nBar;
bar.h = patch.h;
if bar.w ~= round(patch.w/nBar)
    error('the patch width: %d px cannot be divided into %d bars', patch.w, nBar)
end
if bar.h/2 ~= round(bar.h/2)
    error('the patch eigth: %d px cannot be divided into 2', bar.h)
end
if patch.cx/2 ~= round(patch.cx/2)
    error('patch eccentricity %d px should a mupltiple of 2', patch.cx)
end
