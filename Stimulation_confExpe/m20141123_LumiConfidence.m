
% =========================================================================
%                               HISTORY
% =========================================================================
% m20141111
%   - starting first version

% m20141123
%   - reject the random samples in which the mean of the target is lower
%   than the mean of the non-target.


% =========================================================================
%                               INITIALIZATION
% =========================================================================

clear all; close all;
addpath subfunctions
addpath Quest

% Initialize random generators
try
    s = RandStream('mt19937ar','Seed','shuffle');
    RandStream.setGlobalStream(s);
catch
    rand('twister',sum(100*clock))
end

% --- SETTINGS ---
% ################
subs_DefineParameters

% --- COMPLETE SETTINGS ---
% #########################

% Get Subject Info 
% (this include the Quest procedure to calibrate the difficutly of the 
% experiment based on previous sessions).
subs_GetSubInfo

% Initialize PsychToolBox
subs_InitPTB_and_stim

% Randomize the position of the target
if rem(nTrial, 2) == 1 % nTrial is an odd nuber
    TargetOnLeft = [ones(1, floor(nTrial/2)), zeros(1, floor(nTrial/2)+1)];
    TargetOnLeft = TargetOnLeft(randperm(nTrial));
else
    TargetOnLeft = [ones(1, floor(nTrial/2)), zeros(1, floor(nTrial/2))];
    TargetOnLeft = TargetOnLeft(randperm(nTrial));
end
TargetOnLeft = logical(TargetOnLeft);

% =========================================================================
%                             PLAY EXPERIMENT
% =========================================================================

% initialize variable to save
tStimOn         = zeros(nTrial, nImage);
tFixOn          = zeros(nTrial, 1);
tGoOn           = zeros(nTrial, 1);
tRepValid       = zeros(nTrial, 1);
SConfLevel      = zeros(nTrial, 1);
STargetPos      = zeros(nTrial, 1);
tFBOn           = zeros(nTrial, 1);
tITIOn          = zeros(nTrial, 1);
tStimOff        = zeros(nTrial, 1);
correct         = zeros(nTrial, 1);
Q_output        = zeros(nTrial, 1);
save_Quest_proc = cell(nTrial, 1);
save_RpatchL	= zeros(nTrial, nBar, nImage);
save_LpatchL	= zeros(nTrial, nBar, nImage);


% --- WAIT START SIGNAL---
% ########################
exittask = 0;

% ready to start screen
Screen(windowPtr, 'Flip');
text = 'PRET';
[w, h] = RectSize(Screen('TextBounds', windowPtr, text));
Screen('DrawText', windowPtr, text, ceil(crossX-w/2), ceil(crossY-h/2), colText);
Screen(windowPtr,'Flip');

if IsfMRI
    % The start signal is the scanner trigger
    ScanCount = 0;
    fprintf('\n Waiting for the scanner triggers...')
    while true
        [isKeyDown, keyTime, keyCode] = KbCheck;
        if isKeyDown && keyCode(KbName('ESCAPE')); % press escape to quit the experiment
            exittask = 1;
            break
        end
        
        if isKeyDown && keyCode(KbName(key_scanOnset));
            % key_scanOnset is sent when the 1st slice of a new volume in
            % aquiered.
            ScanCount = ScanCount+1;
            fprintf('\n dummy scan %d started', ScanCount)
            if ScanCount == 1
                fprintf(' defined at T0')
                save_T0 = keyTime;
            end
            if ScanCount == (dummy_scans+1)
                fprintf('\n ready-to-analyse fMRI scan starting now!\n')
                break
            end
            
            % wait for key up
            while isKeyDown
                isKeyDown = KbCheck;
            end
        end
    end
    if exittask==1;
        sca
        if fullscreen == 1; ShowCursor; end
        break
    end
else
    % The start signal is the User 'space' key press.
    fprintf('\n Waiting for the space bar key press...')
    while true
        [isKeyDown, keyTime, keyCode] = KbCheck;
        if isKeyDown && keyCode(KbName('ESCAPE')); % press escape to quit the experiment
            exittask = 1;
            break
        end
        if isKeyDown && keyCode(KbName('space'));
            fprintf('\n Starting stimulation...\n')
            break
        end
    end
    if exittask==1;
        sca
        if fullscreen == 1; ShowCursor; end
        break
    end
end

% --- GO SIGNAL FOR THE SUBJECT ---
% #################################
text = 'C EST PARTI!';
[w, h] = RectSize(Screen('TextBounds', windowPtr, text));
Screen('DrawText', windowPtr, text, ceil(crossX-w/2), ceil(crossY-h/2), colText);
Screen(windowPtr,'Flip');
WaitSecs(0.8);

