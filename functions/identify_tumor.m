function [tumor_cluster, tumor_mask, has_tumor, metrics] = identify_tumor(cluster_labels, features_per_cluster, ground_truth_mask, num_clusters)
    arguments (Input)
        cluster_labels %pixels for each cluster
        features_per_cluster % Struct con campi Entropy, Contrast, Correlation, etc.
        ground_truth_mask
        num_clusters    % num clusters (fixed)
    end

    arguments (Output)
        tumor_cluster
        tumor_mask
        has_tumor % Determine if a tumor was identified
        metrics
    end

    normalizedFeatures = normalize_feature_fields(features_per_cluster, { ...
        'Contrast', ...
        'Dissimilarity', ...
        'Entropy', ...
        'Homogeneity', ...
        'Correlation', ...
        'Energy' ...
    });

    % Pesi per features GLCM - scelti in maniera euristica (no model
    % training)
    w_entropy     = 0.1;
    w_contrast    = 0.1;
    w_correlation = 0.3;
    w_dissimilarity= 0.1;
    w_homogeneity = 0.4;

    best_score = -Inf;
    tumor_cluster = 0;

    for i=1:num_clusters
        score = w_entropy*(1- normalizedFeatures(i).Entropy) + ...
        w_contrast*normalizedFeatures(i).Contrast + ...
        w_correlation*normalizedFeatures(i).Correlation + ...
        w_dissimilarity*normalizedFeatures(i).Dissimilarity + ...
        w_homogeneity*normalizedFeatures(i).Homogeneity;

        if score > best_score
            best_score = score;
            tumor_cluster = i;
        end
    end

    tumor_mask = cluster_labels == tumor_cluster;
    has_tumor = any(tumor_mask(:));

    if (tumor_cluster ~= 0)
        metrics = struct( ...
        'Entropy',     normalizedFeatures(tumor_cluster).Entropy, ...
        'Contrast',    normalizedFeatures(tumor_cluster).Contrast, ...
        'Correlation', normalizedFeatures(tumor_cluster).Correlation, ...
        'Energy',      normalizedFeatures(tumor_cluster).Energy, ...
        'Homogeneity', normalizedFeatures(tumor_cluster).Homogeneity, ...
        'Dissimilarity', normalizedFeatures(tumor_cluster).Dissimilarity, ...
        'Score',       best_score ...
        );
        predicted = tumor_mask(:);
        stats_metrics = evaluate_statistic_props(predicted, ground_truth_mask);
        stats_fields = fieldnames(stats_metrics);
        for k=1:numel(stats_fields)
            metrics.(stats_fields{k}) = stats_metrics.(stats_fields{k});
        end
    else 
        metrics = struct([]);
    end
end
