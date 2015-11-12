global GL;

AssertOpenGL;

screenid = 0;
win = Screen('OpenWindow', screenid, 128, [0, 0, 900, 500]);
Screen('ColorRange', win, 1);
[tw, th] = Screen('WindowSize', win);
xc = tw/2;
yc = th/2;
ifi = Screen('GetFlipInterval', win);
vbl = Screen('Flip', win);
ts = vbl;
h=800;
w=900;
% Animation loop: Run until keypress:
while 1    
    Screen('BlendFunction', win, 'GL_ONE', 'GL_ZERO');    
    Screen('DrawT', win, [xc-w/2. yc-h/2, xc+w/2, yc+h/2]);
    vbl = Screen('Flip', win);
    key = GetChar();
end
    
    
Screen('CloseAll');

end