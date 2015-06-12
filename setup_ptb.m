%% Some Setup
AssertOpenGL;
sca;
PsychDefaultSetup(2);
InitializePsychSound;
pahandle = PsychPortAudio('Open', [], [], 0);

screenNumber = min(Screen('Screens'));
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
grey = white / 2;
% Open the screen
%[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey, [400, 0, 1600, 900], 32, 2, [], [],  kPsychNeed32BPCFloat);
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey, [], 32, 2, [], [],  kPsychNeed32BPCFloat);

% You definetly want to set a custom look up table.
% gamma is the look up table
if exist('gamma_lut', 'var') == 0 && length(gamma_lut) == 256
    throw(MException('EXP:Quit', 'variable gamma not in workspace; no gamma lut loaded'));
end
Screen('LoadNormalizedGammaTable', window, gamma_lut*[1 1 1]);

HideCursor(screenNumber)
Screen('Flip', window);

% Make gabortexture
gabortex = make_gabor(window, 'gabor_dim_pix', gabor_dim_pix);