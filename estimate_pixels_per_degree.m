function ppd = estimate_pixels_per_degree(options)
o = tan(0.5*pi/180) *options.dist;
ppd = 2 * o*options.resolution(1)/options.width;
end