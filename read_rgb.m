function rgb = read_rgb()
[status, remainder] = system('colorhug-cmd take-readings');
if status > 0
    error('Can not read RGB values from colorhug')
end
while ~strcmp(remainder, '')
    [token, remainder] = strtok(remainder);
    if strfind(token, 'G:') == 1        
        g = str2double(token(3:end));
    elseif strfind(token, 'R:') == 1
        r = str2num(token(3:end));
    elseif strfind(token, 'B:') == 1
        b = str2num(token(3:end));   
    end
end
rgb = [r, g, b];
end