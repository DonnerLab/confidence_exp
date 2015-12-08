function [up, large, eff_noise] = sample_contrast(up, effective_contrast, sigma, baseline_contrast)
%% 
% up =  1 = larger than baseline contrast -> Stim correct
% up = -1 = smaller than baseline contrast -> Ref correct
effective_contrast = (up*effective_contrast) + baseline_contrast;
eff_noise = randn(1,10)*sigma;
large =  eff_noise + effective_contrast;

if mean(large) > baseline_contrast 
    up = 1;
else
    up = -1;
end
    
    
end


