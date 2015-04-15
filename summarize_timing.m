function summarize_timing(timing)

if iscell(timing)
    timing = [timing{:}];
    % compute animation onset
    animation_onset = [];
    for s = 1:length(timing)
        animation_onset = [animation_onset, timing(s).animation(1)];
    end
    fprintf('Trial start - Animation start: %1.4f \n', mean(animation_onset) - mean([timing(:).TrialOnset]))
    fprintf('Animation start - End: %1.4f \n', mean([timing(:).animation_offset]) - mean(animation_onset))
    fprintf('Animation End - Response Cue: %1.4f \n', mean([timing(:).response_cue]) - mean([timing(:).animation_offset]))
    fprintf('Conf. delay start - End: %1.4f \n', mean([timing(:).confidence_cue]) - mean([timing(:).start_confidence_delay]))
    fprintf('Feedback delay start - End: %1.4f \n', mean([timing(:).feedback_start]) - mean([timing(:).feedback_delay_start]))
    fprintf('Feedback Onset - Trial End: %1.4f \n', mean([timing(:).trial_end]) - mean([timing(:).feedback_start]))
else
    fprintf('Trial start - Animation start: %1.4f \n', timing.animation(1) - timing.TrialOnset)
    fprintf('Animation start - End: %1.4f \n', timing.animation_offset-timing.animation(1))
    fprintf('Animation End - Response Cue: %1.4f \n', timing.response_cue - timing.animation_offset)
    fprintf('Conf. delay start - End: %1.4f \n', timing.confidence_cue - timing.start_confidence_delay)
    fprintf('Feedback delay start - End: %1.4f \n', timing.feedback_start - timing.feedback_delay_start)
    fprintf('Feedback Onset - Trial End: %1.4f \n', timing.trial_end - timing.feedback_start)
    
end

end