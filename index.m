close all;
clear;
clc;
% Dataset path
basePath = 'Task01_BrainTumour';
addpath("functions\");

% Scelta dell'immagine dal dataset di medicaldecathlon
answerNumber = inputdlg('Insert image number (from 001 to 484):', 'MRI Selection', [1 35], {'001'});

if isempty(answerNumber)
    error("No images selected. Aborting script exec...")
end

% Lettura dell'immagine e della "ground truth" per validare la
% segmentazione
img_number = str2double(answerNumber{1});
img_filename = fullfile(basePath, 'imagesTr', sprintf('BRATS_%03d.nii.gz', img_number));
label_filename = fullfile(basePath, 'labelsTr', sprintf('BRATS_%03d.nii.gz', img_number));

try 
    mriImage = niftiread(img_filename); % immagine MRI 4D (size 2D x slice x modalità di acquisizione)
    mriLabel = niftiread(label_filename); %ground truth del cluster tumorale
catch 
    error("Failed to read the selected MRI image or label. Please check the file paths.");
end

% selezione dello slice dall'immagine 4D
maxSlice = size(mriImage, 3);
prompt = sprintf('Insert image slice number (da 1 a %d):', maxSlice);
definput = {num2str(round(maxSlice/2))};
answerSlice = inputdlg('Insert number of slice you want to process', 'MRI slice selection', [1 36], {'001'});
sliceIdx = str2double(answerSlice{1});

% modalità di acquisizione 
modality_names = {'FLAIR','T1','T1c','T2',};

figure('Name', 'Modality Options');
for i = 1:4
    subplot(2, 2, i);
    img_modality = pre_processing(mriImage, sliceIdx, i);
    imshow(img_modality, []);
    title(modality_names{i});
end
sgtitle('Available Modalities (Slice Preview)');


% Selezione della modalità
[indx, tf] = listdlg('PromptString', 'Choose processing modality:', ...
                     'SelectionMode', 'single', ...
                     'ListString', modality_names);
if ~tf
    disp('Selection Aborted...');
    return;
end

% Estrazione e pre-processing dell'immagine con flitro a media mobile 
modality_idx = indx;
selectedSlice = pre_processing(mriImage, sliceIdx, modality_idx);
modality_label = modality_names{modality_idx};

figure('Name', 'Selected modality');
imshow(selectedSlice, []);
title(sprintf("Selected Slice %d (Modality: %s)", sliceIdx, modality_label));

% Scelta dell'algoritmo da eseguire (Fuzzy C-Means o Template Fuzzy
% C-Means)
algorithms = {'FCM', 'TKFCM'};
[idxAlg, algOk] = listdlg('PromptString', 'Choose segmentation algorithm:', ...
                         'SelectionMode', 'single', ...
                         'ListString', algorithms);

if ~algOk
    disp('Algorithm selection aborted.');
    return;
end


switch idxAlg
    case 1 % FCM
        disp('Running FCM algorithm...');
        results_filename = "Results_FCM.xlsx";
        tic;
        [has_tumor, tumor_cluster, tumor_mask, metrics] = run_fcm(selectedSlice, sliceIdx, mriLabel, 13, 150, 'euclidean');
        fcm_time = toc;

        fprintf("FCM execution time: %.4f secondi\n", fcm_time);
    case 2 % TKFCM
        disp('Running TKFCM algorithm...');
        results_filename = "Results_TKFCM.xlsx";
        tic;
        [has_tumor, tumor_cluster, tumor_mask, metrics] = run_tkfcm(selectedSlice, sliceIdx, mriLabel, 13, 150, 0.5);
        tkfcm_time=toc;

        fprintf("TKFCM Execution Time: %.4f secondi\n", tkfcm_time);
end

% salvataggio dei risultati della segmentazione all'interno di un excel
% presente nella root del progetto
if isfile(results_filename)
    try
        results_glcm_table = readtable(results_filename, "Sheet", "GLCM features");
        results_statistical_table = readtable(results_filename, "Sheet", "Statistical features");
    catch
        results_glcm_table = table();
        results_statistical_table = table();
    end
