%% Confidence experiment
%
% Runs one session of the confidence experiment.
%

%% Global parameters.
rng('shuffle')

% general setup
setup.MEG           = true; % true if sending triggers to the MEG
setup.Eye           = true; % true if using Eyelink

num_trials = 150; % How many trials?
datadir = '/Users/nwilming/u/confidence/data/';

% QUEST Parameters
pThreshold = .75; % Performance level and other QUEST parameters
beta = 3.5;
delta = 0.01;
gamma = 0.15;
% Parameters for sampling the contrast + contrast noise
baseline_contrast = 0.5;
noise_sigma = 0.15;
threshold_guess = 0.25;
threshold_guess_sigma = 0.5;
% Size of the gabor
gabor_dim_pix = 500;

% Should we repeat contrast levels? 1 = yes, 0 = no
repeat_contrast_levels = 1;
% Parameters that control appearance of the gabors that are constant over
% trials
opts = {'sigma', gabor_dim_pix/6,...
    'num_cycles', 5,...
    'duration', .1,...
    'xpos', [-10, 10],...
    'ypos', [5, 5]}; % Position Gabors in the lower hemifield to get activation in the dorsal pathaway

%% Setup the ParPort
if setup.MEG,
    % install and/or initialize the kernel-level I/O driver
    config_io;
    % optional step: verify that the driver was successfully installed/initialized
    global cogent;
    if( cogent.io.status ~= 0 )
        error('inp/outp installation failed');
    end
    
    % DO NOT USE DUAL MONITOR SETUP ON WINDOWS 7 !!!!!!!
    vswitch(00); % switches to single monitor, will have the taskbar but more accurate timing
end


try
    %% Ask for some subject details and load old QUEST parameters
    initials = input('Initials? ', 's');
    datadir = fullfile(datadir, initials);
    [~, ~, ~] = mkdir(datadir);
    quest_file = fullfile(datadir, 'quest_results.mat');
    session_struct = struct('q', [], 'results', [], 'date', datestr(clock));
    results_struct = session_struct;
    session_identifier = datestr(clock);
    append_data = false;
    if exist(quest_file, 'file') == 2
        if strcmp(input('There is previous data for this subject. Load last QUEST parameters? [y/n] ', 's'), 'y')
            [~, results_struct, threshold_guess, threshold_guess_sigma] = load_subject(quest_file);
            append_data = true;
        end
    end
    
    fprintf('QUEST Parameters\n----------------\nThreshold Guess: %1.4f\nSigma Guess: %1.4f\n', threshold_guess, threshold_guess_sigma)
    if ~strcmp(input('OK? [y/n] ', 's'), 'y')
        throw(MException('EXP:Quit', 'User request quit'));
        
    end
    
    timings = {};
    % Maximum priority level
    topPriorityLevel = MaxPriority(window);
    
    % Set up QUEST
    q = QuestCreate(threshold_guess, threshold_guess_sigma, pThreshold, beta, delta, gamma);
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
    repeat_contrast_levels = 0;
    if repeat_contrast_levels
        contrast_file_name = fullfile(datadir, 'repeat_contrast_levels.mat');
        repeat_levels = load(contrast_file_name, 'levels');
        repeat_levels = repeat_levels.levels;
        % I assume that repeat_contrast_levels contains a struct array with
        % fields contrast_a and contrast_b.
        assert(num_trials > length(repeat_levels));
        repeat_interval = 2; %'Replace with a sane value'; % <-- Set me!
        repeat_counter = 1;
    end
    %% Do Experiment
    for trial = 1:num_trials
        try
            repeat_trial = false;
            repeated_stim = nan;
            fprintf('Trial: %i\n', trial);
            if repeat_contrast_levels && mod(trial, repeat_interval)==0
                fprintf('This is a repeated stimulus\n');
                repeat_trial = true;
                repeated_stim = mod(repeat_counter-1, length(repeat_levels))+1;
                contrast_a = repeat_levels(repeated_stim).contrast_a;
                contrast_b = repeat_levels(repeated_stim).contrast_b;
                contrast = repeat_levels(repeated_stim).contrast;
                repeat_counter = repeat_counter+1;
            else
                fprintf('This is NOT a repeated stimulus\n');
                % Sample contrasts.
                contrast = min(1, max(0, (QuestQuantile(q, 0.5))));
                random_offset = (rand-0.5)*.5;
                [contrast_a, contrast_b] = sample_contrast(contrast, noise_sigma, baseline_contrast+random_offset);
                
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
            
            [correct, response, confidence, rt_choice, rt_conf, timing] = one_trial(window, windowRect,...
                screenNumber, side, gabortex, gabor_dim_pix, pahandle, trial_options);
            
            timings{trial} = timing;
            if ~isnan(correct) && ~repeat_trial
                q = QuestUpdate(q, contrast, correct);
            end
            results(trial) = struct('response', response, 'side', side, 'choice_rt', rt_choice, 'correct', correct,...
                'contrast', contrast, 'contrast_left', contrast_left, 'contrast_right', contrast_right,...
                'confidence', confidence, 'confidence_rt', rt_conf, 'repeat', repeat_trial, 'repeated_stim', repeated_stim,...
                'session', session_identifier, 'random_offset', random_offset);
        catch ME
            if (strcmp(ME.identifier,'EXP:Quit'))
                break
            else
                rethrow(ME);
            end
        end
    end
catch ME   
    LoadIdentityClut(window);    
    if (strcmp(ME.identifier,'EXP:Quit'))
        return
    else
        disp(getReport(ME,'extended'));
        rethrow(ME);
    end        
end
LoadIdentityClut(window)
PsychPortAudio('Close');
sca
fprintf('Saving data to %s\n', datadir)
session_struct.q = q;
session_struct.results = struct2table(results);
if ~append_data
    results_struct = session_struct;
else
    disp('Trying to append')
    results_struct(length(results_struct)+1) = session_struct;
end
save(fullfile(datadir, 'quest_results.mat'), 'results_struct')
writetable(session_struct.results, fullfile(datadir, sprintf('%s_%s_results.csv', initials, datestr(clock))));
