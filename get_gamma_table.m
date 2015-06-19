function [signal, luminance, gamma] = get_gamma_table(levels, values, resolution, max_val)
if nargin == 3
    max_val = max(values);
end
maxLevel = max(levels);
resolution = linspace(0, maxLevel, resolution);
g = fittype('x^g');

fittedmodel = fit((levels/max(levels))', (values/max(values))',g);
displayGamma = fittedmodel.g;
gamma = max(values)*(((resolution'/maxLevel))).^(1/fittedmodel.g) / max_val; %#ok<NBRAK>

luminance = max(values)*fittedmodel(resolution/maxLevel) / max_val; %#ok<NBRAK>
signal = resolution;