else
    % if file does not exist, create empty tables
    results_glcm_table = table( ...
        'Size', [0 11], ...
        'VariableTypes', {'double', 'double', 'string', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double'}, ...
        'VariableNames', {'ImageNumber', 'ImageSlice', 'Modality', 'Cluster', 'HasTumor', 'Energy', 'Contrast', 'Dissimilarity', 'Entropy', 'Homogeneity', 'Correlation'});

    results_statistical_table = table( ...
        'Size', [0 15], ...
        'VariableTypes', {'double', 'double', 'string', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double'}, ...
        'VariableNames', {'ImageNumber', 'ImageSlice', 'Modality', 'Cluster', 'HasTumor', 'TP', 'FP', 'TN', 'FN', 'Accuracy', 'Precision', 'Recall', 'F1Score', 'Dice Coefficient', 'Jaccard Coefficient'});
end

if (numel(metrics) ~= 0)
glcm_row = { ...
    img_number, ...
    sliceIdx, ...
    modality_label, ...
    tumor_cluster, ...
    has_tumor, ...
    metrics.Energy, ...
    metrics.Contrast, ...
    metrics.Dissimilarity, ...
    metrics.Entropy, ...
    metrics.Homogeneity, ...
    metrics.Correlation ...
    };

stat_row = { ...
    img_number, ...
    sliceIdx, ...
    modality_label, ...
    tumor_cluster, ...
    has_tumor, ...
    metrics.TP, ...
    metrics.FP, ...
    metrics.TN, ...
    metrics.FN, ...
    metrics.Accuracy, ...
    metrics.Precision, ...
    metrics.Recall, ...
    metrics.F1Score, ...
    metrics.Dice, ...
    metrics.Jaccard ...
    };
    
    results_glcm_table = [results_glcm_table; glcm_row];
    results_statistical_table = [results_statistical_table; stat_row];
    
    writetable(results_glcm_table, results_filename, 'Sheet', 'GLCM features');
    writetable(results_statistical_table, results_filename, 'Sheet', 'Statistical features');
end

% stampa dei risultati solo in caso positivo e visualizzazione della
% regione tumorale
if(has_tumor) 
    fprintf("Tumour has been highlighted in cluster nr. %d\n", tumor_cluster);
    disp(" ");
    disp("------- Tumoural cluster GLCM Features -------");
    fprintf("Energy:         %.4f\n", metrics.Energy);
    fprintf("Contrast:       %.4f\n", metrics.Contrast);
    fprintf("Dissimilarity:  %.4f\n", metrics.Dissimilarity);
    fprintf("Entropy:        %.4f\n", metrics.Entropy);
    fprintf("Homogeneity:    %.4f\n", metrics.Homogeneity);
    fprintf("Correlation:    %.4f\n", metrics.Correlation);
    fprintf("Score:          %.4f\n", metrics.Score);
    
    disp(" ");
    disp("------- Segmentation Statistics Metrics -------");
    fprintf("TP:             %d\n", metrics.TP);
    fprintf("FP:             %d\n", metrics.FP);
    fprintf("TN:             %d\n", metrics.TN);
    fprintf("FN:             %d\n", metrics.FN);
    fprintf("Accuracy:       %.4f\n", metrics.Accuracy);
    fprintf("Precision:      %.4f\n", metrics.Precision);
    fprintf("Recall:         %.4f\n", metrics.Recall);
    fprintf("F1 Score:       %.4f\n", metrics.F1Score);
    fprintf("Dice Coefficient: %.4f\n", metrics.Dice);
    fprintf("Dice Jaccard: %.4f\n", metrics.Jaccard);

    edge_detection(tumor_mask, selectedSlice);
else 
    fprintf("No possible tumour region has been highlighted!");
end