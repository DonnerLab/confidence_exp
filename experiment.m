%% Confidence experiment
%
% Runs one session of the confidence experiment.
%
sca; clear all;
%% Global parameters.
rng('shuffle')
setup;

%% Setup the ParPort
trigger = setup_trigger;
setup_parport;

%% Parameters that control appearance of the gabors that are constant over
% trials
opts = {'sigma', options.gabor_dim_pix/6,...
    'num_cycles', 5,...
    'duration', .1,...
    'ppd', 31.9,... % for MEG display at 65cm viewing distance
    'xpos', [-10, 10],...
    'ypos', [6.5, 6.5]}; % Position Gabors in the lower hemifield to get activation in the dorsal pathaway



try
    %% Ask for some subject details and load old QUEST parameters
    subject.initials = input('Initials? ', 's');
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
    
    fprintf('QUEST Parameters\n----------------\nThreshold Guess: %1.4f\nSigma Guess: %1.4f\n',...
        quest.threshold_guess, quest.threshold_guess_sigma)
    if ~strcmp(input('OK? [y/n] ', 's'), 'y')
        throw(MException('EXP:Quit', 'User request quit'));
        
    end
    
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
        'contrast', [], 'contrast_left', [], 'contrast_right', [],...
        'confidence', [], 'confidence_rt', [], 'repeat', [], 'repeated_stim', [], 'session', [], 'random_offset', []);
    
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
            
            if options.repeat_contrast_levels && mod(trial, repeat_interval)==0             
                repeat_trial = true;
                repeated_stim = mod(repeat_counter-1, length(repeat_levels))+1;
                contrast_a = repeat_levels(repeated_stim).contrast_a;
                contrast_b = repeat_levels(repeated_stim).contrast_b;
                contrast = repeat_levels(repeated_stim).contrast;
                repeat_counter = repeat_counter+1;
            else                
                % Sample contrasts.
                contrast = min(1, max(0, (QuestQuantile(q, 0.5))));
                random_offset = (rand-0.5)*.5;
                [contrast_a, contrast_b] = sample_contrast(contrast, options.noise_sigma, options.baseline_contrast+random_offset);
                
            end
            side = randsample([1,-1], 1);
            
            if side == -1
                contrast_left = contrast_a;
                contrast_right = contrast_b;
            else
                contrast_left = contrast_b;
                contrast_right = contrast_a;
            end
            
            % Set options that are valid only for this trial.
            trial_options = [opts, {'contrast_left', contrast_left,...
                'contrast_right', contrast_right,...
                'gabor_angle', rand*180,...
                'baseline_delay', 1 + rand*0.5,...
                'confidence_delay', 0.5 + rand*1,...
                'feedback_delay', 0.5 + rand*1,...
                'rest_delay', 0.5}];
            
            [correct, response, confidence, rt_choice, rt_conf, timing] = one_trial(window, options.window_rect,...
                screenNumber, side, gabortex, options.gabor_dim_pix, audio,  trigger, trial_options);
            
            timings{trial} = timing;
            if ~isnan(correct) && ~repeat_trial
                q = QuestUpdate(q, contrast, correct);
            end
            results(trial) = struct('response', response, 'side', side, 'choice_rt', rt_choice, 'correct', correct,...
                'contrast', contrast, 'contrast_left', contrast_left, 'contrast_right', contrast_right,...
                'confidence', confidence, 'confidence_rt', rt_conf, 'repeat', repeat_trial, 'repeated_stim', repeated_stim,...
                'session', session_identifier, 'random_offset', random_offset);
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
        %LoadIdentityClut(window);        
        %Eyelink('StopRecording');

        disp(getReport(ME,'extended'));
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
