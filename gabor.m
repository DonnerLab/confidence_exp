function G = gabor(dim_pix, tilt, phase, freq, contrast, baseline)
res = 1*[dim_pix, dim_pix];
sc = 50.0;
contrast = contrast*100;

tw = res(1);
th = res(2);
x=tw/2;
y=th/2;


sf = freq;

[gab_x, gab_y] = meshgrid(0:(res(1)-1), 0:(res(2)-1));

a=cos(deg2rad(tilt))*sf*360;
b=sin(deg2rad(tilt))*sf*360;

multConst=1/(sqrt(2*pi)*sc);

x_factor=-1*(gab_x-x).^2;
y_factor=-1*(gab_y-y).^2;

sinWave=sin(deg2rad(a*(gab_x - x) + b*(gab_y - y)+phase));

varScale=2*sc^2;

G=0.5 + contrast*(multConst*exp(x_factor/varScale+y_factor/varScale).*sinWave)';
G = (G-mean(G(:)));
G = G-min(G(:));
G = G/max(G(:)) ;
% now in [0-1]
G = (G-0.5);% *contrast/100 + baseline;




end