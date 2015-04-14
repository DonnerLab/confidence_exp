function [small, large] = sample_contrast(contrast, baseline_contrast)
large = [0,0];
small = [0, 1];
while mean(large) < mean(small)
    large = (randn(1,10)+ baseline_contrast + contrast)/16;
    small = (randn(1,10)+ baseline_contrast)/16;
end
end
