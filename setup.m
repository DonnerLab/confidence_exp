% Setup various options

options.num_trials = 100; % How many trials?
options.datadir = 'data/';
window = false;

options.dist = 65; % viewing distance in cm 
options.width = 42; % physical width of the screen in cm, 53.5 for BENQ in EEG lab
options.height = 32; % physical height of the screen in cm, 42 for the MEG projector screen inside the scanner

% Parameters for sampling the contrast + contrast noise
options.baseline_contrast = 0.5;
options.noise_sigma = 0.15;


options.ringwidth = estimate_pixels_per_degree(0, 65)*3/4;
options.inner_annulus = 1.5*estimate_pixels_per_degree(0, 65);
options.radius = 4*estimate_pixels_per_degree(0, 65);
options.sigma = 75;
options.cutoff = 5.5;

% Should we repeat contrast levels? 1 = yes, 0 = no
options.repeat_contrast_levels = 1;


% QUEST Parameters
quest.pThreshold = .75; % Performance level and other QUEST parameters
quest.beta = 3.5;
quest.delta = 0.5/128;
quest.gamma = 0.15;
quest.threshold_guess = 0.025;
quest.threshold_guess_sigma = 0.25;