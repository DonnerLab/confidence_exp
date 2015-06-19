function [measurements, levels] = test_calibration(test, numMeasures, ppd, gabor_dim_pix, signal, left, right, gamma_left, gamma_right, variable_arguments)
% Adapt psychtoolbox's CalibrateMonitorPhotometer to show two stimuli at
% different locations and to read measurements from a color hug.

xpos = default_arguments(variable_arguments, 'xpos', [-10, 10]);
ypos = default_arguments(variable_arguments, 'ypos', [0, 0]);


screenid = max(Screen('Screens'));

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
    Screen('Flip',win);  
    %WaitSecs(60)
    % Load identity gamma table for calibration:    
    measurements = [];
    inputV = [0:(maxLevel+1)/(numMeasures - 1):(maxLevel+1)]; %#ok<NBRAK>
    inputV(end) = maxLevel;
    levels = [];
    [corr_left, notmatched_left, corr_right, diff] = match_luminance(inputV/maxLevel, signal, left, right, gamma_left, gamma_right);     
    
    for i = 1:(find(corr_left == max(corr_left),1, 'first'))
        % Compute correction
        levels = [levels, inputV(i)];
        Screen('FillOval', win, corr_left(i)*maxLevel,  allRects(:,1));        
        Screen('FillOval', win, corr_right(i)*maxLevel,  allRects(:,2));        
        
        Screen('Flip',win);
        WaitSecs(0.25)
         data = [0, 0];
        if ~test
            data = read_rgb_spotread('devices', [1,2]);
            data = sum(data, 2);
           
        end
        measurements = [measurements data]; %#ok<AGROW>
    end
    
    % Restore normal gamma table and close down:
    RestoreCluts;
    Screen('CloseAll');
catch %#ok<*CTCH>
    RestoreCluts;
    Screen('CloseAll');
    psychrethrow(psychlasterror);
end


return;
