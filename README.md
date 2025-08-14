# MRI_Brain_Tumour_Segmentation
MATLAB image processing project for brain tumour segmentation with fuzzy C-Means / TKFCM

## Entry points
index.m -> project entry point, interactive script that permit user to apply both fcm and tkfcm on chosen images from dataset.
indext_batched.m -> permit user to execute segmentation on 50 images (slice 50) for each acquisition modalities (FLAIR, T1, T1c, T2) computing metrics such as Accuracy, Dice and Jaccard Coefficient for segmentation evaluation.

## Functions
pre_processing.m -> noise filtering and contrast enhancing 
create_moving_window_features.m -> computes train_features for segmentation algorythms
run_fcm.m -> execute fuzzy c-means segmentation
run_tkfcm.m -> execute template based fuzzy c-means
features_extraction.m -> glcm feature extraction from each cluster
normaliza_feature_fields.m -> feature values normalization
evaluate_statistic_props.m -> compute statistics metrics such as TP, FP, TN, FN, Precision, Accuracy, F1-Score
identify_tumor.m -> segmentation function
edge_detection.m -> highlights tumour edges
