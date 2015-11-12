global GL;

AssertOpenGL;

screenid = 0;
win = Screen('OpenWindow', screenid, 128, [0, 0, 1920, 1080]);
Screen('ColorRange', win, 1);
[tw, th] = Screen('WindowSize', win);
xc = tw/2;
yc = th/2;
ifi = Screen('GetFlipInterval', win);
vbl = Screen('Flip', win);
ts = vbl;
w=1400;
h=1080;
% Animation loop: Run until keypress:
mod = 10;
while 1    
    
    Screen('FrameRect', win, [.5, 1, 0], [xc-w/2. yc-h/2, xc+w/2, yc+h/2]);
    vbl = Screen('Flip', win);
    key = GetChar();
    if key=='1'
        w = w+mod;
    elseif key=='2'
        w = w-mod;
    elseif key=='3'
        h = h+mod;        
    elseif key=='4'
        h = h-mod;        
    elseif key=='i'
        mod = mod+1;
    elseif key=='d'
        mod = mod-1;        
    elseif key=='q'
        break      
    end
end
    
    
Screen('CloseAll');

