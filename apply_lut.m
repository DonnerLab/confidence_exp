function input = apply_lut(input, signal, lut)
% Apply a look up table to values in input. The lookup up table is defined
% by 'signal':'lut'. Each value is mapped to it' where each number in signal ma a value in input
% that is to be replaced by the correspondingly indexed value in lut.

shape = size(input);
input = input(:);
for j = 1:length(input)
    [~, val] = min(abs(signal-input(j)));
    input(j) = lut(val);
    
end
input = reshape(input, shape);