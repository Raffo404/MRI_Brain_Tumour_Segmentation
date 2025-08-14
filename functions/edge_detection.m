function edge_detection(tumor_mask, preprocessed_image)
    arguments (Input)
        tumor_mask
        preprocessed_image
    end

    edgeImage = edge(tumor_mask,'Canny',[0.1, 0.8]);
    
    figure('Name', 'Tumoral mask');
    imshow(edgeImage, []), title('Tumoral region highlighted');
    
    overlay = imoverlay(preprocessed_image, edgeImage, [1, 0, 0]);
    figure('Name', 'Tumor cluster highlighted on original image');
    imshow(overlay);
    title('Overlay between original image and tumoral cluster');
end