function data = read_rgb_spotread(varargin)
% Read values from multiple color hug devices. 
%
% The varargin might contain key value pairs that specify:
%   'path' : The path to Argyll spotread (does the actual communication
%            with the color hug.)
%   'devices' : a list of device numbers to read from. Call spotread to
%               find out which are available.
%
devices = default_arguments(varargin, 'devices', [1]);
path = default_arguments(varargin, 'path', '/home/meg/Documents/Argyll_V1.7.0/bin');

data = [];
for i = 1:length(devices)
    device = devices(i);
    cmd = fullfile(path, sprintf('spotread -c %i -O -y R', device));
    [status, output] = system(cmd);
    if status > 0
        disp(status)
        disp(output)
        error('Can not read XYZ values from colorhug');
    end
    result = strsplit(output, '\n');
    result = result{end-1};
    result = textscan(result, 'Result is XYZ: %f %f %f, D50 Lab: %f %f %f %*[^\n]');
    x = result{1};
    y = result{2};
    z = result{3};    
    L = result{4};
    a = result{5};
    b = result{6};
    data = [data; x y z L a b];
end

end