
% INITIALIZE PSYCHTOOLBOX
% =======================
try PsychtoolboxVersion
catch
    try
        addpath(genpath('/usr/share/psychtoolbox-3/'));
    catch
        error('cannot find Psychtoolbox in the path...')
    end
end

% UnifyKeyNames
KbName('UnifyKeyNames');

% print everything right now in the command line (for Octave)
if IsOctave
    page_screen_output(0)
end

% initialize OpenGL
AssertOpenGL

% Prepare configuration of PTB
% The use of PsychImaging to set up PTB to open a window is necessary prior
% to the use of PsychColorCorrection. In particular, the window must be
% used with PsychImaging, not Screen!
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask','General','UseFastOffscreenWindows');
PsychImaging('AddTask','General','NormalizedHighresColorRange');
PsychImaging('AddTask','FinalFormatting','DisplayColorCorrection','SimpleGamma');

% Open a window for display
if isunix && strcmp(getenv('USER'), 'meyniel') % for my Linux HP
    [w_px, h_px] = Screen('WindowSize', 0);
    if fullscreen == 1
        [windowPtr, rect] = PsychImaging('OpenWindow', 0, [bg, bg, bg]);
        HideCursor
    else
        [windowPtr, rect] = PsychImaging('OpenWindow', 0, [bg, bg, bg], [1 1 1+round(0.33*w_px) 1+round(0.5*h_px)]);
    end
    w_px = rect(3);
    h_px = rect(4);
elseif isunix && strcmp(getenv('USER'), 'fm239804') % for Z800 computer
    [w_px, h_px] = Screen('WindowSize', 0);
    if fullscreen == 1
        [windowPtr, rect] = PsychImaging('OpenWindow', 0, [bg, bg, bg]);
        HideCursor
    else
        [windowPtr, rect] = PsychImaging('OpenWindow', 0, [bg, bg, bg], [1 1 1+0.2*w_px 1+0.5*h_px]);
    end
    w_px = rect(3);
    h_px = rect(4);
else
    [w_px, h_px] = Screen('WindowSize', 0);
    if fullscreen == 1
        [windowPtr, rect] = PsychImaging('OpenWindow', 0, [bg, bg, bg]);
        HideCursor
    else
        [windowPtr, rect] = PsychImaging('OpenWindow', 0, [bg, bg, bg], [1 1 1+0.5*w_px 1+0.5*h_px]);
    end
    w_px = rect(3);
    h_px = rect(4);
end

% get screen center coordinates
crossY = 1/2*h_px;
crossX = 1/2*w_px;

% get inter frame interval
fprintf('\n get ifi...')
ifi = Screen('GetFlipInterval', windowPtr, 100, 50e-6, 1); % [data point, std, timeout]
fprintf('Done!\n')

% enable transparancy
Screen('BlendFunction', windowPtr, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

% Apply gamma correction
LoadIdentityClut(windowPtr);
PsychColorCorrection('SetColorClampingRange', windowPtr, 0, 1);
PsychColorCorrection('SetEncodingGamma', windowPtr, 1/Gamma_correction);
Priority(MaxPriority(windowPtr));

% Set font
Screen('TextSize', windowPtr, 21);
Screen('TextFont', windowPtr, 'Arial');

% set color range to 0 1
Screen(windowPtr, 'Flip');
Screen('ColorRange', windowPtr, 1);

% Initialize screen BEFORE making texture (otherwise, it does not work...)
text = '...';
[w, h] = RectSize(Screen('TextBounds', windowPtr, text));
Screen('DrawText', windowPtr, text, round(crossX-w/2), round(crossY-h*3/2), colText);
Screen(windowPtr,'Flip');

% INITIALIZE STIMULI
% ==================

% get position of the bars (appended columwise) following the rect format
% in PTB
% Right patch
Right_patch_pos = [...
    (1:nBar) * bar.w - bar.w    + patch.cx/2 + crossX; ... % left border
    - bar.h/2 * ones(1, nBar)                + crossY; ... % top border
    (1:nBar) * bar.w            + patch.cx/2 + crossX; ... % right border
    bar.h/2 * ones(1, nBar)                  + crossY; ... % bottom border
    ];

% Left patch
Left_patch_pos = [...
    -(nBar+1-(1:nBar)) * bar.w  - patch.cx/2 + crossX ; ... % left border
    - bar.h/2 * ones(1, nBar)                + crossY; ...  % top border
    -(nBar-(1:nBar)) * bar.w    - patch.cx/2 + crossX ; ... % right border
    bar.h/2 * ones(1, nBar)                  + crossY; ...  % bottom border
    ];

% Compute position of the fixation dot
fix.pos = CenterRectOnPoint([0 0 fix.w fix.w], crossX, crossY);
fix.posin = CenterRectOnPoint([0 0 fix.in fix.in], crossX, crossY);

% Compute the jittered Delay duration
Dur_Delay = tDelay + tDelayJit*((rand(nTrial, 1) - 0.5)/0.5);

% Compute the jittered Inter Trial Interval
Dur_ITI = tITI + tITIJit*((rand(nTrial, 1) - 0.5)/0.5);

