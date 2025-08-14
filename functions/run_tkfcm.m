function [has_tumor, tumor_cluster, tumor_mask, metrics, cluster_labels, U, features_per_cluster] = run_tkfcm(img_input, slice_idx, ground_truth_labels, num_clusters, max_iter, alpha)
    arguments (Input)
        img_input
        slice_idx
        ground_truth_labels
        num_clusters
        max_iter 
        alpha %weighted coefficient for optimized distance evaluation
    end

    arguments (Output)
        has_tumor
        tumor_cluster
        tumor_mask
        metrics
        cluster_labels
        U
        features_per_cluster
    end
    m = 2; % fuzzy coefficient
    window_size = [3 3];
    eps_conv = 1e-5;
    [rows, cols] = size(img_input);
    N = rows*cols;
    
    % 1) Estrai features locali basate su intensità (finestre mobili)
    train_features = create_moving_window_features(img_input, window_size);
    
    % 3) Aggiungi coordinate spaziali normalizzate
    [xg, yg] = ndgrid(1:rows, 1:cols);
    coords = 0.01*[xg(:)/rows, yg(:)/cols]; %riduco l'effetto di delle coordinate spaziali per evitare divisione dello sfondo in clusters diversi
    feature_vec = [train_features, coords];
    
    % 4) Inizializza matrice di membership tramite da K-means
    oopts = statset('MaxIter', 200);
    kmeans_labels = kmeans(feature_vec, num_clusters, 'Replicates', 2, 'Options', oopts);
    alpha_eff = alpha * var(train_features(:,1));
    
    U = zeros(num_clusters, N);
    for k = 1:num_clusters
        assigned = (kmeans_labels == k);
        U(k, assigned) = 0.9; %livello di membership "alto" per i pixel inseriti nel cluster già dal kmeans
        U(k, ~assigned) = 0.1 / (num_clusters-1);
    end
    
    % 5) Iterazioni TKFCM (calcolo centroidi, aggiornamento membership e
    % distanze dai centroidi)
    X = feature_vec';
    for iter = 1:max_iter
        U_old = U;
        Um = U.^m;
        c = (Um * X') ./ (sum(Um,2) + eps);
    
        D = zeros(num_clusters, N);
        for k = 1:num_clusters
            diff = X - c(k,:)';
            D(k,:) = sum(diff.^2, 1);
            if alpha_eff > 0
                xc = c(k, end-1); yc = c(k, end);
                px = X(end-1,:); py = X(end,:);
                D(k,:) = D(k,:) + alpha_eff * ((px - xc).^2 + (py - yc).^2);
            end
        end
    
        power = 2/(m-1);
        D = max(D, 1e-12);
    
        D_exp1 = reshape(D, [num_clusters, 1, N]);
        D_exp2 = reshape(D, [1, num_clusters, N]);
        
        fraction = D_exp1 ./ D_exp2;               
        fraction_p = fraction .^ power;           
        
        denominator = sum(fraction_p, 2);          
        U = reshape(1 ./ denominator, num_clusters, N);
    
        if max(abs(U(:) - U_old(:))) < eps_conv
            break;
        end
    end
    
    % 6) Etichette finali
    [~, cluster_idx_vec] = min(D, [], 1);
    cluster_labels = reshape(cluster_idx_vec, rows, cols);
    cluster_labels = rot90(cluster_labels); % Ruota l'immagine di 90 gradi
    cluster_labels = flipud(cluster_labels); %capovolge verticalmente
    
    % Visualizzazione dei cluster individuati
    r = ceil(sqrt(num_clusters));
    c = ceil(num_clusters / r);

    figure('Name', 'Cluster Masks');
    for i = 1:num_clusters
        mask = reshape(cluster_labels == i, [240, 240]);
        subplot(r, c, i);
        imshow(mask);
         title(['Cluster ', num2str(i)]);
    end
    sgtitle('Cluster Masks');
    
    % 7) Estrazione features per cluster usando funzione features_extraction (sulla slice originale)
    features_per_cluster = features_extraction(img_input, U, num_clusters);
    
    % 8) Identificazione tumore (usando ground truth)
    tumor_classes = [1, 2, 3]; % [tumour, edema, necrosis]
    ground_truth_mask = ismember(double(ground_truth_labels(:,:,slice_idx)), tumor_classes);
    [tumor_cluster, tumor_mask, has_tumor, metrics] = identify_tumor(cluster_labels, features_per_cluster, ground_truth_mask, num_clusters);
    
    tumor_mask = reshape(tumor_mask, [240 240]);
    
    figure('Name','Tumor prediction vs ground truth');
    imshowpair(tumor_mask, ground_truth_mask, 'montage');  % side-by-side
    title('Tumor Prediction (LEFT) vs Ground Truth (RIGHT)');
end
