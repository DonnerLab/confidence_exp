%% run 10 calibrations and save data.
gt1 = nan(256, 10);
gt2 = nan(256, 10);
displayGamma = nan(10,1);
displayRange= nan(10,1);
raw_values = nan(10, 9);
options.gabor_dim_pix = 300;

for j = 1:1
    tic;
    [gammaTable1, gammaTable2, displayBaseline, dr, dg, maxLevel, vals, levels] = calibrate_display(9, 31.9, options.gabor_dim_pix, {'xpos', [-10, 10], 'ypos', [6.5, 6.5]});
    toc
    gt1(:, j) = gammaTable1;
    gt2(:, j) = gammaTable2;
    displayGamma(j) = dg;
    displayRange(j) = dr;
    raw_values(j,:) = vals;
end

save('right_calib.mat')
