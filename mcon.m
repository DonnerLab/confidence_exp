function con = mcon(I)

lmx = max(I(:));
lmin = min(I(:));
con = (lmx-lmin)/(lmx+lmin);