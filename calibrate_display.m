function [ gammaTable1, gammaTable2, displayBaseline, displayRange, displayGamma, maxLevel, raw_vals, levels] = calibrate_display(numMeasures, ppd, gabor_dim_pix, variable_arguments)
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
        GetChar();

    % Load identity gamma table for calibration:
    LoadIdentityClut(win);
    
    vals = [];
    inputV = [0:(maxLevel+1)/(numMeasures - 1):(maxLevel+1)]; %#ok<NBRAK>
    inputV(end) = maxLevel;
    levels = inputV;
    for i = inputV
        for n = 1:ngabors
            Screen('FillOval', win, i,  allRects(:,n));
        end
        Screen('Flip',win);
        WaitSecs(0.1)
        resp = sum(read_rgb());
        resp = 0.5*(resp+sum(read_rgb()));
        vals = [vals resp]; %#ok<AGROW>
    end
    
    % Restore normal gamma table and close down:
    RestoreCluts;
    Screen('CloseAll');
catch %#ok<*CTCH>
    RestoreCluts;
    Screen('CloseAll');
    psychrethrow(psychlasterror);
end

displayRange = range(vals);
displayBaseline = min(vals);

%Normalize values
raw_vals = vals;
vals = (vals - displayBaseline) / displayRange;
inputV = inputV/maxLevel;

if ~exist('fittype'); %#ok<EXIST>
    fprintf('This function needs fittype() for automatic fitting. This function is missing on your setup.\n');
    fprintf('Therefore i can''t proceed, but the input values for a curve fit are available to you by\n');
    fprintf('defining "global vals;" and "global inputV" on the command prompt, with "vals" being the displayed\n');
    fprintf('values and "inputV" being user input from the measurement. Both are normalized to 0-1 range.\n\n');
    error('Required function fittype() unsupported. You need the curve-fitting toolbox for this to work.\n');
end

%Gamma function fitting
g = fittype('x^g');
fittedmodel = fit(inputV',vals',g);
displayGamma = fittedmodel.g;
gammaTable1 = ((([0:maxLevel]'/maxLevel))).^(1/fittedmodel.g); %#ok<NBRAK>

firstFit = fittedmodel([0:maxLevel]/maxLevel); %#ok<NBRAK>

%Spline interp fitting
fittedmodel = fit(inputV',vals','splineinterp');
secondFit = fittedmodel([0:maxLevel]/maxLevel); %#ok<NBRAK>

figure;
plot(inputV, vals, '.', [0:maxLevel]/maxLevel, firstFit, '--', [0:maxLevel]/maxLevel, secondFit, '-.'); %#ok<NBRAK>
legend('Measures', 'Gamma model', 'Spline interpolation');
title(sprintf('Gamma model x^{%.2f} vs. Spline interpolation', displayGamma));

%Invert interpolation
fittedmodel = fit(vals',inputV','splineinterp');

gammaTable2 = fittedmodel([0:maxLevel]/maxLevel); %#ok<NBRAK>

return;
