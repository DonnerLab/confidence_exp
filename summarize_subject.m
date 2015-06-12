function summarize_subject(res)
figure(1)
subplot(4, 4, [1, 2, 3, 4])
choice_kernel(res, res.response==1)
legend('Chosen', 'Not Chosen')
title('Decision Kernels')
ylim([0.35, 0.8])
xlim([0.5, 10.5])
cnt = 5;
ks ={}
for c = [-2. -1. 1 2]
    subplot(4, 4, cnt)
    cnt = cnt+1;
    r = res(res.confidence==c,:);
    idx = r.response==1;
    [selected, non_selected] = choice_kernel(r, idx);
    ks{c+3} = {selected, non_selected};
    ylim([0.35, 0.8])
    title(sprintf('Conf. = %i', c))
    xlim([0.5, 10.5])
end

figure(2)
sel = ks{2+3}{1} - ks{-2+3}{1};
nsel = ks{2+3}{2} - ks{-2+3}{2};

plot(nanmean(sel,1), 'r')
hold on
plot(nsel, 'b')

figure(1)
avgs = [];
trial = [];
for i = 50:200
    avgs = [avgs; calc_bsc_effect(res(i-49:i,:), [0, 100/3. 200/3, 100])];
    trial = [trial i+25];
end

subplot(4, 4, [1, 2, 3]+8)
plot(trial, avgs)
hold on
plot(trial, mean(avgs,2), 'k')
title('Accuracy as a function of contrast offset')
xlabel('trial')
legend('low', 'mid', 'high', 'mean perf')

subplot(4, 4, 4+8)
avgs = [];
prc = prctile(res.random_offset, [0, 100/3. 200/3, 100]);
cnt = 0.25;
colors = {'r', 'g', 'b'};
cnt2 = 1;
for i = 2:length(prc)
    low = prc(i-1);
    high = prc(i);
    idx = low<=res.random_offset & res.random_offset<high;   
    a = histc(res(idx,:).confidence, [-2.5, -1.5, -0.5, 0.5, 1.5, 2.5]);
    a = a([1,2,4,5]);
    bar([-2.5, -1.5, 1.5, 2.5]+cnt, a, 0.25, colors{cnt2});
    cnt2 = cnt2+1;
    hold all
    cnt = cnt+0.2;
end
subplot(4, 4, [1, 2, 3, 4]+12)
plot(res.contrast)