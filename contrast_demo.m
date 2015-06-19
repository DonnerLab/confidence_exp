%% Show a bunch of gratings.

screenNumber = min(Screen('Screens'));
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
grey = white / 2;
% Open the screen
Screen('Preference', 'SkipSyncTests', 1);
[window, windowRect] = Screen('OpenWindow', screenNumber, grey);
options.window_rect = windowRect;
options.width = windowRect(3) - windowRect(1);
options.height = windowRect(4) - windowRect(2);

Screen('LoadNormalizedGammaTable', window, gamma_lut*[1 1 1]);

% Set the display parameters 'frameRate' and 'resolution'
options.frameDur     = Screen('GetFlipInterval',window); %duration of one frame
options.frameRate    = 1/options.frameDur; %Hz

HideCursor(screenNumber)
Screen('Flip', window);

%1900x1200 = 7x4
gabor_dim_pix = 270;
[xpos, ypos] = meshgrid(270/2:270:270/2+6*270, 270/2:270:270/2 + 3*270);
num_cycles = 5;
freq = num_cycles / gabor_dim_pix;
sigma = gabor_dim_pix/6;

% Make gabortexture
gabortex = make_gabor(window, 'gabor_dim_pix', gabor_dim_pix);
ngabors = numel(xpos);
allRects = nan(4, ngabors);
baseRect = [0 0 gabor_dim_pix gabor_dim_pix];

for i = 1:ngabors
    allRects(:, i) = CenterRectOnPointd(baseRect, xpos(i), ypos(i));
end
degPerSec = 360 * 1;
degPerFrame =  1 * 1;
gaborAngles = 45*ones(1, ngabors);
propertiesMat = repmat([NaN, freq, sigma, 0, 1, 0, 0, 0],...
    ngabors, 1);
propertiesMat(:, 1) = 0;
baseline = 0.5;
threshold = linspace(0, .5, ngabors);
contrasts = baseline + threshold;
contrasts(1:2:end) = baseline;
reshape(contrasts-baseline, size(xpos,1), size(xpos,2))
propertiesMat(:, 4) = contrasts;

Screen('BlendFunction', window, 'GL_ONE', 'GL_ZERO');
%Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% Batch draw all of the Gabors to screen
Screen('DrawTextures', window, gabortex, [], allRects, gaborAngles - 90,...
    [], [], [], [], kPsychDontDoRotation, propertiesMat');
vbl = Screen('Flip', window);

% make Kb Queue
keyList = zeros(1, 256); keyList(KbName({'ESCAPE'})) = 1; % only listen to those keys!
PsychHID('KbQueueCreate', [], keyList);
PsychHID('KbQueueStart');
WaitSecs(.1);
PsychHID('KbQueueFlush');

keyIsDown = false;
while ~keyIsDown
    [keyIsDown, firstPress] = PsychHID('KbQueueCheck');
end
LoadIdentityClut(window);
vbl = Screen('Flip', window);

sca

