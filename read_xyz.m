function rgb = read_xyz()
[status, remainder] = system('colorhug-cmd take-readings-xyz 0');
if status > 0
    error('Can not read RGB values from colorhug')
end
while ~strcmp(remainder, '')
    [token, remainder] = strtok(remainder);
    if strfind(token, 'X:') == 1        
        x = str2double(token(3:end));
    elseif strfind(token, 'Y:') == 1
        y = str2num(token(3:end));
    elseif strfind(token, 'Z:') == 1
        z = str2num(token(3:end));   
    end
end
rgb = [x, y, z];
end