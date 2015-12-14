function localizer_trial(window, windowRect, screen_number, ringtex, pahandle, trigger_enc, beeps, ppd, variable_arguments)


%% Process variable input stuff
radius = default_arguments(variable_arguments, 'radius', 150);
inner_annulus = default_arguments(variable_arguments, 'inner_annulus', 5);
ringwidth = default_arguments(variable_arguments, 'ringwidth', 25);
sigma = default_arguments(variable_arguments, 'sigma', 2*ppd);
cutoff = default_arguments(variable_arguments, 'cutoff', 2*ppd);

contrast_probe = default_arguments(variable_arguments, 'contrast_probe', [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]/10.);
driftspeed = default_arguments(variable_arguments, 'driftspeed', 1);
duration = default_arguments(variable_arguments, 'duration', .5);
baseline_delay = default_arguments(variable_arguments, 'baseline_delay', 0.5);
inter_stimulus_delay = default_arguments(variable_arguments, 'baseline_delay', 0.5);
decision_delay = default_arguments(variable_arguments, 'decision_delay', 0.0);
feedback_delay = default_arguments(variable_arguments, 'feedback_delay', 0.5);
rest_delay = default_arguments(variable_arguments, 'rest_delay', 0.5);
expand = default_arguments(variable_arguments, 'expand', 1);
kbqdev = default_arguments(variable_arguments, 'kbqdev', []);


%% Setting the stage
timing = struct();

first_conf_high = '1';
first_conf_low = '2';
second_conf_low = '3';
second_conf_high = '4';
quit = 'ESCAPE';

black = BlackIndex(screen_number);

[xCenter, yCenter] = RectCenter(windowRect);
ifi = Screen('GetFlipInterval', window);


%% Baseline Delay period

% Draw the fixation point
Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 1);
vbl = Screen('Flip', window);
timing.TrialOnset = vbl;

trigger(trigger_enc.localizer_start);
WaitSecs(0.005);



waitframes = (baseline_delay-0.01)/ifi;

flush_kbqueues(kbqdev);




waitframes = 1;
%% Animation loop
start = nan;
cnt = 1;
framenum = 1;
dynamic = [];
stimulus_onset = nan;
[low, high] = contrast_colors(contrast_probe(cnt), 0.5);
%cnt = cnt+1;
shiftvalue = 0;

while ~((GetSecs - stimulus_onset) >= (length(contrast_probe))*duration-2*ifi) 
    
    % Set the right blend function for drawing the gabors
    Screen('BlendFunction', window, 'GL_ONE', 'GL_ZERO');
    %Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

    Screen('DrawTexture', window, ringtex, [], [], [], [], [], low, [], [],...
        [high(1), high(2), high(3), high(4), shiftvalue, ringwidth, radius, inner_annulus, sigma, cutoff, xCenter, yCenter]);
    shiftvalue = shiftvalue+expand*driftspeed;
    % Change the blend function to draw an antialiased fixation point
    % in the centre of the array
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    
    % Draw the fixation point
    Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 1);
    
    % Flip our drawing to the screen
    vbl = Screen('Flip', window, vbl + (waitframes-.5) * ifi);
    flush_kbqueues(kbqdev);

    if framenum == 1
        Eyelink('message', 'SYNCTIME');
        trigger(trigger_enc.stim_onset);
        
    elseif framenum == 1 && ~(cnt==1)
        trigger(trigger_enc.con_change);
    end
    framenum = framenum +1;
    waitframes = 1;
    dynamic = [dynamic vbl];
    
    % Change contrast every 100ms
    elapsed = GetSecs;
    if isnan(start)
        stimulus_onset = GetSecs;
        trigger(trigger_enc.con_change);
        start = GetSecs;
    end
    if (elapsed-start) > (duration-.5*ifi)
        start = GetSecs;        
        cnt = cnt+1;
        [low, high] = contrast_colors(contrast_probe(cnt), 0.5);        
        trigger(trigger_enc.con_change);
    end
    
end

target = (waitframes - 0.5) * ifi;
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

%%% Get choice
% Draw the fixation point
Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 1);
vbl = Screen('Flip', window, vbl + target );



%% Provide Feedback
WaitSecs(1);
WaitSecs(rand)+1;

Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 1);
waitframes = rest_delay/ifi;
vbl = Screen('Flip', window, (waitframes - 0.5) * ifi);
timing.trial_end = vbl;
trigger(trigger_enc.localizer_end);