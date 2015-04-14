function [correct, response, confidence, rt_choice, rt_conf] = one_trial(window, windowRect, screen_number, correct_location, gabortex, gaborDimPix, pahandle, variable_arguments)
%%
% Presents two Gabor patches that vary in contrast over time and then asks
% for which one of the two had higher contrast and the confidence of the
% decision.
%
% A note about contrast. The gabor is created with a procedural texture
% where disablenorm is True, contrastpremult is 0.5 and the background is
% 0.5. The amplitude of the gabor is then given by
%   amp = cpre * con
% The max and min of the Gabor are therefore
%   max, min = ampl +- BG
% The Michelson contrast is then given by
%       (BG + cpre * con) - (BG - cpre * con)    2*cpre*con
%  MC = ------------------------------------- =  ---------- = con [cpre =  BG]
%       (BG + cpre * con) + (BG - cpre * con)       2*BG
%  Which is to say that the contrast parameter gives the Michelson contrast
%  with the current contrastpremult and background settings.




%% Process variable input stuff
sigma = default_arguments(variable_arguments, 'sigma', gaborDimPix/6); % Sigma of the gaussian for the Gabor patch
contrast_left = default_arguments(variable_arguments, 'contrast_left', [10, 9, 8, 7, 6, 5, 4, 3, 2, 1]/10.); % Contrast of the left patch
contrast_right = default_arguments(variable_arguments, 'contrast_right', [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]/10.); % Contrast of the right patch
num_cycles = default_arguments(variable_arguments, 'num_cycles', 5); % Spatial Frequency (Cycles Per Pixel)
xpos = default_arguments(variable_arguments, 'xpos', [-10, 10]); % X position of the two Gabors
ypos = default_arguments(variable_arguments, 'ypos', [0, 0]); % Y position of the two Gabors
driftspeed = default_arguments(variable_arguments, 'driftspeed', 1); % Speed of the drift in units not yet clear
gabor_angle = default_arguments(variable_arguments, 'gabor_angle', 45); % Speed of the drift in units not yet clear
ppd = default_arguments(variable_arguments, 'ppd', estimate_pixels_per_degree(screen_number, 60));
duration = default_arguments(variable_arguments, 'duration', .1);
baseline_delay = default_arguments(variable_arguments, 'baseline_delay', 0.5);
decision_delay = default_arguments(variable_arguments, 'decision_delay', 0.25);
confidence_delay = default_arguments(variable_arguments, 'confidence_delay', 0.5);
feedback_delay = default_arguments(variable_arguments, 'confidence_delay', 0.5);
rest_delay = default_arguments(variable_arguments, 'confidence_delay', 0.5);
%% Key mappings
left_key = KbName('LeftArrow');
right_key = KbName('RightArrow');

up_key = KbName('UpArrow');
down_key = KbName('DownArrow');

quit = KbName('q');

% Define black, white and grey
white = WhiteIndex(screen_number);
black = BlackIndex(screen_number);

%% Properties of the gabor
ifi = Screen('GetFlipInterval', window);
freq = num_cycles / gaborDimPix;
xpos = xpos*ppd;
ypos = ypos*ppd;
% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(windowRect);
xpos = xpos + xCenter;
ypos = ypos + yCenter;
% Count how many Gabors there are
ngabors = numel(xpos);
% Make the destination rectangles for all the Gabors in the array
baseRect = [0 0 gaborDimPix gaborDimPix];
allRects = nan(4, ngabors);
for i = 1:ngabors
    allRects(:, i) = CenterRectOnPointd(baseRect, xpos(i), ypos(i));
end
degPerSec = 360 * driftspeed;
degPerFrame =  degPerSec * ifi;
gaborAngles = gabor_angle*ones(1, ngabors);
propertiesMat = repmat([NaN, freq, sigma, 0, 1, 0, 0, 0],...
    ngabors, 1);
propertiesMat(:, 1) = 0;
propertiesMat(:, 4) = [contrast_left(1) contrast_right(1)];


%% Baseline Delay period
% Draw the fixation point
Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 1);
vbl = Screen('Flip', window);
WaitSecs(baseline_delay)


% Numer of frames to wait before re-drawing
waitframes = 1;
% Animation loop
start = nan;
cnt = 1;

stimulus_onset = nan;
while ~((GetSecs - stimulus_onset) >= length(contrast_left)*duration)
    
    % Set the right blend function for drawing the gabors
    %Screen('BlendFunction', window, 'GL_ONE', 'GL_ZERO');
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    
    % Batch draw all of the Gabors to screen
    
    Screen('DrawTextures', window, gabortex, [], allRects, gaborAngles - 90,...
        [], [], [], [], kPsychDontDoRotation, propertiesMat');
    
    
    % Change the blend function to draw an antialiased fixation point
    % in the centre of the array
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    
    % Draw the fixation point
    Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 1);
    vbl = Screen('DrawText', window, sprintf('%2.2f', GetSecs-start), 0, 0);
    
    % Flip our drawing to the screen
    vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
    
    % Change contrast every 100ms
    elapsed = GetSecs;
    if isnan(start)
        stimulus_onset = GetSecs;
        start = GetSecs;
    end
    if (elapsed-start) > duration
        vbl = Screen('DrawText', window,  sprintf('%2.2f', elapsed-start), 0, 40);
        vala = contrast_left(1 + mod(cnt, length(contrast_left)));
        valb = contrast_right(1 + mod(cnt, length(contrast_right)));
        propertiesMat(:,4) = [vala valb];
        start = GetSecs;
        cnt = cnt+1;
    end
    
    % Increment the phase of our Gabors
    propertiesMat(:, 1) =  propertiesMat(:, 1) + degPerFrame;
end
% in the centre of the array
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');


%%% Get choice
% Draw the fixation point
Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 1);
vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
WaitSecs(decision_delay);
Screen('DrawDots', window, [xCenter; yCenter], 10, [0.5, 0.75, 0.5, 1 ], [], 1);
vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
start = GetSecs;
rt_choice = nan;
while (GetSecs-start) < 100
    [~, RT, keyCode] = KbCheck;
    if keyCode(quit)        
        throw(MException('EXP:Quit', 'User request quit'));
    end
    if keyCode(left_key) || keyCode(right_key)
        if keyCode(left_key)
            response = 1;
        else
            response = -1;
        end
        if correct_location == response
            correct = 1;
        else
            correct = 0;
        end
        rt_choice = RT-start;
        break;
    end
end

%%% Get confidence response
% Draw the fixation point
Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 1);
vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
WaitSecs(confidence_delay);
Screen('DrawDots', window, [xCenter; yCenter], 10, [0.5, 0.5, 0.75, 1 ], [], 1);
vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
start = GetSecs;
rt_conf = nan;
while (GetSecs-start) < 100
    [~, RT, keyCode] = KbCheck;
    if keyCode(up_key) || keyCode(down_key)
        if keyCode(up_key)
            confidence = 1;
        else
            confidence = -1;
        end
        rt_conf = RT-start;
        break;
    end
end

if correct
    beep = MakeBeep(350, .25);
else
    beep = MakeBeep(150, .25);
end
% Fill the audio playback buffer with the audio data 'wavedata':
PsychPortAudio('FillBuffer', pahandle, repmat(beep, [2,1]));
%%% Provide Feedback
% Draw the fixation point
Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 1);
vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
WaitSecs(feedback_delay);
t1 = PsychPortAudio('Start', pahandle, 1, 0, 1);
WaitSecs(rest_delay);
