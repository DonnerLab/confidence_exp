function test_contrasts()

global GL;

AssertOpenGL;

screenid = 0;
win = Screen('OpenWindow', screenid, 128, [0, 0, 1900, 500]);
Screen('ColorRange', win, 1);
[tw, th] = Screen('WindowSize', win);

rshader = fullfile(pwd, 'ExpandingRingsShader.vert.txt');


expandingRingShader = LoadGLSLProgramFromFiles({ rshader, fullfile(pwd, 'ExpandingSinesShader.frag.txt') }, 1);
ringwidth = 25;
ringtex = Screen('SetOpenGLTexture', win, [], 0, GL.TEXTURE_RECTANGLE_EXT, tw, th, 1, expandingRingShader);
glUseProgram(expandingRingShader);
glUniform2f(glGetUniformLocation(expandingRingShader, 'RingCenter'), tw/2, th/2);
glUseProgram(0);
firstColor  = [1 1 1 1]; 
secondColor = [0 0 0 1]; 
shiftvalue = 500;
count = 0;
ifi = Screen('GetFlipInterval', win);
vbl = Screen('Flip', win);
ts = vbl;

% Animation loop: Run until keypress:
side = randsample([1,-1], 1)
[side, contrast_fluctuations] = sample_contrast(side, 0.2, 0.01, 0.5);
contrast_fluctuations(1) = 0.5;
mean(contrast_fluctuations)

contrast = contrast_fluctuations;
pos = 50:180:1850
for i=1:10
    [firstColor, secondColor] = contrast_colors(contrast(i), 0.5);
    Screen('BlendFunction', win, 'GL_ONE', 'GL_ZERO');
    Screen('DrawTexture', win, ringtex, [], [], [], [], [], firstColor, [], [],...
        [secondColor(1), secondColor(2), secondColor(3), secondColor(4), shiftvalue, ringwidth, 50, 0, 50, 1, pos(i), 250]);
end
    vbl = Screen('Flip', win, vbl + ifi/2);
    WaitSecs(5);
% Done. Print some fps stats:
avgfps = count / (vbl - ts);
fprintf('Average redraw rate in Hz was: %f\n', avgfps);

% Close window, release all ressources:
Screen('CloseAll');

end