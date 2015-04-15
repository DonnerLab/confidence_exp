%% Confidence experiment
%
% Runs one session of the confidence experiment.
%
rng('shuffle')
pThreshold = .75;
beta = 3.5;
delta = 0.01;
gamma = 0.5;
num_trials = 25;
%% Where to store data
datadir = '/home/nwilming/u/confidence/data/';

%% Ask for some subject details, load old data etc.
initials = input('Initials? ', 's');
session = str2num(input('Which session # is this? ', 's')); %#ok<ST2NM>
datadir = fullfile(datadir, initials);
[s, mess, messid] = mkdir(datadir);
quest_file = fullfile(datadir, 'quest_results.mat');
if exist(quest_file, 'file') == 2
    qs = load(quest_file, 'qs', 'results_table');
    results_table = qs.results_table;
    qs = qs.qs;
    if ~(length(qs) == session-1)
        s = input(sprintf('There are %d sessions for this subject and you are doing session %d - so there is a gap. Want to stop here? [y/n] ', length(qs), session), 's');
        if strcmp(s, 'y')
            break
        end
    end
    
    threshold_guess = QuestQuantile(qs{end}, [0.5])
    threshold_guess_sigma = 2* (QuestQuantile(qs{end}, [0.95]) - QuestQuantile(qs{end}, [0.05]))
else    
    qs = {};
    results_table = {};
    threshold_guess = 0.15;
    threshold_guess_sigma = 1.5;
end


%% Some Setup
AssertOpenGL;
sca;
PsychDefaultSetup(2);
InitializePsychSound;
pahandle = PsychPortAudio('Open', [], [], 0);

timings = {};
try
    screenNumber = max(Screen('Screens'));
    
    % Open the screen
    %[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey, [400, 0, 1600, 900], 32, 2, [], [],  kPsychNeed32BPCFloat);
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, 0.5, [], 32, 2, [], [],  kPsychNeed32BPCFloat);
    HideCursor(screenNumber)
    Screen('Flip', window);
    
    % Make gabortexture
    gabor_dim_pix = 255;
    gabortex = make_gabor(window, 'gabor_dim_pix', gabor_dim_pix);
    % Maximum priority level
    topPriorityLevel = MaxPriority(window);
    
    % Set Options
    opts = {'sigma', gabor_dim_pix/6, 'num_cycles', 5,...
        'duration', .1,...
        'baseline_delay', 0.5,...
        'decision_delay', 0.25,...
        'confidence_delay', 0.5,...
        'confidence_delay', 0.5,...
        'confidence_delay', 0.5};
    
    % Do Quest to determine threshold
    q = QuestCreate(threshold_guess, threshold_guess_sigma, pThreshold, beta, delta, gamma);
    q.updatePdf = 1;
    baseline_contrast = 0.5;
    sigma = 0.15;
    results = struct('response', [], 'side', [], 'choice_rt', [], 'correct', [],...
        'contrast', [], 'contrast_left', [], 'contrast_right', [],...
        'confidence', [], 'confidence_rt', []);

%% Do Experiment
    for trial = 1:num_trials
        try
            contrast = abs(QuestQuantile(q, [0.5]));
            side = randsample([1,-1], 1);
            [contrast_a, contrast_b] = sample_contrast(contrast, sigma, baseline_contrast);
            if side == -1
                contrast_left = contrast_a;
                contrast_right = contrast_b;
            else
                contrast_left = contrast_b;
                contrast_right = contrast_a;
            end
            % set options for this experiment
            trial_options = [opts, {'contrast_left', contrast_left,...
                'contrast_right', contrast_right,...
                'gabor_angle', rand*180}];
            
            [correct, response, confidence, rt_choice, rt_conf, timing] = one_trial(window, windowRect,...
                screenNumber, side, gabortex, gabor_dim_pix, pahandle, trial_options);
            
            timings{trial} = timing;
            q = QuestUpdate(q, contrast, correct);
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
    PsychPortAudio('Close');    
    disp(ME);
    disp(ME.message);
    disp(ME.stack);
    disp(ME.identifier);
    
end
PsychPortAudio('Close');  
sca
fprintf('Saving data to %s\n', datadir)
qs{session} = q;    
session_table = struct2table(results);
results_table{session} = session_table;
save(fullfile(datadir, 'quest_results.mat'), 'qs', 'results_table')
writetable(session_table, fullfile(datadir, sprintf('%s_%d_results.csv', initials, session)));
