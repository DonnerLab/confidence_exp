function [low, high] = contrast_colors(contrast, baseline)
%% Make two colors that have a specified contrast around a baseline

low = [baseline-contrast/2., baseline-contrast/2., baseline-contrast/2., 1];
high = [baseline+contrast/2., baseline+contrast/2., baseline+contrast/2., 1];