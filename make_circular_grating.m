function ringtex = make_circular_grating(win, ringwidth)
global GL;
% Make sure this is running on OpenGL Psychtoolbox:
AssertOpenGL;



% Query window size: Need this to define center and radius of expanding
% disk stimulus:
[tw, th] = Screen('WindowSize', win);

% Load the 'ExpandingRingsShader' fragment program from file, compile it,
% return a handle to it:
rshader = fullfile(pwd, 'ExpandingRingsShader.vert.txt');

expandingRingShader = LoadGLSLProgramFromFiles({ rshader, fullfile(pwd, 'ExpandingSinesShader.frag.txt') }, 1);
% Width of a single ring (radius) / Period of a single color sine wave in pixels:


% Create a purely virtual texture 'ringtex' of size tw x th virtual pixels, i.e., the
% full size of the window. Attach the expandingRingShader to it, to define
% its "appearance":
ringtex = Screen('SetOpenGLTexture', win, [], 0, GL.TEXTURE_RECTANGLE_EXT, tw, th, 1, expandingRingShader);

% Bind the shader: After binding it, we can setup some constant parameters
% for our stimulus, so called GLSL 'uniform' variables. These are
% parameters that are constant during the whole session, or at least only
% change infrequently. They are set outside the fast stimulus rendering
% loop and potentially optimized by the graphics driver for fast execution:
glUseProgram(expandingRingShader);

% Set the 'RingCenter' parameter to the center position of the ring
% stimulus [tw/2, th/2]:
glUniform2f(glGetUniformLocation(expandingRingShader, 'RingCenter'), tw/2, th/2);

% Done with setup, disable shader. All other stimulus parameters will be
% set at each Screen('DrawTexture') invocation to allow fast dynamic change
% of the parameters during each stimulus redraw:
glUseProgram(0);


end