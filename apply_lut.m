function input = apply_lut(input, signal, lut, ~)
% Apply a look up table to values in input. The lookup up table is defined
% by 'signal':'lut', where each number in symbol describes a value in input
% that is to be replace by the correspondingly indexed value in lut.


shape = size(input);
input = input(:);
for j = 1:length(input)
    [~, val] = min(abs(signal-input(j)));   
    if nargin == 3
        input(j) = lut(val);
    else
        input(j) = input(j) + lut(val);
    end
end
input = reshape(input, shape);