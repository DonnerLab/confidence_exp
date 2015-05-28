function make_repeat_contrast_levels(datadir, num_trials, contrast, noise_sigma, baseline_contrast)
% Make a set of contrast levels that can be repeated in different sessions
% of the experiment.
levels = struct();
for idx = 1:num_trials    
    [contrast_a, contrast_b] = sample_contrast(contrast, noise_sigma, baseline_contrast);
    levels(idx).contrast_a = contrast_a;
    levels(idx).contrast_b = contrast_b;
    levels(idx).contrast = contrast;
end
save(fullfile(datadir, 'repeat_contrast_levels.mat'), 'levels')
end