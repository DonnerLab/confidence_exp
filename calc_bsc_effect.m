function avgs = calc_bsc_effect(res, prc)
avgs = [];
prc = prctile(res.random_offset, prc);
for i = 2:length(prc)
    low = prc(i-1);
    high = prc(i);
    idx = low<=res.random_offset & res.random_offset<high;   
    avgs = [avgs nanmean(res.correct(idx))];
end