function [correct, response, confidence, rt_choice, rt_conf, timing] = one_trial(window, windowRect, screen_number, correct_location, gabortex, gabor_dim_pix, pahandle, trigger, variable_arguments)
%% function [correct, response, confidence, rt_choice, rt_conf] = one_trial(window, windowRect, screen_number, correct_location, gabortex, gaborDimPix, pahandle, variable_arguments)
%
% Presents two Gabor patches that vary in contrast over time and then asks
% for which one of the two had higher contrast and the confidence of the
% decision.
%
% Parameters
% ----------
%
% window : window handle to draw into
% windowRect : dimension of the window
% screen_number : which screen to use
% correct_location : -1 if correct is right, 1 if left
% gabortex : the gabor texture to draw
% gabor_dim_pix : size of the gabor grating in px.
% pahandle : audio handle
%
% Variable Arguments
% ------------------
%
% sigma : sigma of the gaussian for the gabor patch
% contrast_left : array of michelson contrast values for left gabor
% contrast_right : array of michelson contrast values for right gabor
% num_cycles : spatial frequency of the gabor
% xpos : array of two x positions for the two gabors
% ypos : array of two y positions for the two gabors
% driftspeed : how fast the gabors drift (units not clear yet)
% gabor_angle : orientation of the two gabors
% ppd : pixels per degree to convert to visual angles
% duration : how long each contrast level is shown in seconds
% baseline_delay : delay between trial start and stimulus onset.
% confidence_delay : delay between decision response and confidence cue
% feedback_delay : delay between confidence response and feedback onset
% rest_delay : delay between feedback onset and trial end
%
%
% A note about contrast. The gabor is created with a procedural texture
% where disablenorm is True, contrastpremult is 0.5 and the background is
% 0.5. The amplitude of the gabor is then given by
%   amp = cpre * con
% The max and min of the Gabor are therefore
%   max, min = ampl +- BG
% The Michelson contrast is then given by
%       (BG + cpre * con) - (BG - cpre * con)    2*cpre*con
%  MC = ------------------------------------- =  ---------- = con [cpre = BG]
%       (BG + cpre * con) + (BG - cpre * con)       2*BG
%  Which is to say that the contrast parameter gives the Michelson contrast
%  with the current contrastpremult and background settings.


%% Process variable input stuff
sigma = default_arguments(variable_arguments, 'sigma', gabor_dim_pix/6);
contrast_left = default_arguments(variable_arguments, 'contrast_left', [10, 9, 8, 7, 6, 5, 4, 3, 2, 1]/10.);
contrast_right = default_arguments(variable_arguments, 'contrast_right', [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]/10.);
num_cycles = default_arguments(variable_arguments, 'num_cycles', 5);
xpos = default_arguments(variable_arguments, 'xpos', [-10, 10]);
ypos = default_arguments(variable_arguments, 'ypos', [0, 0]);
driftspeed = default_arguments(variable_arguments, 'driftspeed', 1);
gabor_angle = default_arguments(variable_arguments, 'gabor_angle', 45);
ppd = default_arguments(variable_arguments, 'ppd', estimate_pixels_per_degree(screen_number, 60));
duration = default_arguments(variable_arguments, 'duration', .1);
baseline_delay = default_arguments(variable_arguments, 'baseline_delay', 0.5);
decision_delay = default_arguments(variable_arguments, 'decision_delay', 0.25);
confidence_delay = default_arguments(variable_arguments, 'confidence_delay', 0.5);
feedback_delay = default_arguments(variable_arguments, 'feedback_delay', 0.5);
rest_delay = default_arguments(variable_arguments, 'rest_delay', 0.5);

%% Setting the stage
beeps = {MakeBeep(150, .25), MakeBeep(350, .25)};
timing = struct();

% left_key = KbName('1!');
% right_key = KbName('2@');
% conf_very_high = KbName('1!');
% conf_high = KbName('2@');
% conf_low = KbName('3#');
% conf_very_low = KbName('4$');

