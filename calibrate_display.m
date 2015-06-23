function [ gammaTables1, gammaTables2, displayBaselines, displayRanges, displayGammas, maxLevel, measurements, levels] = calibrate_display(numMeasures, ppd, gabor_dim_pix, variable_arguments)
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
    
    keyIsDown = false;
    while ~keyIsDown
        [keyIsDown, firstPress] = PsychHID('KbQueueCheck');
    end
    
    
    
    % Load identity gamma table for calibration:
    LoadIdentityClut(win);
    
    measurements = [];
    inputV = [0:(maxLevel+1)/(numMeasures - 1):(maxLevel+1)]; %#ok<NBRAK>
    inputV(end) = maxLevel;
    levels = inputV;
    for i = inputV
        
        for n = 1:ngabors
            Screen('FillOval', win, i,  allRects(:,n));
        end
        Screen('Flip',win);
        WaitSecs(0.1)
        data = read_rgb_spotread('devices', [1,2]);
        data = sum(data, 2);
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


% [ gammaTable1, gammaTable2, displayBaseline, displayRange, displayGamma, maxLevel, raw_vals, levels]
gammaTables1 = [];
gammaTables2 = [];
displayBaselines = [];
displayRanges = [];
displayGammas = [];


for n = 1:2
    %Normalize values
    vals = measurements(n, :);
    displayRange = range(vals);
    displayBaseline = min(vals);
    displayRanges = [displayRanges displayRange];
    displayBaselines = [displayBaselines displayBaseline];
    
    raw_vals = vals;
    vals = (vals - displayBaseline) / displayRange;
    inputV = [0:(maxLevel+1)/(numMeasures - 1):(maxLevel+1)]; %#ok<NBRAK>
    inputV(end) = maxLevel;
    inputV = inputV/maxLevel;
    
    %Gamma function fitting
    g = fittype('x^g');
    fittedmodel = fit(inputV',vals',g);
    displayGamma = fittedmodel.g;
    displayGammas = [displayGammas displayGamma];
    gammaTable1 = ((([0:maxLevel]'/maxLevel))).^(1/fittedmodel.g); %#ok<NBRAK>
    gammaTables1 = [gammaTables1, gammaTable1];  %#ok<AGROW>
    firstFit = fittedmodel([0:maxLevel]/maxLevel); %#ok<NBRAK>
    
    %Spline interp fitting
    try
        fittedmodel = fit(inputV',vals','splineinterp');
        secondFit = fittedmodel([0:maxLevel]/maxLevel); %#ok<NBRAK>
        %Invert interpolation
        fittedmodel = fit(vals',inputV','splineinterp');
        
        gammaTable2 = fittedmodel([0:maxLevel]/maxLevel); %#ok<NBRAK>
    catch
        gammaTable2 = gammaTable1;
    end
    gammaTables2 = [gammaTables2, gammaTable2];  %#ok<AGROW>
end
return;
