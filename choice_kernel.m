function [selected, non_selected] = choice_kernel(res, index)
offset = res.random_offset;
con_right= res.contrast_right;
con_left= res.contrast_left;

con_right = con_right - repmat(offset, 1, 10);
con_left = con_left - repmat(offset, 1, 10);

con_chosen = [con_left(index,:); con_right(~index,:)];
con_not_chosen = [con_left(~index,:); con_right(index,:)];
errorbar(mean(con_chosen,1), std(con_chosen,1)/(size(con_chosen,1)^0.5), 'r')
hold on
errorbar(mean(con_not_chosen,1), std(con_not_chosen,1)/(size(con_not_chosen,1)^0.5), 'b')
xlabel('Frame #')
ylabel('Contrast')
selected = mean(con_chosen,1);
non_selected = mean(con_not_chosen,1);
end