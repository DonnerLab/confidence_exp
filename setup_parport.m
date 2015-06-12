% install and/or initialize the kernel-level I/O driver
config_io;
% optional step: verify that the driver was successfully installed/initialized
global cogent;
if( cogent.io.status ~= 0 )
    error('inp/outp installation failed');
end

% DO NOT USE DUAL MONITOR SETUP ON WINDOWS 7 !!!!!!!
vswitch(00); % switches to single monitor, will have the taskbar but more accurate timing

