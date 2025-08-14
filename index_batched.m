%% Batch processing FCM & TKFCM - MRI Brain Tumor Segmentation
close all; clear; clc;

% Dataset path
basePath = 'Task01_BrainTumour';
addpath("functions\");

% Slice fisso
sliceIdx = 50;

% Modalities
modality_names = {'FLAIR','T1','T1c','T2'};

% Output Excel
results_filename = "Batch_Segmentation_Results.xlsx";

% Range immagini
imgStart = 45;
imgEnd   = 95;

% Algoritmi e intestazioni tabella risultati
algorithms   = {'FCM','TKFCM'};
metrics_vars = {'Image','Slice','Cluster','HasTumor','Accuracy','Dice','Jaccard'};

% Creazione tabelle vuote per ogni modalità e algoritmo
for a = 1:numel(algorithms)
    for m = 1:numel(modality_names)
        sheet_name = sprintf('%s_%s', algorithms{a}, modality_names{m});
        results_table.(sheet_name) = table( ...
            'Size', [0 numel(metrics_vars)], ...
            'VariableTypes', repmat("double", 1, numel(metrics_vars)), ...
            'VariableNames', metrics_vars);
    end
end

%% Loop sulle immagini e modalità (slice fisso)
disp("Running batches...")
for img_number = imgStart:imgEnd
    img_filename   = fullfile(basePath, 'imagesTr', sprintf('BRATS_%03d.nii.gz', img_number));
    label_filename = fullfile(basePath, 'labelsTr', sprintf('BRATS_%03d.nii.gz', img_number));

    % Controllo esistenza file
    if ~isfile(img_filename) || ~isfile(label_filename)
        warning('File mancanti per BRATS_%03d: salto.', img_number);
        continue
    end

    % Lettura MRI e ground truth (con gestione errori)
    try
        mriImage = niftiread(img_filename);
        mriLabel = niftiread(label_filename);
    catch ME
        warning('Impossibile leggere BRATS_%03d (%s): salto.', img_number, ME.message);
        continue
    end

    for modality_idx = 1:numel(modality_names)
        % Pre-processing & selezione slice
        try
            selectedSlice = pre_processing(mriImage, sliceIdx, modality_idx);
        catch ME
            warning('pre_processing fallita (img %d, mod %s): %s', ...
                img_number, modality_names{modality_idx}, ME.message);
            continue
        end

        modality_label = modality_names{modality_idx};

        for a = 1:numel(algorithms)
            try
                switch algorithms{a}
                    case 'FCM'
                        [has_tumor, tumor_cluster, tumor_mask, metrics] = ...
                            run_fcm(selectedSlice, sliceIdx, mriLabel, 13, 150, 'euclidean');
                    case 'TKFCM'
                        [has_tumor, tumor_cluster, tumor_mask, metrics] = ...
                            run_tkfcm(selectedSlice, sliceIdx, mriLabel, 13, 150, 0.5);
                end
            catch ME
                warning('%s fallito (img %d, mod %s): %s', ...
                    algorithms{a}, img_number, modality_label, ME.message);
                continue
            end

            % Aggiungi riga ai risultati (convertita in tabella con intestazioni coerenti)
            sheet_name = sprintf('%s_%s', algorithms{a}, modality_label);
            new_row = {img_number, sliceIdx, tumor_cluster, has_tumor, ...
                       metrics.Accuracy, metrics.Dice, metrics.Jaccard};

            new_row_table = cell2table(new_row, 'VariableNames', metrics_vars);
            results_table.(sheet_name) = [results_table.(sheet_name); new_row_table];
        end
    end
end

%% Scrittura in Excel e calcolo medie
% (Cancella il file esistente per evitare accumuli da run precedenti)
if isfile(results_filename)
    delete(results_filename);
end

for a = 1:numel(algorithms)
    for m = 1:numel(modality_names)
        sheet_name = sprintf('%s_%s', algorithms{a}, modality_names{m});
        T = results_table.(sheet_name);

        % Scrivi i risultati
        writetable(T, results_filename, 'Sheet', sheet_name);

        % Calcolo medie (ignora eventuali NaN)
        avg_accuracy = mean(T.Accuracy, 'omitnan');
        avg_dice     = mean(T.Dice, 'omitnan');
        avg_jaccard  = mean(T.Jaccard, 'omitnan');

        % Riga medie con stesse colonne (prime 4 come NaN)
        avg_row = {NaN, NaN, NaN, NaN, avg_accuracy, avg_dice, avg_jaccard};
        avg_row_tbl = cell2table(avg_row, 'VariableNames', metrics_vars);

        % Aggiungi riga medie in append
        writetable(avg_row_tbl, results_filename, 'Sheet', sheet_name, 'WriteMode', 'Append');
    end
end

disp('Batch processing completed. Results saved to Excel.');
