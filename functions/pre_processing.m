function img_processed = pre_processing(img_input, slice, modality)
    arguments (Input)
        img_input   %4D MRI image
        slice   %one of 155 slices
        modality    %chosen modality
    end
    
    arguments (Output)
        img_processed   %filtered grayscaled 2D image [240,240]
    end

    img_extracted = img_input(:,:,slice,modality);
    img_filtered = mat2gray(medfilt2(img_extracted, [3 3])); %filtro a media mobile con kernel 3x3
    img_processed =  histeq(img_filtered);
end




