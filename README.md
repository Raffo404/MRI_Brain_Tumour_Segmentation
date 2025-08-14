# MRI Brain Tumour Segmentation

MATLAB project for brain tumour segmentation using **Fuzzy C-Means (FCM)** and **Template-based Kernel FCM (TKFCM)** algorithms.

---

## Table of Contents
- [Introduction](#introduction)
- [Dataset](#dataset)
- [Project Structure](#project-structure)
- [Functions](#functions)
- [Methodology](#methodology)
- [Results](#results)

---

## Introduction
This project focuses on segmenting brain tumours from MRI scans using advanced fuzzy clustering algorithms.  
FCM allows soft segmentation by assigning membership probabilities to pixels, while TKFCM incorporates a template-based kernel function to improve cluster accuracy, particularly on heterogeneous tissue regions.  
The project also includes feature extraction using GLCM (Gray Level Co-occurrence Matrix) and post-processing edge detection for visualizing tumour boundaries.

---

## Dataset
MRI slices are taken from multi-modal brain MRI datasets, including the following sequences:  
- **FLAIR**  
- **T1**  
- **T1c**  
- **T2**

---

## Project Structure

### Entry points
- **index.m** → Interactive script to apply FCM and TKFCM on selected images.  
- **index_batched.m** → Batch processing on 50 images per modality, computing metrics such as Accuracy, Dice, and Jaccard coefficient.

### Functions
- **pre_processing.m** → Noise filtering and contrast enhancement  
- **create_moving_window_features.m** → Computes train_features for segmentation algorithms  
- **run_fcm.m** → Executes fuzzy c-means segmentation  
- **run_tkfcm.m** → Executes template-based fuzzy c-means segmentation  
- **features_extraction.m** → Extracts GLCM features from each cluster  
- **normaliza_feature_fields.m** → Normalizes feature values  
- **evaluate_statistic_props.m** → Computes metrics: TP, FP, TN, FN, Precision, Accuracy, F1-Score  
- **identify_tumor.m** → Main segmentation function  
- **edge_detection.m** → Highlights tumour edges and overlays them on the original image  

---

## Methodology
1. **Pre-processing**  
   - Noise removal using Gaussian filters  
   - Contrast enhancement using histogram equalization  

2. **Feature extraction**  
   - Compute texture and intensity features using moving windows  
   - Normalize features to prepare input for clustering  

3. **Segmentation**  
   - **FCM:** Assigns fuzzy memberships to pixels  
   - **TKFCM:** Applies template-based kernel to improve clustering of tumour regions  

4. **Post-processing**  
   - Extract clusters corresponding to tumour regions  
   - Apply **edge_detection.m** to highlight tumour boundaries  
   - Overlay edges on original MRI for visualization  

5. **Evaluation**  
   - Compute standard metrics: Accuracy, Dice coefficient, Jaccard index, Precision, F1-Score  

---

## Results
- Tumour regions are segmented with high accuracy across different MRI modalities.  
- Edge detection provides clear visualization of tumour boundaries.  
- Batch evaluation demonstrates robustness of TKFCM compared to standard FCM in heterogeneous tissue areas.

