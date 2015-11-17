function [measurements, levels] = pofile_luminance(win, windowRect, maxLevel, numMeasures,  gabor_dim_pix, xpos, ypos)
% Adapt psychtoolbox's CalibrateMonitorPhotometer to show two stimuli at
% different locations and to read measurements from a color hug.

devices = 1;
path ='/home/meg/Documents/Argyll_V1.7.0/bin';



% Compute presentation locations
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

KbEventFlush();
KbWait();
% Load identity gamma table for calibration:


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


