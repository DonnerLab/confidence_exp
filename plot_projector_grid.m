plotpos=[7 8 9 4 5 6 1 2 3];
figure
for k = 1:9
    S1=subplot(3,3,plotpos(k));
    hold on
    for i=1:9;
         plot(cl,squeeze(mean(data(:,:,i),2)),'Color',[0.7 0.7 0.7],'LineWidth',0.5)
    end
    plot(cl,squeeze(mean(data(:,:,k),2)),'r','LineWidth',1.25)
    ylim([0 200]), xlim([0 255])
    set(S1,'XTickLabel',{}),set(S1,'YTickLabel',{})
    if plotpos(k)==1 || plotpos(k)==4 || plotpos(k)==7
        set(S1,'YTick',[0 200],'YTickLabel',{'0' '200'})
    end
    if plotpos(k)==7 || plotpos(k)==8 || plotpos(k)==9
        set(S1,'XTick',[0 255],'XTickLabel',{'Black' 'White'})
    end
    if plotpos(k)==8
        xlabel('RGB value')
    elseif plotpos(k)==4
        ylabel('Luminance')
    end
    hold off
end