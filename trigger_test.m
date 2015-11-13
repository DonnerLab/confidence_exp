global GL;
addpath('matlabtrigger')
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
w=1920;
h=1080;
% Animation loop: Run until keypress:
mod = 10;
trigger(100)    
waitframes = 20;
for k=1:100
    
    Screen('FillRect', win, [1, 1, 1], [xc-w/2. yc-h/2, xc+w/2, yc+h/2]);
    vbl = Screen('Flip', win, vbl+ifi*(waitframes-0.1));
    trigger(200)    
    Screen('FillRect', win, [0, 0, 0], [xc-w/2. yc-h/2, xc+w/2, yc+h/2]);
    vbl = Screen('Flip', win, vbl+ifi*0.9);
end
    
    
Screen('CloseAll');

