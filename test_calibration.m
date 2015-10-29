function [measurements, levels] = test_calibration(gamma, numMeasures, ppd, gabor_dim_pix, varargin)
% Adapt psychtoolbox's CalibrateMonitorPhotometer to show two stimuli at
% different locations and to read measurements from a color hug.
Screen('Preference', 'SkipSyncTests', 1); 
xpos = default_arguments(varargin, 'xpos', [0]);
ypos = default_arguments(varargin, 'ypos', [0]);
devices = 1;
path = default_arguments(varargin, 'path', '/home/meg/Documents/Argyll_V1.7.0/bin');

screenid = min(Screen('Screens'));

psychlasterror('reset');
try
    
    % Open black window:
    white = WhiteIndex(screenid);
    black = BlackIndex(screenid);
    grey = white / 2;
    % Open the screen
    [win, windowRect] = Screen('OpenWindow', screenid, grey);
    maxLevel = Screen('ColorRange', win);
    
    % Compute presentation locations
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
    for n = 1:ngabors
        Screen('FillOval', win, i,  allRects(:,n));
    end
    Screen('Flip',win);
    
    % make Kb Queue
    keyList = zeros(1, 256); keyList(KbName({'ESCAPE'})) = 1; % only listen to those keys!
    PsychHID('KbQueueCreate', [], keyList);
    PsychHID('KbQueueStart');
    WaitSecs(.1);
    PsychHID('KbQueueFlush');

    % Load identity gamma table for calibration:

    oldtable = Screen('LoadNormalizedGammaTable',win, gamma)

    measurements = [];
        
    inputV = [0:(maxLevel+1)/(numMeasures - 1):(maxLevel+1)]; %#ok<NBRAK>
    inputV(end) = maxLevel;
    levels = inputV;
    for i = inputV
        colors = [i, i];
        for n = 1:ngabors
            Screen('FillOval', win, colors(n),  allRects(:,n));
        end
        Screen('Flip',win);
        WaitSecs(0.1);
        data = read_rgb();
        %data = read_xyz();g
        
            measurements = [measurements; data]; %#ok<AGROW>
        
    end
    
    Screen('LoadNormalizedGammaTable',win, oldtable)
    % Restore normal gamma table and close down:
    Screen('CloseAll');
catch %#ok<*CTCH>
   Screen('LoadNormalizedGammaTable',win, oldtable)
    Screen('CloseAll');
    psychrethrow(psychlasterror);
end


