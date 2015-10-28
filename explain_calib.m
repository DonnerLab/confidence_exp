ls%% A script to explain how the colorhug calibration and matching works.
%
% This is a demonstration of how to equalize luminance between to patches
% on a screen when the luminance of each patch can be measured with a color
% hug device.
%
% Ok, when I say luminance I mean something that is proportional to
% luminance. The color hugs doen't actually output luminance directly
ypos = [3.8, 3.8];
xpos = [-7.5, 7.5];
% 1st Step: Measure luminance.
numMeasures = 15;
ppd = 40;
gabor_dim_pix = 300;

% Get the mapping of sensors to left/right correct:
left_sensor = 1;
right_sensor = 2;

% Get luminance measurements. Make sure that colorhug 1 = left and 2 =
% right
path = '/home/meg/Documents/Argyll_V1.7.0/bin';
[ gammaTables1, gammaTables2, displayBaselines, displayRanges, displayGammas, maxLevel, measurements, levels] = calibrate_display(...
    numMeasures, ppd, gabor_dim_pix, 'path', path, 'devices', [1, 2], 'ypos', ypos, 'xpos', xpos);
rlevels = levels/max(levels);
left = mean(measurements{left_sensor}(:,1:3), 2)';
right = mean(measurements{right_sensor}(:,1:3), 2)';

max_value = max(left(end), right(end));

% 2nd Step: Get look up tables. Be careful, since the max values are set,
% the gamma tables do not simply go from X to X' linearized. 
[left_signal, left_interp, gamma_left] = get_gamma_table(levels, left, 1500, max_value);
[right_signal, right_interp, gamma_right] = get_gamma_table(levels, right, 1500, max_value);
signal = left_signal;

% 3rd Step: Match luminance of your stimuli. Left is the reference. Right
% is to be adapted. Matched should be the signal shown on the right side.
[matched, Idiff, Ldiff] = match_luminance(levels/max(levels), signal, left_interp, signal, right_interp);     

% 4th Step: Measure if it works
[first_corrected] = test_calibration(0, ppd, gabor_dim_pix,  levels/max(levels), matched, 'path', path, 'devices', [1,2], 'ypos', ypos, 'xpos', xpos);

% 5th Step: Compare
coleft = mean(first_corrected{left_sensor}(:,1:3), 2)';
coright = mean(first_corrected{right_sensor}(:,1:3), 2)';
figure()
plot(coleft, 'b')
hold all
plot(left, 'b--')
plot(coright, 'r')
hold all
plot(right, 'r--')
legend('Matched left', 'Non matched left', 'Matched right', 'Non matched right')

%% Now let's do the same with gamma correction.  
% We need to equalize differences between T(T^-1(X)) = Lum
% First compute gamma correction look up tables that do not take the max
% luminance on the screen into account. This allows us to correct each
% grating individually.
[left_signal, ~, gamma_left] = get_gamma_table(levels, left, 1500);
[right_signal, ~, gamma_right] = get_gamma_table(levels, right, 1500);
signal = left_signal;

% My signal here is just all possible gray values. Therefore this maps the
% input X into X' (gamma corrected) for each side.
gleft = apply_lut(signal, signal, gamma_left);
gright = apply_lut(signal, signal, gamma_right);

% Now translate this into luminances. This applies the lookup tables from
% above which do take the maximum luminance of both patches into account.
Lgleft = apply_lut(gleft, signal, left_interp);
Lgright = apply_lut(gright, signal, right_interp);

% Now apply gamma correction to a set of gray values that we will actually
% show later.
levels_left = apply_lut(rlevels, signal, gamma_left);
levels_right = apply_lut(rlevels, signal, gamma_right);

% Now apply the luminance correction method. levels matched is then the
% gray values that need to be shown on the right.
[levels_matched, Idiff, Ldiff] = match_luminance(levels_right, signal, left_interp, signal, right_interp);     

% To show that it works, let's compute expected luminances and plot these.
Llevel_matched = apply_lut(levels_matched, signal, right_interp);
Llevel_left = apply_lut(levels_left, signal, left_interp);
Llevel_right = apply_lut(levels_right, signal, right_interp);

clf()
subplot(1,2,2)
plot(rlevels, levels_right, 'b')
hold on
plot(rlevels, Llevel_matched, 'k--')
plot(rlevels, Llevel_right, 'r')
ylim([0,1])
title('right')
xlabel('Gray level')

subplot(1,2,1)
plot(rlevels, Llevel_left, 'r')
hold on
plot(rlevels, Llevel_matched, 'k--')
plot(rlevels, levels_left, 'b')
ylim([0,1])
title('left')
legend('Lum', 'Matched lum', 'level')
xlabel('Gray level')
ylabel('Luminance or gamma corr. gray')

% Measure if it works
pause(15)
[corrected_not_measured] = test_calibration(0, ppd, gabor_dim_pix,  levels_left, levels_matched, 'path', path, 'devices', [1,2], 'ypos', ypos, 'xpos', xpos);
pause(15)
[corrected_non_matched_not_measured] = test_calibration(0, ppd, gabor_dim_pix,  levels_left, levels_left, 'path', path, 'devices', [1,2], 'ypos', ypos, 'xpos', xpos);
% Compare
cleft = mean(corrected{left_sensor}(:,1:3), 2)';
cright = mean(corrected{right_sensor}(:,1:3), 2)';
nccleft = mean(corrected_non_matched{left_sensor}(:,1:3), 2)';
nccright = mean(corrected_non_matched{right_sensor}(:,1:3), 2)';
figure()
plot(rlevels, cleft, 'r')
hold all
plot(rlevels, nccleft, 'r--')
plot(rlevels, cright, 'b')
plot(rlevels, nccright, 'b--')
legend('Matched left', 'Non matched left', 'Matched right', 'Non matched right')
