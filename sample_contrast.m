function [small, large] = sample_contrast(contrast, sigma, baseline_contrast)
large = [0,0];
small = [0, 1];
while mean(large) < mean(small)
    large = randn(1,10)*sigma + contrast + baseline_contrast ;
    small = randn(1,10)*sigma + baseline_contrast;
end
end
