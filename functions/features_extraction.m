function features_per_cluster = features_extraction(image, U, num_clusters)

    arguments (Input)
        image
        U
        num_clusters
    end

    arguments (Output)
        features_per_cluster
    end

    % glcm parameters
    m_threshold = 0.15;                     % fuzzy membership treshold
    glcm_offsets = [0 1; -1 1; -1 0; -1 -1]; % glcm directions
    num_levels = 8;                          % glcm quantization levels

    % features struct initialization
    features_per_cluster(1:num_clusters) = struct( ...
        'Energy', NaN, ...
        'Contrast', NaN, ...
        'Dissimilarity', NaN, ...
        'Entropy', NaN, ...
        'Homogeneity', NaN, ...
        'Correlation', NaN ...
    );

    for c = 1:num_clusters
        cluster_mask = reshape(U(c,:) > m_threshold, size(image));

        if nnz(cluster_mask) < 10
            continue;
        end

        glcm = graycomatrix(mat2gray(cluster_mask), ...
            'Offset', glcm_offsets, ...
            'Symmetric', true, ...
            'NumLevels', num_levels);

        if all(glcm(:) == 0)
            continue;
        end

        stats = graycoprops(glcm, {'Contrast', 'Homogeneity', 'Correlation'});
        [i, j] = meshgrid(1:num_levels, 1:num_levels);
        dissimilarity = sum(sum(abs(i - j) .* double(glcm)));
        glcm_norm = double(glcm) / sum(glcm(:));
        entropy_val = -sum(glcm_norm(glcm_norm > 0) .* log(glcm_norm(glcm_norm > 0)));
        energy = sum(glcm_norm(:).^2);

        features_per_cluster(c).Energy = energy;
        features_per_cluster(c).Contrast = mean(stats.Contrast);
        features_per_cluster(c).Dissimilarity = mean(dissimilarity);
        features_per_cluster(c).Entropy = entropy_val;
        features_per_cluster(c).Homogeneity = mean(stats.Homogeneity);
        features_per_cluster(c).Correlation = mean(stats.Correlation);
    end
end

