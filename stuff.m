cnt = 1;
for c = [-2. -1. 1 2]
    subplot(1,4,cnt)
    r = res(res.confidence==c,:);
    idx = r.response==1;
    choice_kernel(r, idx)
    cnt = cnt+1;
    title(sprintf('Conf. = %i', c))
    ylim([0.35, 0.8])
end