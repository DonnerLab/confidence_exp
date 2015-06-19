
%% Load data and make gamma tables.
close all; 
clear

load left_calib
[signal, left_nomxval, gamma_left_nomxval] = get_gamma_table(levels, mean(raw_values,1), 1500);
max(mean(raw_values,1))
max_left = max(mean(raw_values,1));

load right_calib
max_right = max(mean(raw_values,1));
max_val = max(max_right, max_left);
[signal, right_nomxval, gamma_right_nomxval] = get_gamma_table(levels, mean(raw_values,1), 1500);
[signal, right, gamma_right] = get_gamma_table(levels, mean(raw_values,1), 1500, max_val);

load left_calib
[signal, left, gamma_left] = get_gamma_table(levels, mean(raw_values,1), 1500, max_val);
close all

signal = signal/max(signal);

%% Make a Gabor with contrast = 0.5 and background = 0.5
figure()
G = gabor(300, 45, 0.1, 0.009, 1, 0.5) * 0.5 + 0.5;
Gl = apply_lut(G, signal, left_nomxval);
Gr = apply_lut(G, signal, right_nomxval);
% Without any correction.
subplot(3, 3, [1,2])
imshow([Gl, Gr], [0,1])
ylabel('No correction')
subplot(3, 3, 3)
hold on; 
plot(G(:), Gl(:), '+r')
plot(G(:), Gr(:), '+g')
legend('left', 'right')
xlabel('Intensity')
ylabel('Luminance')

% Match luminance
[Gli, Ggleft, Gri, diff] = match_luminance(G, signal, left, right, gamma_left, gamma_right);

subplot(3, 3, [1,2]+3)
imshow([Gli, Gri], [0,1])
ylabel('Intensity modified to match luminance')
subplot(3, 3, 3+3)
hold on; 
plot(G(:), Gli(:), '+r')
plot(G(:), Gri(:), '+g')
legend('left', 'right')
xlabel('Intensity')
ylabel('Mod. Intensity')
% 
Gllum = apply_lut(Gli, signal, left);
Grlum = apply_lut(Gri, signal, right);
subplot(3, 3, [1,2]+6)
imshow([Gllum, Grlum], [0,1])
ylabel('Effect of matching.')
subplot(3, 3, 3+6)
hold on; 
plot(G(:), Gllum(:), '+r')
plot(G(:), Grlum(:), '+g')

legend('left', 'right')
xlabel('Intensity')
ylabel('Luminance')

fprintf('Contrast is: %1.2f / %1.2f, Mean lum is: %1.2f / %1.2f\n', mcon(Gllum), mcon(Grlum), mean(Gllum(:)), mean(Grlum(:))); 