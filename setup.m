% Setup various options

options.num_trials = 1; % How many trials?
options.datadir = 'E:\Users\nwilming\Desktop\nwilming\confidence\data';
window = false;

options.dist = 65; % viewing distance in cm 
options.width = 42; % physical width of the screen in cm, 53.5 for BENQ in EEG lab
options.height = 32; % physical height of the screen in cm, 42 for the MEG projector screen inside the scanner

% Parameters for sampling the contrast + contrast noise
options.baseline_contrast = 0.5;
options.noise_sigma = 0.15;


options.ringwidth = 50;
% Should we repeat contrast levels? 1 = yes, 0 = no
options.repeat_contrast_levels = 1;


% QUEST Parameters
quest.pThreshold = .75; % Performance level and other QUEST parameters
quest.beta = 3.5;
quest.delta = 0.01;
quest.gamma = 0.15;
quest.threshold_guess = 0.125;
quest.threshold_guess_sigma = 0.25;