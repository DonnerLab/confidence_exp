function data = load_tables(initials, sessions, datadir)
datadir = fullfile(datadir, initials)
tables = {};
for s = 1:length(sessions)
    fullfile(datadir, sprintf('%s_%d_results.csv', initials, sessions(s)))
    results = readtable(fullfile(datadir, sprintf('%s_%d_results.csv', initials, sessions(s))));    
    contrast_left = [results.contrast_left_1, results.contrast_left_2, results.contrast_left_3, results.contrast_left_4, results.contrast_left_5, results.contrast_left_6, results.contrast_left_7, results.contrast_left_8, results.contrast_left_9, results.contrast_left_10];
    contrast_right = [results.contrast_right_1, results.contrast_right_2, results.contrast_right_3, results.contrast_right_4, results.contrast_right_5, results.contrast_right_6, results.contrast_right_7, results.contrast_right_8, results.contrast_right_9, results.contrast_right_10];
    t = table(contrast_left, contrast_right);
    for k = results.Properties.VariableNames
        if ~(numel(strfind(k{1}, 'contrast_'))==0)  
            results.(k{1}) = [];
        end
    end    
    tables{s} = [results t];    
end
data = vertcat(tables{:});
