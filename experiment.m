%% Confidence experiment
%
% Runs one session of the confidence experiment.
%
sca; clear all;
%% Global parameters.
rng('shuffle')
setup;

%% Setup the ParPort
trigger_enc = setup_trigger;
%setup_parport;

%% Parameters that control appearance of the gabors that are constant over
% trials
opts = {'num_cycles', 5,...
    'duration', .1,...
    'ppd', estimate_pixels_per_degree(0, 65),...%31.9,... % for MEG display at 65cm viewing distance
    'xpos', [-10, 10],...
    'ypos', [6.5, 6.5]}; % Position Gabors in the lower hemifield to get activation in the dorsal pathaway



try
    %% Ask for some subject details and load old QUEST parameters
    subject.initials = 'NW' % input('Initials? ', 's');
    options.datadir = fullfile(options.datadir, subject.initials);
    [~, ~, ~] = mkdir(options.datadir);
    quest_file = fullfile(options.datadir, 'quest_results.mat');
    session_struct = struct('q', [], 'results', [], 'date', datestr(clock));
    results_struct = session_struct;
    session_identifier =  datestr(now, 30);
    append_data = false;
    if exist(quest_file, 'file') == 2
        if strcmp(input('There is previous data for this subject. Load last QUEST parameters? [y/n] ', 's'), 'y')
            [~, results_struct, quest.threshold_guess, quest.threshold_guess_sigma] = load_subject(quest_file);
            append_data = true;
        end
    end
    
    %     fprintf('QUEST Parameters\n----------------\nThreshold Guess: %1.4f\nSigma Guess: %1.4f\n',...
    %         quest.threshold_guess, quest.threshold_guess_sigma)
    %     if ~strcmp(input('OK? [y/n] ', 's'), 'y')
    %         throw(MException('EXP:Quit', 'User request quit'));
    %
    %     end
    
    %% Configure Psychtoolbox
    setup_ptb;
    
    %% Set up Eye Tracker
    [el, options] = ELconfig(window, subject, options);
    
    % Calibrate the eye tracker
    EyelinkDoTrackerSetup(el);
    
    % start recording eye position
    Eyelink('StartRecording');
    % record a few samples before we actually start displaying
    WaitSecs(0.1);
    % mark zero-plot time in data file
    Eyelink('message', 'Start recording Eyelink');
    
    %% Set up QUEST
    q = QuestCreate(quest.threshold_guess, quest.threshold_guess_sigma, quest.pThreshold, quest.beta, quest.delta, quest.gamma);
    q.updatePdf = 1;
    
    % A structure to save results.
    results = struct('response', [], 'side', [], 'choice_rt', [], 'correct', [],...
        'contrast', [], 'contrast_probe', [], 'contrast_ref', [],...
        'confidence', [], 'repeat', [], 'repeated_stim', [], 'session', [], 'noise_sigma', [], 'expand', []);
    
    % Sometimes we want to repeat the same contrast fluctuations, load them
    % here. You also need to set the repeat interval manually. The repeat
    % interval specifies the interval between repeated contrast levels.
    % If you want to show each of, e.g. 5 repeats twice and you have 100
    % trials, set it to 10.
    options.repeat_contrast_levels = 0;
    if options.repeat_contrast_levels
        contrast_file_name = fullfile(options.datadir, 'repeat_contrast_levels.mat');
        repeat_levels = load(contrast_file_name, 'levels');
        repeat_levels = repeat_levels.levels;
        % I assume that repeat_contrast_levels contains a struct array with
        % fields contrast_a and contrast_b.
        assert(options.num_trials > length(repeat_levels));
        repeat_interval = 2; %'Replace with a sane value'; % <-- Set me!
        repeat_counter = 1;
    end
    %% Do Experiment
    for trial = 1:options.num_trials
        try
            % This supplies the title at the bottom of the eyetracker display
            Eyelink('command', 'record_status_message "TRIAL %d/%d"', trial, options.num_trials);
            Eyelink('message', 'TRIALID %d', trial);
            
            repeat_trial = false;
            repeated_stim = nan;
            
            % Sample contrasts.
            contrast = min(1, max(0, (QuestQuantile(q, 0.5))));
            side = randsample([1,-1], 1);
            noise_sigma = randsample(options.noise_sigmas, 1);
            [side, contrast_fluctuations] = sample_contrast(side, contrast, noise_sigma, options.baseline_contrast);
            [side mean(contrast_fluctuations)]
            expand = randsample([-1, 1], 1);
            % Set options that are valid only for this trial.
            trial_options = [opts, {...
                'contrast_probe', contrast_fluctuations,...
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
            
            [correct, response, confidence, rt_choice, timing] = one_trial(window, options.window_rect,...
                screenNumber, side, ringtex, audio,  trigger_enc, options.beeps, trial_options);
            
            timings{trial} = timing;
            if ~isnan(correct) && ~repeat_trial
                q = QuestUpdate(q, contrast, correct);
            end
            results(trial) = struct('response', response, 'side', side, 'choice_rt', rt_choice, 'correct', correct,...
                'contrast', contrast, 'contrast_probe', contrast_fluctuations, 'contrast_ref', options.baseline_contrast,...
                'confidence', confidence, 'repeat', repeat_trial, 'repeated_stim', repeated_stim,...
                'session', session_identifier, 'noise_sigma', noise_sigma, 'expand', expand);
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
    if (strcmp(ME.identifier,'EXP:Quit'))
        return
    else
        Eyelink('StopRecording');        
        disp(getReport(ME,'extended'));
        Screen('LoadNormalizedGammaTable', window, old_gamma_table);

        rethrow(ME);
    end
end
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

session_struct.q = q;
%session_struct.results = struct2table(results);
session_struct.results = results;
if ~append_data
    results_struct = session_struct;
else
    disp('Trying to append')
    results_struct(length(results_struct)+1) = session_struct;
end
save(fullfile(options.datadir, 'quest_results.mat'), 'results_struct')
%writetable(session_struct.results, fullfile(datadir, sprintf('%s_%s_results.csv', initials, datestr(clock))));
