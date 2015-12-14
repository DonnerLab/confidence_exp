%% Confidence experiment
%
% Runs one session of the confidence experiment.
%
sca; clear all;
%% Global parameters.
rng('shuffle')
setup;
if strcmp(options.do_trigger, 'yes')
    addpath matlabtrigger/
else
   addpath faketrigger/
end
%% Setup the ParPort
trigger_enc = setup_trigger;
%setup_parport;

opts = {'num_cycles', 5,...
    'duration', .1,...
    'ppd', options.ppd,...%31.9,... % for MEG display at 65cm viewing distance
    'xpos', [-10, 10],...
    'ypos', [6.5, 6.5]}; % Position Gabors in the lower hemifield to get activation in the dorsal pathaway
session_identifier =  datestr(now, 30);

try
   
    subject.initials = input('Initials? ', 's');

    %% Configure Psychtoolbox
    setup_ptb; 
    % start recording eye position
    Eyelink('StartRecording');
    % record a few samples before we actually start displaying
    WaitSecs(0.1);
    % mark zero-plot time in data file
    Eyelink('message', 'Start recording Eyelink');

    for trial = 1:100
        try
            % This supplies the title at the bottom of the eyetracker display
            Eyelink('command', 'record_status_message "TRIAL %d/%d"', trial, options.num_trials);
            Eyelink('message', 'TRIALID %d', trial);
            
            repeat_trial = false;
            repeated_stim = nan;
            
            % Sample contrasts.
            contrast = 0.25;                        
            ns = 0.25;
            [side, contrast_fluctuations] = sample_contrast(1, contrast,...
                ns, options.baseline_contrast); % Converts effective contrast to absolute contrst
            expand = randsample([-1, 1], 1);

            
            % Set options that are valid only for this trial.
            trial_options = [opts, {...
                'contrast_probe', contrast_fluctuations,...
                'contrast_ref', options.baseline_contrast,...
                'baseline_delay', 1,...
                'feedback_delay', 0,...
                'rest_delay', 0.5,...
                'ringwidth', options.ringwidth,...
                'radius', options.radius,...
                'inner_annulus', options.inner_annulus,...
                'sigma', options.sigma,...
                'cutoff', options.cutoff,...
                'expand', expand,...
                'kbqdev', options.kbqdev}];
            
            localizer_trial(window, options.window_rect,...
                screenNumber, ringtex, audio,  trigger_enc, options.beeps, options.ppd, trial_options);
            

            Eyelink('message', 'TRIALEND %d', trial);
        catch ME
            if (strcmp(ME.identifier,'EXP:Quit'))
                break
            else
                rethrow(ME);
            end
        end
    end
catch ME
    PsychPortAudio('close')
    if (strcmp(ME.identifier,'EXP:Quit'))
        return
    else
        disp(getReport(ME,'extended'));
        Eyelink('StopRecording');        
        Screen('LoadNormalizedGammaTable', window, old_gamma_table);

        rethrow(ME);
    end
end
LoadIdentityClut(window);
PsychPortAudio('Close');
sca
fprintf('Saving data to %s\n', options.datadir)
eyefilename   = fullfile(options.datadir, sprintf('%s_localizer_%s.edf', subject.initials, session_identifier));
Eyelink('CloseFile');
Eyelink('WaitForModeReady', 500);
try
    status = Eyelink('ReceiveFile', options.edfFile, eyefilename);
    disp(['File ' eyefilename ' saved to disk']);
catch
    warning(['File ' eyefilename ' not saved to disk']);
end

Eyelink('StopRecording');
