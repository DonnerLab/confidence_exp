function [G, Idiff, Ldiff] = match_luminance(G, ref_signal, transfer_reference, target_signal, transfer_target)
% Find a mapping that makes signal G as if it were presented with reference
% transfer function on the site with the to_be_adapted transfer function.

if transfer_reference(end) > transfer_target(end)
    error('Left is the stronger signal - can not make left stronger; therefore can not make it equal to right')
end

% What happens to the signals when we present them on the screen? Compute
% luminance from signal
Lref = apply_lut(ref_signal, ref_signal, transfer_reference);
Ladapt = apply_lut(target_signal, target_signal, transfer_target);

% find mapping that equalizes differences. 
Ldiff = nan*ones(length(transfer_reference), 1);
Idiff = nan*ones(length(transfer_reference), 1);
idxs = nan*ones(length(transfer_reference), 1);
for i = 1:length(target_signal)
    % What target val is produced on the right when we present signal intensity 
    target_lum = Lref(i);
    % What value in left leads to target? 
    [~, source] = min(abs(Ladapt-target_lum));  
    idxs(i) = source;
    Ldiff(i) = Ladapt(source);
    Idiff(i) = target_signal(source);
end
% Applying the look up table Idiff to G gives equalized luminances. 
G = apply_lut(G, target_signal, Idiff);
end