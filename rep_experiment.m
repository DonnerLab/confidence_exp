%% Confidence experiment
%
% Repeats one session of the confidence experiment.
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

%% Parameters that control appearance of the gabors that are constant over
% trials
opts = {'num_cycles', 5,...
    'duration', .1,...
    'ppd', options.ppd,...%31.9,... % for MEG display at 65cm viewing distance
    'xpos', [-10, 10],...
    'ypos', [6.5, 6.5]}; % Position Gabors in the lower hemifield to get activation in the dorsal pathaway




%% Ask for some subject details and load old QUEST parameters
subject.initials = input('Initials? ', 's');
options.datadir = fullfile(options.datadir, subject.initials);
[~, ~, ~] = mkdir(options.datadir);
quest_file = fullfile(options.datadir, 'quest_results.mat');
session_struct = struct('q', [], 'results', [], 'date', datestr(clock));
results_struct = session_struct;
session_identifier =  datestr(now, 30);

previous_trials = select_time(options);

append_data = true;



%% Configure Psychtoolbox
setup_ptb;


% start recording eye position
Eyelink('StartRecording');
% record a few samples before we actually start displaying
WaitSecs(0.1);
% mark zero-plot time in data file
Eyelink('message', 'Start recording Eyelink');



% A structure to save results.
results = struct('response', [], 'side', [], 'choice_rt', [], 'correct', [],...
    'contrast', [], 'contrast_probe', [], 'contrast_ref', [],...
    'confidence', [], 'repeat', [], 'repeated_stim', [], 'session', [], 'noise_sigma', [], 'expand', []);


%% Do Experiment
try
for trial = 1:options.num_trials
    try
        prev_trial = previous_trials(trial);
        % This supplies the title at the bottom of the eyetracker display
        Eyelink('command', 'record_status_message "TRIAL %d/%d"', trial, options.num_trials);
        Eyelink('message', 'TRIALID %d', trial);
        
        repeat_trial = false;
        repeated_stim = nan;
        
        % Sample contrasts.
        contrast = prev_trial.contrast; %min(1, max(0, (QuestQuantile(q, 0.5))));
        side = prev_trial.side; %randsample([1,-1], 1);
        %ns  = randsample([1, 2, 3], 1);
        noise_sigma = prev_trial.noise_sigma; %options.noise_sigmas(ns);
        ns = options.nsreverse(noise_sigma);
        
        contrast_probe = prev_trial.contrast_probe;
        expand = prev_trial.expand; %randsample([-1, 1], 1);
        % Set options that are valid only for this trial.
        trial_options = [opts, {...
            'contrast_probe', contrast_probe,...
            'contrast_ref', options.baseline_contrast,...
            'baseline_delay', 1 + rand*0.5,...
            'feedback_delay', 0.5 + rand*1,...
            'rest_delay', 0.5,...
            'ringwidth', options.ringwidth,...
            'radius', options.radius,...
            'inner_annulus', options.inner_annulus,...
            'sigma', options.sigma,...
            'cutoff', options.cutoff,...
            'expand', expand,...
            'kbqdev', options.kbqdev}];
        
        % Encode trial number in triggers.
        bstr = dec2bin(trial, 8);
        pins = find(str2num(reshape(bstr',[],1))');
        WaitSecs(0.005);
        for pin = pins
            trigger(pin);
            WaitSecs(0.005);
        end
        [correct, response, confidence, rt_choice, timing] = one_trial(window, options.window_rect,...
            screenNumber, side, ns, ringtex, audio,  trigger_enc, options.beeps, options.ppd, trial_options);
        
        timings{trial} = timing;
        results(trial) = struct('response', response, 'side', side, 'choice_rt', rt_choice, 'correct', correct,...
            'contrast', contrast, 'contrast_probe', contrast_probe, 'contrast_ref', options.baseline_contrast,...
            'confidence', confidence, 'repeat', 1, 'repeated_stim', repeated_stim,...
            'session', session_identifier, 'noise_sigma', noise_sigma, 'expand', expand);
        Eyelink('message', 'TRIALEND %d', trial);
        
        
        
    catch ME
        if (strcmp(ME.identifier,'EXP:Quit'))
            rethrow(ME)
        else
            disp(getReport(ME,'extended'));
            Eyelink('StopRecording');
            Screen('LoadNormalizedGammaTable', window, old_gamma_table);
            
            rethrow(ME);
        end
    end
end
catch ME
    disp(getReport(ME,'extended'));
end
Eyelink('StopRecording');

LoadIdentityClut(window);
PsychPortAudio('Close');
sca
fprintf('Saving data to %s\n', options.datadir)
eyefilename   = fullfile(options.datadir, sprintf('%s_%s.edf', subject.initials, session_identifier));
Eyelink('CloseFile');
Eyelink('WaitForModeReady', 500);
try
    status = Eyelink('ReceiveFile', options.edfFile, eyefilename);
    disp(['File ' eyefilename ' saved to disk']);
catch
    warning(['File ' eyefilename ' not saved to disk']);
end

Eyelink('StopRecording');

%session_struct.results = struct2table(results);
session_struct.results = results;

save( fullfile(options.datadir, sprintf('%s_%s_results.mat', subject.initials, datestr(clock))), 'session_struct')
if ~append_data
    results_struct = session_struct;
else
    disp('Trying to append')
    results_struct(length(results_struct)+1) = session_struct;
end
save(fullfile(options.datadir, 'quest_results.mat'), 'results_struct')
%writetable(session_struct.results, fullfile(datadir, sprintf('%s_%s_results.csv', initials, datestr(clock))));
