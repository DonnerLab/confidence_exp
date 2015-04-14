function gabortex = make_gabor(window, varargin)
gabor_dim_pix = default_arguments(varargin, 'gabor_dim_pix', 155); % Size of Gabor
bgcolor = default_arguments(varargin, 'bgcolor', [0.5, 0.5, 0.5, 0]); % Background color
% Build a procedural gabor texture
gabortex = CreateProceduralGabor(window, gabor_dim_pix, gabor_dim_pix,...
    [], bgcolor, 1, 0.5);
end
