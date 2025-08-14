function train_features = create_moving_window_features(img_slice, window_size)
    arguments (Input)
        img_slice %grayscale slice mri image
        window_size %mobile window size
    end
    
    arguments (Output)
        train_features
    end

    halfWrow = floor(window_size(1)/2);
    halfWcol = floor(window_size(2)/2);
    % added padding to image in order to don't lose information about image
    % borders
    padded = padarray(img_slice, [halfWrow halfWcol], 'symmetric');
    [rows, cols] = size(img_slice);
    numFeatures = window_size(1)*window_size(2);
    train_features = zeros(rows*cols, numFeatures);
    idx = 1;
    for r=1:rows
        for c=1:cols
            win = padded(r:r+2*halfWrow, c:c+2*halfWcol);
            train_features(idx,:) = win(:)';
            idx=idx+1;
        end
    end
end