function [Gleft, Ggleft, Ggright, diff, max_luminance] = match_luminance(G, signal, left, right, gamma_left, gamma_right)
%% Goal: To set up Gleft and Grifght such that when they are presented on the projector look the same

% Apply gamma correction to G
Ggleft = apply_lut(G, signal, gamma_left);
Ggright = apply_lut(G, signal, gamma_right);

% What shift do we need to apply to correct for the differences between the
% two gamma corrected gratings?
left_gamma_signal = apply_lut(signal, signal, gamma_left);
right_gamma_signal = apply_lut(signal, signal, gamma_right);

% What happens to the signals when we present them on the screen.
luml = apply_lut(left_gamma_signal, signal, left);
lumr = apply_lut(right_gamma_signal, signal, right);

% find mapping that equalizes differences.
diff = [];
for i = 1:length(signal)
    s = signal(i);
    % What target val is produced on the right when we present signal intensity 
    target = lumr(i);
    % What value in left leads to target?
    
    [~, source] = min(abs(luml-target));     
    diff = [diff left_gamma_signal(source)];
end
Gleft = apply_lut(Ggleft, left_gamma_signal, diff);

end