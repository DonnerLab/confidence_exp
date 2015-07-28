function [measurements] = test_calibration(test, ppd, gabor_dim_pix, left_values, right_values, varargin)
% Adapt psychtoolbox's CalibrateMonitorPhotometer to show two stimuli at
% different locations and to read measurements from a color hug.

xpos = default_arguments(varargin, 'xpos', [-10, 10]);
ypos = default_arguments(varargin, 'ypos', [0, 0]);
devices = default_arguments(varargin, 'devices', [1, 2]);
path = default_arguments(varargin, 'path', '/home/meg/Documents/Argyll_V1.7.0/bin');


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
    
    measurements = {};
    for k = 1:length(devices)
        measurements{k} = [];
    end
    for i = 1:length(left_values)
        % Compute correction
        Screen('FillOval', win, left_values(i)*maxLevel,  allRects(:,1));
        Screen('FillOval', win, right_values(i)*maxLevel,  allRects(:,2));
        
        Screen('Flip',win);
        WaitSecs(0.25);
        if ~test
            data = read_rgb_spotread('devices', [1,2], 'path', path);
            for k = 1:length(devices)
                measurements{k} = [measurements{k}; data(k, :)]; %#ok<AGROW>
            end
        end
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
