function [q, results_structure, threshold_guess, threshold_guess_sigma] = load_subject(quest_file)
results_structure = load(quest_file, 'results_struct');
results_structure = results_structure.results_struct;
q = results_structure(end).q;
threshold_guess = QuestQuantile(q, 0.5);
threshold_guess_sigma = 1.* (QuestQuantile(q, 0.95) - QuestQuantile(q, 0.05));
end