function metrics = evaluate_statistic_props(predicted, ground_truth)

    arguments (Input)
        predicted % predicted cluster pixel mask
        ground_truth % ground_truth mask from dataset
    end

    arguments (Output)
        metrics % statistical metrics
    end
    
    predicted = logical(predicted(:));
    ground_truth = logical(ground_truth(:)); 

    if length(predicted) ~= length(ground_truth)
        error('Predicted and ground truth masks must be the same size.');
    end

    % Calcolo delle metriche statistiche 
    TP = sum(predicted & ground_truth);
    FP = sum(predicted & ~ground_truth);
    TN = sum(~predicted & ~ground_truth);
    FN = sum(~predicted & ground_truth);

    Accuracy  = (TP + TN) / (TP + FP + TN + FN + eps);
    Precision = TP / (TP + FP + eps);
    Recall    = TP / (TP + FN + eps);
    F1        = 2 * (Precision * Recall) / (Precision + Recall + eps);

    % Dice coefficient
    Dice = 2 * TP / (2*TP + FP + FN + eps);

    % Jaccard coefficient
    Jaccard = TP / (TP + FP + FN + eps);

    metrics = struct( ...
        'TP', TP, ...
        'FP', FP, ...
        'TN', TN, ...
        'FN', FN, ...
        'Accuracy', Accuracy, ...
        'Precision', Precision, ...
        'Recall', Recall, ...
        'F1Score', F1, ...
        'Dice', Dice, ...
        'Jaccard', Jaccard ...
    );
end