for iTrial = 1:nTrial
    
    % --- SETUP STIMULI FOR THIS TRIAL ---
    % ####################################
    
    % Gets estimate from the Quest procedure for the next trial
    Q_output(iTrial) = round(QuestMean(Quest_proc)*100)/100;
    if Q_output(iTrial)<0.5,
        Q_output(iTrial)=0.5; 
    elseif Q_output(iTrial)>1
        Q_output(iTrial)=1; 
    end
    
    % sample values for the target distribution and background distribution
    tmp.T = -1; tmp.D = 1;
    while mean(tmp.T) < mean(tmp.D)
        tmp.T = randn([nImage*nBar 1])*distSD + Q_output(iTrial);
        tmp.D = randn([nImage*nBar 1])*distSD + bg;
    end
    
    % Get rig of values that are below 0 and that the screen cannot present.
    tmp.T(tmp.T<0) = 0;
    tmp.D(tmp.D<0) = 0;
    
    % Gets rid of values that are above 1 and that the screen cannot present.
    tmp.T(tmp.T>1) = 1;
    tmp.D(tmp.D>1) = 1;
    
    % Reshapes the data as bars x frame
    tmp.T = reshape(tmp.T, nBar, nImage);
    tmp.D = reshape(tmp.D, nBar, nImage);
    
    % put the target on the right of left
    if TargetOnLeft(iTrial) == 1
        Left_patch_lum  = tmp.T;
        Right_patch_lum = tmp.D;
    else
        Left_patch_lum  = tmp.D;
        Right_patch_lum = tmp.T;
    end

    % store in a variable    
    save_LpatchL(iTrial, :, :) = Left_patch_lum;
    save_RpatchL(iTrial, :, :) = Right_patch_lum;

    % --- DRAW FIXATION ---
    % #####################
    
    Screen('FillOval', windowPtr, fix.col, fix.pos);
    Screen('FillOval', windowPtr, bg, fix.posin);
    tFixOn(iTrial) = Screen('Flip', windowPtr);
    
    % --- PRESENT THE FLICKERING PATCHES ---
    % ######################################
        
    % FIRST IMAGE
    iImage = 1;
    Screen('FillOval', windowPtr, fix.col, fix.pos);
    Screen('FillOval', windowPtr, bg, fix.posin);
    
    % draw left patch
    Screen('FillRect', windowPtr, ...
        (Left_patch_lum(:, iImage) * ones(1, 3))', ...                      % color of the patch
        Left_patch_pos);                                                    % position of the bar within the patch.
    
    % draw right patch
    Screen('FillRect', windowPtr, ...
        (Right_patch_lum(:, iImage) * ones(1, 3))', ...                     % color of the patch
        Right_patch_pos);                                                   % position of the bar within the patch.
    
    % draw, at the next possible frame defined
    tStimOn(iTrial, 1) = Screen('Flip', windowPtr, ...
        tFixOn(iTrial) + (floor(fix.dur/ifi) - 0.5)*ifi);
    
    % FOLLOWING IMAGES
    for iImage = 2:nImage
        
        % draw fixation
        Screen('FillOval', windowPtr, fix.col, fix.pos);
        Screen('FillOval', windowPtr, bg, fix.posin);
        
        % draw left patch
        Screen('FillRect', windowPtr, ...
            (Left_patch_lum(:, iImage) * ones(1, 3))', ...                  % color of the patch
            Left_patch_pos);                                                % position of the bar within the patch.
        
        % draw right patch
        Screen('FillRect', windowPtr, ...
            (Right_patch_lum(:, iImage) * ones(1, 3))', ...                 % color of the patch
            Right_patch_pos);                                               % position of the bar within the patch.
        
        % draw, at the next possible frame defined
        tStimOn(iTrial, iImage) = Screen('Flip', windowPtr, ...
            tStimOn(iTrial, iImage-1) + (nFramePerImg-0.5)*ifi);
    end
    
    % --- DELAY PERIOD ---
    % ####################
    
    % display background during the delay period
    Screen('FillOval', windowPtr, fix.col, fix.pos);
    Screen('FillOval', windowPtr, bg, fix.posin);
    tStimOff(iTrial) = Screen('Flip', windowPtr, ...
        tStimOn(iTrial, nImage) + (nFramePerImg-0.5)*ifi);
    
    % --- ASK FOR A RESPONSE AND PRESENT FEEDBACK ---
    % ###############################################
    
    % DISPLAY GO SIGNAL AFTER THE DELAY
    Screen('FillOval', windowPtr, go.col, fix.pos);
    Screen('FillOval', windowPtr, bg, fix.posin);
    tGoOn(iTrial) = Screen('Flip', windowPtr, ...
        tStimOff(iTrial) + (floor(Dur_Delay(iTrial)/ifi) - 0.5)*ifi);
    
    % WAIT SUBJECT ANSWER
    isValidated = 0;
    while ~exittask && ~isValidated
        % Get subject responses
        [isKeyDown, keyTime, keyCode] = KbCheck;
        if isKeyDown
            if keyCode(KbName('ESCAPE')); % press escape to quit the experiment
                exittask = 1;
            elseif keyCode(KbName(key_LhHc));
                isValidated = 1; SConfLevel(iTrial) = 2; STargetPos(iTrial) = 1;
            elseif keyCode(KbName(key_LhLc));
                isValidated = 1; SConfLevel(iTrial) = 1; STargetPos(iTrial) = 1;
            elseif keyCode(KbName(key_RhLc));
                isValidated = 1; SConfLevel(iTrial) = 1; STargetPos(iTrial) = 2;
            elseif keyCode(KbName(key_RhHc));
                isValidated = 1; SConfLevel(iTrial) = 2; STargetPos(iTrial) = 2;
            end
        end
    end
    tRepValid(iTrial) = keyTime;
    if exittask == 1
        break
    end
    
    % SHOW SELECTED POSITION
    if fb.pre > 0
        text = '^';
        [w, h] = RectSize(Screen('TextBounds', windowPtr, text));
        if STargetPos(iTrial) == 1; shift = -1; else shift = 1; end
        
        % fixation
        Screen('FillOval', windowPtr, go.col, fix.pos);
        Screen('FillOval', windowPtr, bg, fix.posin);
        
        % selection        
        Screen('DrawText', windowPtr, text, ...
            ceil(crossX-w/2) + shift*patch.cx, ...
            ceil(crossY-h/2) + patch.h, colText);
        Screen('Flip', windowPtr)
    end
    
    % COMPUTE IF THE RESPONSE IS CORRECT
    if ( (TargetOnLeft(iTrial) == 1 && STargetPos(iTrial) == 1) ...
            || (TargetOnLeft(iTrial) ~= 1 && STargetPos(iTrial) == 2) )
        correct(iTrial) = 1;
    end
    
    % DISPLAY FEEDBACK
    Screen('FillOval', windowPtr, go.col, fix.pos);
    Screen('FillOval', windowPtr, bg, fix.posin);
    subf_DisplayFB(windowPtr, STargetPos(iTrial), fb, correct(iTrial), patch, crossX, crossY)
    tFBOn(iTrial) = Screen('Flip', windowPtr, ...
        tRepValid(iTrial) + (floor(fb.pre/ifi) - 0.5)*ifi);
    
    % --- INTER TRIAL INTERVAL, CLEAN UP & UPDATE DIFFICULTY ---
    % ##########################################################
    
    % return display after the FB duration
    % plot fixation during ITI only if the go signal is different from the
    % fixation (otherwise, it is difficult to get ready to the new trial).
    if any(fix.col ~= go.col)
        Screen('FillOval', windowPtr, go.col, fix.pos);
        Screen('FillOval', windowPtr, bg, fix.posin);
    end
    tITIOn(iTrial) = Screen('Flip', windowPtr, ...
        tFBOn(iTrial) + (floor(fb.post/ifi) - 0.5)*ifi);
    
    % Update Quest
    save_Quest_proc{iTrial} = Quest_proc; % store Quest_proc used at the at this trial
    Quest_proc = QuestUpdate(Quest_proc, Q_output(iTrial), correct(iTrial));
    
    % allow escape key during ITI
    if iti.compensate
        RT = tRepValid(iTrial) - tGoOn(iTrial);
        ThisITIduration = Dur_ITI(iTrial) - RT;
        if ThisITIduration < iti.mini
            ThisITIduration = iti.mini;
        end
    else
    ThisITIduration = Dur_ITI(iTrial);
    end
    
    while ((GetSecs - tITIOn(iTrial)) < ThisITIduration) && (exittask==0)
        [isKeyDown, keyTime, keyCode] = KbCheck;
        if isKeyDown
            if keyCode(KbName('ESCAPE')); % press escape to quit the experiment
                exittask = 1;
            end
        end
    end
    if exittask
        break
    end
end

% =========================================================================
%                             EXIT EXPERIMENT
% =========================================================================

% Clean up for exit
WaitSecs(1.5)
text = 'Fin de la session';
[w, h] = RectSize(Screen('TextBounds', windowPtr, text));
Screen('DrawText', windowPtr, text, ceil(crossX-w/2), ceil(crossY-h/2), colText);
Screen(windowPtr,'Flip');
WaitSecs(1.5)
sca                                 % close PTB window
% ListenChar(0)   % log back key press into the command line window

if IsOctave
    % stop printing everything right now in the command line
    page_screen_output(1)
end

if fullscreen == 1; ShowCursor; end

if ~strcmp(subID, 'test')
    % get a time stamp
    timestr = sprintf('%d-%d-%d_%d-%d-%1.0f', clock);
    
    if IsOctave 				
        save('-mat7-binary', ...
            [PathSave, ...
            'r_', NamePrefix, ...
            '_SUBJECT_', subID, '_Sess_', sessionID, '_', ...
            timestr, '.mat']);
    else
        save([PathSave, ...
            'r_', NamePrefix, ...
            '_SUBJECT_', subID, '_Sess_', sessionID, '_', ...
            timestr, '.mat']);
    end
end
