function ppd = estimate_pixels_per_degree(screenNumber, distance)
[w, h] = Screen('DisplaySize', screenNumber);
w = w/10;
h = h/10;
stats = Screen('Resolution', screenNumber);
o = tan(0.5*pi/180) *distance;
ppd = 2 * o*stats.width/w;
end