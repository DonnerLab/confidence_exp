function [correct, response, confidence, rt_choice, timing] = one_trial(window, windowRect, screen_number, correct_location, ringtex, pahandle, trigger_enc, variable_arguments)
%% function [correct, response, confidence, rt_choice, rt_conf] = one_trial(window, windowRect, screen_number, correct_location, gabortex, gaborDimPix, pahandle, variable_arguments)
%
% Presents a circular contracting/expanding grating with a reference
% contrast, then the same with changing contrast. Ask for response and
% confidence.
%
% Parameters
% ----------
%
% window : window handle to draw into
% windowRect : dimension of the window
% screen_number : which screen to use
% correct_location : -1 if correct is right, 1 if left
% ringtex : the ring texture to draw
% pahandle : audio handle
%
% Variable Arguments
% ------------------
%
% ringwidth : spatial frequency of the grating
% contrast_reference : contrast of the reference
% contrast_probe : array of contrast values for the probe stimulus
% driftspeed : how fast the gabors drift (units not clear yet)
% ppd : pixels per degree to convert to visual angles
% duration : how long each contrast level is shown in seconds
% baseline_delay : delay between trial start and stimulus onset.
% feedback_delay : delay between confidence response and feedback onset
% rest_delay : delay between feedback onset and trial end



%% Process variable input stuff
ref_duration =  default_arguments(variable_arguments, 'ref_duration', .400);
radius = default_arguments(variable_arguments, 'radius', 150);
contrast_reference = default_arguments(variable_arguments, 'contrast_reference', 0.25);
contrast_probe = default_arguments(variable_arguments, 'contrast_probe', [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]/10.);
ringwidth = default_arguments(variable_arguments, 'ringwidth', 25);
driftspeed = default_arguments(variable_arguments, 'driftspeed', 1);
ppd = default_arguments(variable_arguments, 'ppd', estimate_pixels_per_degree(screen_number, 60));
duration = default_arguments(variable_arguments, 'duration', .5);
baseline_delay = default_arguments(variable_arguments, 'baseline_delay', 0.5);
inter_stimulus_delay = default_arguments(variable_arguments, 'baseline_delay', 0.2);
decision_delay = default_arguments(variable_arguments, 'decision_delay', 0.0);
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



left_conf_high = 'd';
left_conf_low = 'f';
right_conf_low = 'g';
right_conf_high = 'h';
quit = 'ESCAPE';

black = BlackIndex(screen_number);

[xCenter yCenter] = RectCenter(windowRect);
ifi = Screen('GetFlipInterval', window);

if correct_location == -1
    trigger(trigger_enc.stim_strong_right);
elseif correct_location == 1
    trigger(trigger_enc.stim_strong_left);
end


%% Baseline Delay period

% Draw the fixation point
Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 1);
vbl = Screen('Flip', window);
timing.TrialOnset = vbl;

trigger(trigger_enc.trial_start);


waitframes = (baseline_delay-0.01)/ifi;

PsychHID('KbQueueFlush');

%% Show reference
[low, high] = contrast_colors(contrast_reference, 0.5);
shiftvalue = 0;
for frame = 1:(ref_duration/ifi)
    Screen('DrawTexture', window, ringtex, [], [], [], [], [], low, [], [],...
        [high(1), high(2), high(3), high(4), shiftvalue, ringwidth, radius, 50]);
    vbl = Screen('Flip', window, vbl + (waitframes) * ifi);
    waitframes = 1;
    shiftvalue = shiftvalue+driftspeed;
end
Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 1);
vbl = Screen('Flip', window);

waitframes = (inter_stimulus_delay-0.01)/ifi;

%% Animation loop
start = nan;
cnt = 1;
framenum = 1;
dynamic = [];
stimulus_onset = nan;
[low, high] = contrast_colors(contrast_probe(cnt), 0.5);
cnt = cnt+1;
while ~((GetSecs - stimulus_onset) >= (length(contrast_probe)-1)*duration-1*ifi) 
    
    % Set the right blend function for drawing the gabors
    Screen('BlendFunction', window, 'GL_ONE', 'GL_ZERO');
    %Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

    Screen('DrawTexture', window, ringtex, [], [], [], [], [], low, [], [],...
        [high(1), high(2), high(3), high(4), shiftvalue, ringwidth, radius, 50]);
    shiftvalue = shiftvalue+driftspeed;
    % Change the blend function to draw an antialiased fixation point
    % in the centre of the array
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    
    % Draw the fixation point
    Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 1);
    
    % Flip our drawing to the screen
    vbl = Screen('Flip', window, vbl + (waitframes-.5) * ifi);
    if framenum == 1 && cnt == 1
        Eyelink('message', 'SYNCTIME');
        trigger(trigger_enc.stim_onset);
    elseif framenum == 1 && ~(cnt==1)
        trigger(trigger_enc.con_change);
    end
    waitframes = 1;
    dynamic = [dynamic vbl];
    
    % Change contrast every 100ms
    elapsed = GetSecs;
    if isnan(start)
        stimulus_onset = GetSecs;
        start = GetSecs;
    end
    if (elapsed-start) > duration-.5*ifi
        elapsed-start
        start = GetSecs;
        [low, high] = contrast_colors(contrast_probe(cnt), 0.5);
        cnt = cnt+1;
        
    end
    
end
target = (waitframes - 0.5) * ifi;
% if decision_delay > 0
%     Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 1);
%     vbl = Screen('Flip', window, vbl + (waitframes-0.5)*ifi);
%     Eyelink('message', 'stim_off');
%     trigger(trigger_enc.stim_off);
%     WaitSecs(0.01);
%     trigger(trigger_enc.zero);
%     target = decision_delay -0.01 - 0.5 * ifi;
% end
PsychHID('KbQueueFlush');
% in the centre of the array
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
timing.animation = dynamic;

%%% Get choice
% Draw the fixation point
Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 1);
vbl = Screen('Flip', window, vbl + target );
trigger(trigger_enc.decision_start);
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
            case left_conf_high
                Eyelink('message', 'decision left conf high');
                trigger(trigger_enc.left_conf_high);
                response = 1;
                confidence = 2;
            case left_conf_low
                Eyelink('message', 'decision left conf low');
                trigger(trigger_enc.left_conf_high);
                response = 1;  
                confidence = 1;
            case right_conf_low
                Eyelink('message', 'decision right conf low');
                trigger(trigger_enc.right_conf_high);
                response = -1;                
                confidence = 1;
            case right_conf_high
                Eyelink('message', 'decision right conf high');
                trigger(trigger_enc.right_conf_high);
                response = -1;
                confidence = 2;                
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
    trigger(trigger_enc.no_decisions);
    Eyelink('message', 'decision none');
    fprintf('Error in answer\n')
    wait_period = 1 + feedback_delay + rest_delay;
    WaitSecs(wait_period);
    correct = nan;
    response = nan;
    confidence = nan;
    rt_choice = nan;
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
    trigger(trigger_enc.feedback_correct);
    Eyelink('message', 'decision correct');
else
    trigger(trigger_enc.feedback_incorrect);
    Eyelink('message', 'decision incorrect');
end
timing.feedback_start = t1;

Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 1);
waitframes = rest_delay/ifi;
vbl = Screen('Flip', window, t1 + (waitframes - 0.5) * ifi);
timing.trial_end = vbl;
trigger(trigger_enc.trial_end);