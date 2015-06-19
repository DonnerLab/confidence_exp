function data = read_rgb_spotread(varargin)
devices = default_arguments(varargin, 'devices', [1]);
path = default_arguments(varargin, 'path', '/home/meg/Documents/Argyll_V1.7.0/bin');

data = [];
for i = 1:length(devices)
    device = devices(i);
    cmd = fullfile(path, sprintf('spotread -c %i -O', device));
    [status, output] = system(cmd);
    if status > 0
        error('Can not read RGB values from colorhug');
    end
    result = strsplit(output, '\n');
    result = result{end-1};
    result = textscan(result, 'Result is XYZ: %f %f %f %*[^\n]');
    x = result{1};
    y = result{2};
    z = result{3};    
    data = [data; x y z];
end

end