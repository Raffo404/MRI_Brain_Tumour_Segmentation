function normalizedFeatures = normalize_feature_fields(featuresStruct, fieldNames)
    arguments (Input)
        featuresStruct %glcm features raw struct
        fieldNames %struct fieldnames
    end

    arguments (Output)
        normalizedFeatures %normalize glcm features (z-score normalization)
    end

    normalizedFeatures = featuresStruct;
    
    %normalizzazione nell'intervallo [-1,1] delle features calcolate
    for i = 1:numel(fieldNames)
        field = fieldNames{i};
        values = [featuresStruct.(field)];
        normValues = (values - mean(values)) / std(values);
        for j = 1:numel(featuresStruct)
            normalizedFeatures(j).(field) = normValues(j);
        end
    end
end