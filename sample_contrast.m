function [up, large] = sample_contrast(up, contrast, sigma, baseline_contrast)
%% 
% up =  1 = larger than baseline contrast
% up = -1 = smaller than baseline contrast
large = randn(1,10)*sigma + up*contrast + baseline_contrast;

if mean(large) > baseline_contrast && up == -1
    up = 1;
elseif mean(large) < baseline_contrast && up == 1
    up = -1;
end
    
    
end

