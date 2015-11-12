function [low, high] = contrast_colors(contrast, baseline)
%% Make two colors that have a specified contrast around a baseline
contrast = (contrast/2);
low = [baseline-contrast, baseline-contrast, baseline-contrast, 1];
high = [baseline+contrast, baseline+contrast, baseline+contrast, 1];