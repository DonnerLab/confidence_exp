%% Confidence experiment
%
% Runs one session of the confidence experiment.
%

%% Global parameters.
rng('shuffle')

num_trials = 25; % How many trials?
datadir = '/home/nwilming/u/confidence/data/';

% QUEST Parameters
pThreshold = .75; % Performance level and other QUEST parameters
beta = 3.5; 
delta = 0.01;
gamma = 0.15;
% Parameters for sampling the contrast + contrast noise
baseline_contrast = 0.5;
noise_sigma = 0.15;   
threshold_guess = 0.5;
threshold_guess_sigma = 0.5;
% Size of the gabor
gabor_dim_pix = 500;
% Parameters that control appearance of the gabors that are constant over
% trials
opts = {'sigma', gabor_dim_pix/6,...
    'num_cycles', 5,...
    'duration', .1,...
    'xpos', [-10, 10],...
    'ypos', [5, 5]}; % Position Gabors in the lower hemifield to get activation in the dorsal pathaway
try
    %% Ask for some subject details and load old QUEST parameters
    initials = input('Initials? ', 's');
    datadir = fullfile(datadir, initials);
    [~, ~, ~] = mkdir(datadir);
    quest_file = fullfile(datadir, 'quest_results.mat');
    session_struct = struct('q', [], 'results', [], 'date', datestr(clock));
    results_struct = session_struct;
    
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
    
    %% Some Setup
    AssertOpenGL;
    sca;
    PsychDefaultSetup(2);
    InitializePsychSound;
    pahandle = PsychPortAudio('Open', [], [], 0);
    
    timings = {};
    
    screenNumber = max(Screen('Screens'));
    
    % Open the screen
    %[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey, [400, 0, 1600, 900], 32, 2, [], [],  kPsychNeed32BPCFloat);
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, 0.5, [], 32, 2, [], [],  kPsychNeed32BPCFloat);
    HideCursor(screenNumber)
    Screen('Flip', window);
    
    % Make gabortexture
    gabortex = make_gabor(window, 'gabor_dim_pix', gabor_dim_pix);
    % Maximum priority level
    topPriorityLevel = MaxPriority(window);
          
    % Set up QUEST
    q = QuestCreate(threshold_guess, threshold_guess_sigma, pThreshold, beta, delta, gamma);
    q.updatePdf = 1;
    
    % A structure to save results.
    results = struct('response', [], 'side', [], 'choice_rt', [], 'correct', [],...
        'contrast', [], 'contrast_left', [], 'contrast_right', [],...
        'confidence', [], 'confidence_rt', []);
    
    %% Do Experiment
    for trial = 1:num_trials
        try
            % Sample contrasts.
            contrast = min(1, max(0, (QuestQuantile(q, 0.5))));
            side = randsample([1,-1], 1);
            [contrast_a, contrast_b] = sample_contrast(contrast, noise_sigma, baseline_contrast);
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
            if ~isnan(correct)
                q = QuestUpdate(q, contrast, correct);
            end
            results(trial) = struct('response', response, 'side', side, 'choice_rt', rt_choice, 'correct', correct,...
                'contrast', contrast, 'contrast_left', contrast_left, 'contrast_right', contrast_right,...
                'confidence', confidence, 'confidence_rt', rt_conf);
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
        rethrow(ME);
    end
    PsychPortAudio('Close');
    disp(getReport(ME,'extended'));
    
end
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
