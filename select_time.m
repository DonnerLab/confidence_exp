function results = select_time(options)
listing = dir(fullfile(options.datadir, 's*.mat'));
if numel(dir) == 0
    fprintf('Could not find previous trials')
    throw(MException('EXP:Quit', 'User request quit'));
end
for i = 1:length(listing)
    parts = strsplit(listing(i).name, '_');
    if strcmp(parts{1}, 'quest')
        listing(i).recording_time = nan;
        listing(i).recording_day = 'nan';
    else
        time = datenum(parts{2});
        listing(i).recording_time = time;
        listing(i).recording_day = datestr(time , 'dd/mm/yyyy');
    end
end
[~, I] = sort([listing.recording_time]);

fprintf('Found data from these days:\n');
days = unique({listing.recording_day});
cnt = 1;
for i = days
    fprintf('[%i] - %s\n', cnt, i{1})
    cnt = cnt + 1;
end

day = input('Which one to choose? ', 's');
day = days{str2num(day)};
fprintf('You choose %s\n', day)

cnt = 1;
fprintf('Available sessions:\n')
for i = 1:length(listing)
    if strcmp(day, listing(i).recording_day)
        fprintf('[%i] - %s\n', cnt, listing(cnt).name)
    end
    cnt = cnt + 1;
end
sess = input('Which session? ', 's');
session = listing(str2num(sess)).name

load(fullfile(options.datadir, session))
results = session_struct.results;
