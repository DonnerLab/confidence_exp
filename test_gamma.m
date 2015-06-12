function gammatable = test_gamma(gamma, screenid)
numMeasures = 9;
% Open black window:
try
    win = Screen('OpenWindow', screenid, 0);
    maxLevel = Screen('ColorRange', win);
    
    % Load identity gamma table for calibration:    
    %LoadIdentityClut(win);
    [gammatable, dacbits, reallutsize] = Screen('ReadNormalizedGammaTable', screenid);
    Screen('LoadNormalizedGammaTable', win, gamma*[1 1 1]);
    vals = [];
    inputV = [0:(maxLevel+1)/(numMeasures - 1):(maxLevel+1)]; %#ok<NBRAK>
    inputV(end) = maxLevel;
    for i = inputV
        Screen('FillRect',win,i);
        Screen('Flip',win);
        
        fprintf('Value? ');
        resp = GetNumber;
        fprintf('\n');
        vals = [vals resp]; %#ok<AGROW>
    end
    % Restore normal gamma table and close down:
catch
    lasterr
    RestoreCluts;
    Screen('CloseAll');
end
RestoreCluts;
Screen('CloseAll');

plot(inputV)
hold all
plot(vals)
end