
% GET SUBJECT INFO
% ================

% Try to get the subject ID and session ID (to minimize mistakes)
res_files = dir(strcat(PathSave, 'r_', NamePrefix, '_*'));
SubNum    = [];
for i_file = 1:size(res_files,1)
    SubNum(i_file) = str2double(res_files(i_file).name(length(NamePrefix)+12 ...
        :strfind(res_files(i_file).name, '_Sess') -1));
end
if isempty(SubNum)
    LastSub = 0;
else
    LastSub = max(SubNum);
end

files_thisSub = dir(strcat(PathSave, 'r_', NamePrefix, '_SUBJECT_', num2str(LastSub), '*'));
SubSessNum = [];
for i_sess = 1:size(files_thisSub)
    indSess = strfind(files_thisSub(i_sess).name, '_Sess_');
    indNext_ = strfind(files_thisSub(i_sess).name(indSess+6:end), '_');
    SubSessNum(i_sess) = str2double(files_thisSub(i_sess).name(...
        indSess+6 ...
        :indNext_(1)+indSess+4));
end

if LastSub == 0;
    SuggestSub = 1;
    SuggestSess = 1;
else
    if max(SubSessNum) == 4 % Previous subject has all (4) session => increment subject
        SuggestSub = LastSub+1;
        SuggestSess = 1;
    else
        SuggestSub = LastSub;
        SuggestSess = max(SubSessNum)+1;
    end
end

% Ask for input
while true
    clc;
    if IsfMRI == 1
        fprintf('\n fMRI setting enabled')
    else
        fprintf('\n fMRI setting disabled')
    end
    
    subID = input(sprintf([...
        '\n\n \t ENTER THE FOLLOWING DATA ', ...
        '\n\t (and press enter to validate) \n\n', ...
        '   subject ID......... (%d?) '], SuggestSub), 's');
    
    if strcmp(subID, 'test'); 
        sessionID       = '1'; 
        experimenterID  = 'test'; 
        centerID        = 'test'; 
        break; 
    end
    sessionID = input(sprintf('   session ID......... (%d?) ', SuggestSess), 's');
    experimenterID = input(   '   experimenter ID.... ', 's');
    centerID = input(         '   center ID.......... ', 's');
    
    fprintf('\n\n \t CHECK THE DATA YOU SPECIFIED\n')
    fprintf('\n \t      Subject ID: %s', subID)
    fprintf('\n \t      Session ID: %s', sessionID)
    fprintf('\n \t Experimenter ID: %s', experimenterID)
    fprintf('\n \t       Center ID: %s', centerID)
    
    fprintf('\n \t IS IT CORRECT? \n')
    correct = input(' (press the ''y'' or ''n'' key and then the ''enter'' key for yes or no)   ', 's');
    
    if correct=='y'
        info.experimenterID = experimenterID;
        info.centerID       = centerID;
        break
    end
end

% USE QUEST PROCEDURE TO CALIBRATE THE EXPERIMENT DIFFICULTY
% ==========================================================

est_thresh    = initialThd_Quest; %.5
est_thresh_SD =.1; %.1
if strcmp(sessionID, '1')
    Quest_proc = QuestCreate(est_thresh, est_thresh_SD, prob, 3.5, .01, 0.5, .03, .5);
else
    % get previous file name
    filename = strcat('r_', NamePrefix, ...
        '_SUBJECT_', subID, ...
        '_Sess_', num2str(str2double(sessionID)-1), ...
        '*');
    
    flist = dir(strcat(PathSave, filename));
    
    fdate = zeros(length(flist), 1);
    for k = 1:length(flist)
        fdate(k) = flist(k).datenum;
    end
    
    % get the most recent file
    [val, ind] = max(fdate);
        
    % load previous file
    load(strcat(PathSave, '/', flist(ind).name), 'Quest_proc');
    
    % compute the new parameters
    Quest_est = Quest_proc.intensity(end);
    
    %notar que en cada bloque se setea el std del threshold inicial, no
    %el estimado. Es para que no se clave??
    Quest_proc = QuestCreate(Quest_est, est_thresh_SD, prob, 3.5, .01, 0.5, .03, .5);
end
    
