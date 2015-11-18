positions = [-1  1; 0  1; 1  1;...
    -1  0; 0  0; 1  0;...
    -1 -1; 0 -1; 1 -1];
positions = positions.*400*0;

Screen('Preference', 'SkipSyncTests', 1);
screenid = min(Screen('Screens'));
psychlasterror('reset');


% Open black window:
white = WhiteIndex(screenid);
black = BlackIndex(screenid);
grey = white / 2;
% Open the screen
[win, windowRect] = Screen('OpenWindow', screenid, grey);
maxLevel = Screen('ColorRange', win);

data = nan(25,3,9);
num_measurements = 25;
cnt = 1;
for pos = positions'
    xpos = pos(1);
    ypos = pos(2);
    [cm, cl] = pofile_luminance(win, windowRect, maxLevel,  25, 550, xpos, ypos);
    data(:,:,cnt) = cm;
    cnt = cnt+1;
    
    
end

Screen('CloseAll');
sca
psychrethrow(psychlasterror);