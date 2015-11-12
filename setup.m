% Setup various options
options.where = 'local';

options.num_trials = 100; % How many trials?
options.datadir = 'data/';
window = false;

options.dist = 65; % viewing distance in cm 
options.width = 38; % physical width of the screen in cm, 38 for MEG projector -> but better check on a regular basis
options.height = 29; % physical height of the screen in cm, 29 for the MEG projector screen inside the scanner
% If I set the projector to zoom and use a 1920x1080 resolution on the
% stimulus PC I get a nice display -> The image is ten roughly 1450x1080
options.resolution = [1450, 1080];
options.ppd = estimate_pixels_per_degree(options);
% Parameters for sampling the contrast + contrast noise
options.baseline_contrast = 0.5;
options.noise_sigmas = [.05 .1 .15];


options.ringwidth = options.ppd*3/4;
options.inner_annulus = 1.5*options.ppd;
options.radius = 4*options.ppd;
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


% Load marked feedback beeps
options.beeps = {repmat(audioread('low_mrk_150Hz.wav'), 1,2)', repmat(audioread('high_mrk_350Hz.wav'), 1,2)'};