left_key = 'LeftArrow';
right_key = 'RightArrow';
conf_very_high = 'f';
conf_high = 'd';
conf_low = 's';
conf_very_low = 'a';
quit = 'ESCAPE';

black = BlackIndex(screen_number);

% Properties of the gabor
ifi = Screen('GetFlipInterval', window);
freq = num_cycles / gabor_dim_pix;
xpos = xpos*ppd;
ypos = ypos*ppd;
[xCenter, yCenter] = RectCenter(windowRect);
xpos = xpos + xCenter;
ypos = ypos + yCenter;
ngabors = numel(xpos);
baseRect = [0 0 gabor_dim_pix gabor_dim_pix];
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

if correct_location == -1
    outp(trigger.address, trigger.stim_strong_right);
elseif correct_location == 1    
    outp(trigger.address, trigger.stim_strong_left);
end
WaitSecs(0.01);
outp(trigger.address, trigger.zero);


%% Baseline Delay period
% Draw the fixation point
Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 1);
vbl = Screen('Flip', window);
timing.TrialOnset = vbl;

outp(trigger.address, trigger.trial_start);
WaitSecs(0.01);
outp(trigger.address, trigger.zero);

waitframes = (baseline_delay-0.01)/ifi;

PsychHID('KbQueueFlush');
%% Animation loop
start = nan;
cnt = 1;
framenum = 1;
dynamic = [];
stimulus_onset = nan;
while ~((GetSecs - stimulus_onset) >= (length(contrast_left)*duration-1*ifi))
    
    % Set the right blend function for drawing the gabors
    Screen('BlendFunction', window, 'GL_ONE', 'GL_ZERO');
    %Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    
    % Batch draw all of the Gabors to screen
    Screen('DrawTextures', window, gabortex, [], allRects, gaborAngles - 90,...
        [], [], [], [], kPsychDontDoRotation, propertiesMat');
    
    % Change the blend function to draw an antialiased fixation point
    % in the centre of the array
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    
    % Draw the fixation point
    Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 1);
    
    % Flip our drawing to the screen
    vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
    if framenum == 1 && cnt == 1
        Eyelink('message', 'SYNCTIME');
        outp(trigger.address, trigger.stim_onset);
    elseif framenum > 1
        outp(trigger.address, trigger.zero);
    elseif framenum == 1 && ~(cnt==1)
        outp(trigger.address, trigger.con_change);
    end
    waitframes = 1;
    dynamic = [dynamic vbl];
    % Change contrast every 100ms
    elapsed = GetSecs;
    if isnan(start)
        stimulus_onset = GetSecs;
        start = GetSecs;
    end
    if (elapsed-start) > duration
        vala = contrast_left(1 + mod(cnt, length(contrast_left)));
        valb = contrast_right(1 + mod(cnt, length(contrast_right)));
        propertiesMat(:,4) = [vala valb];
        start = GetSecs;
        cnt = cnt+1;
    end
    
    % Increment the phase of our Gabors
    propertiesMat(:, 1) =  propertiesMat(:, 1) + degPerFrame;
end
target = (waitframes - 0.5) * ifi;
if decision_delay > 0    
    Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 1);        
    vbl = Screen('Flip', window, vbl + (waitframes-0.5)*ifi);
    Eyelink('message', 'stim_off');
    outp(trigger.address, trigger.stim_off);
    WaitSecs(0.01);
    outp(trigger.address, trigger.zero);
    target = decision_delay -0.01 - 0.5 * ifi;
end
PsychHID('KbQueueFlush');
% in the centre of the array
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
timing.animation = dynamic;

%%% Get choice
% Draw the fixation point
Screen('DrawDots', window, [xCenter; yCenter], 10, 255*[1, 0.25, 0.25, 1 ], [], 1);
vbl = Screen('Flip', window, vbl + target );
outp(trigger.address, trigger.decision_start);
Eyelink('message', 'decision_start');

