function [has_tumor, tumor_cluster, tumor_mask, metrics] = run_fcm(data, slice_idx, ground_truth_labels, num_clusters, max_iterations, distance_metric)
    arguments (Input)
        data    %input image
        slice_idx %index of chosen image slice
        ground_truth_labels %ground truth obtained from labelsTr dataset
        num_clusters    %nr. clusters
        max_iterations %max number of iterations
        distance_metric %distance metric (euclidean or mahalanobis)
    end
    
    arguments (Output)
        has_tumor %presenza del tumore (true / false)
        tumor_cluster %cluster tumorale
        tumor_mask %maschera tumorale
        metrics %metriche di segmentazione
    end

    % dimensione della finestra mobile per estrarre le train_features da
    % dare in pasto all'algoritmo
    window_size = [3 3];

    train_features = create_moving_window_features(data, window_size);
    % Esecuzione dell'algoritmo FCM con fuzzy coefficient (2.0)
    [centroids, U] = fcm(train_features, num_clusters, [2.0, max_iterations, 1e-5, 0]);

    %calcolo della distanza tra pixels e centroidi -> distances sarà una
    %matrice num_pixels x num_clusters quindi ogni riga sarà la distanza di
    %quel pixel da ogni centroide 
    if strcmp(distance_metric, 'euclidean')
        distances = pdist2(train_features, centroids, 'euclidean');
    elseif strcmp(distance_metric, 'mahalanobis')
        distances = pdist2(train_features, centroids, 'mahalanobis');
    else
        error('Invalid distance metric specified.');
    end

    %calcolo delle labels per cluster (cioè l'appartenenza per ogni pixel a
    %quale cluster)
    [~, cluster_labels] = min(distances, [], 2);
    cluster_labels = reshape(cluster_labels, size(data)); % Rimodella le etichette dei cluster
    cluster_labels = rot90(cluster_labels); % Ruota l'immagine di 90 gradi
    cluster_labels = flipud(cluster_labels);

    % Visualizzazione delle cluster masks
    rows = ceil(sqrt(num_clusters));
    cols = ceil(num_clusters / rows);

    figure('Name', 'Cluster Masks');
    for i = 1:num_clusters
        mask = reshape(cluster_labels == i, [240, 240]);
        subplot(rows, cols, i);
        imshow(mask);
        title(['Cluster ', num2str(i)]);
    end
    sgtitle('Cluster Masks');

    % estrazione delle features GLCM per ogni cluster
    features_x_cluster = features_extraction(data, U, num_clusters);

    tumor_classes = [1, 2, 3]; % [tumore, edema, necrosi]
    ground_truth_mask = ismember(double(ground_truth_labels(:,:,slice_idx)), tumor_classes);

    % identificazione della regione tumorale
    [tumor_cluster, tumor_mask, has_tumor, metrics] = identify_tumor(cluster_labels, features_x_cluster, ground_truth_mask, num_clusters);
    
    % reshape in base alla dimensione delle immagini del dataset
    tumor_mask = reshape(tumor_mask, [240 240]);

    % stampa side-by-side della tumor mask individuata dalla segmentazione
    % e la ground truth mask
    figure('Name', 'Tumor prediction vs Ground Truth');
    imshowpair(tumor_mask, ground_truth_mask, 'montage');
    title('Tumor Prediction (LEFT) vs Ground Truth (RIGHT)');

end
