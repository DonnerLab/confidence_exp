function trigger = setup_trigger()
%% TRIGGERS
% Event                 Value	Pins
% Trial start           150
% Trial end             151
% Stimulus onset		64	01100100
% Conrast chage 		50	
% Stimulus offset		49	
% Decision start		48	
% Confidence start		47	
% Feedback onset		46	
%
% Stim. - strong left   41	00110001
% Stim. - strong right  40	00110000
%
%
% Left Confidence  - +2 24	00100001
% Left Confidence  - +1	23	00100000
% Right Confidence - -1 22	00100001
% Right Confidence - -2 21	00100000
%
% Feedback - correct	11	00010001
% Feedback - incorrect	10	00010000

trigger.zero = 0;
trigger.width = 0.005; %1 ms trigger signal

trigger.trial_start = 150;
trigger.trial_end = 151;

trigger.stim_onset = 64; % fixation is 64
trigger.con_change = 50;
trigger.stim_off = 49;
trigger.decision_start = 48;
trigger.confidence_start = 47;
trigger.feedback_start = 46;

trigger.stim_strong_left = 41;
trigger.stim_strong_right = 40;


trigger.left_conf_high = 24;
trigger.left_conf_low = 23;
trigger.right_conf_low = 22;
trigger.right_conf_high = 21;

trigger.feedback_correct    = 11;
trigger.feedback_incorrect  = 10;

trigger.beep = 100;

trigger.no_decisions = 88;
trigger.no_confidence = 77;

end