timing.response_cue = vbl;
start = GetSecs;
rt_choice = nan;
key_pressed = false;
error = false;
response = nan;
while (GetSecs-start) < 2    
    [keyIsDown, firstPress] = PsychHID('KbQueueCheck');
    RT = GetSecs();
    if keyIsDown
        keys = KbName(firstPress);
        if iscell(keys)
            error = true;
            break
        end
        switch keys
            case quit
                throw(MException('EXP:Quit', 'User request quit'));
            case left_key
                Eyelink('message', 'decision left');
                outp(trigger.address, trigger.resp_left);
                response = 1;
            case right_key
                Eyelink('message', 'decision right');
                outp(trigger.address, trigger.resp_right);
                response = -1;
        end
        if ~isnan(response)
            if correct_location == response
                correct = 1;
            else
                correct = 0;
            end
            rt_choice = RT-start;
            key_pressed = true;
            break;
        end
    end
end
Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 1);
vbl = Screen('Flip', window);
if ~key_pressed || error 
    outp(trigger.address, trigger.no_decisions);
    Eyelink('message', 'decision none');
    fprintf('Error in answer\n')
    wait_period = confidence_delay + 1 + feedback_delay + rest_delay;
    WaitSecs(wait_period);
    correct = nan;
    response = nan;
    confidence = nan;
    rt_choice = nan;
    rt_conf = nan;
    return
end

%% Get confidence response
key_pressed = false;
timing.start_confidence_delay = vbl;
waitframes = confidence_delay/ifi;
Screen('DrawDots', window, [xCenter; yCenter], 10, 255*[0.25, 1, 0.25, 1 ], [], 1);
vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
PsychHID('KbQueueFlush');
outp(trigger.address, trigger.confidence_start);
Eyelink('message', 'confidence start');
timing.confidence_cue = vbl;
start = GetSecs;
rt_conf = nan;
error = false;
while (GetSecs-start) < 2
    [keyIsDown, firstPress] = PsychHID('KbQueueCheck');
    RT = GetSecs();    
    if keyIsDown
        keys = KbName(firstPress);
        if iscell(keys)
            error = true;
            break
        end
        switch keys
            case conf_very_high
                outp(trigger.address, trigger.conf_very_high);
                Eyelink('message', 'confidence very_high');
                confidence = 2;
                key_pressed = true;
                rt_conf = RT-start;
                break;
            case conf_high
                Eyelink('message', 'confidence high');
                outp(trigger.address, trigger.conf_high);
                confidence = 1;
                key_pressed = true;
                rt_conf = RT-start;
                break;
            case conf_low
                Eyelink('message', 'confidence low');
                outp(trigger.address, trigger.conf_low);
                confidence = -1;
                key_pressed = true;
                rt_conf = RT-start;
                break;
            case conf_very_low
                Eyelink('message', 'confidence very_low');
                outp(trigger.address, trigger.conf_very_low);
                confidence = -2;
                key_pressed = true;
                rt_conf = RT-start;
                break;
        end

    end
end
Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 1);
vbl = Screen('Flip', window);

if ~key_pressed || error
    outp(trigger.address, trigger.no_confidence);
    Eyelink('message', 'confidence none');
    wait_period = 0.5 + feedback_delay + rest_delay;
    WaitSecs(wait_period);
    confidence = nan;
    rt_conf = nan;
    return
end

%% Provide Feedback
beep = beeps{correct+1};
PsychPortAudio('FillBuffer', pahandle.h, repmat(beep, [2,1]));
timing.feedback_delay_start = vbl;
Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 1);
waitframes = (feedback_delay/ifi) - 2;
vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
t1 = PsychPortAudio('Start', pahandle.h, 1, 0, 1);
if correct
    outp(trigger.address, trigger.feedback_correct);
    Eyelink('message', 'decision correct');
else
    outp(trigger.address, trigger.feedback_incorrect);
    Eyelink('message', 'decision incorrect');
end
timing.feedback_start = t1;

Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 1);
waitframes = rest_delay/ifi;
vbl = Screen('Flip', window, t1 + (waitframes - 0.5) * ifi);
timing.trial_end = vbl;
outp(trigger.address, trigger.trial_end);