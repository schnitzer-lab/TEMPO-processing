function exists = h5checkDatasetExists(filepath, datasetname)
    %Apparently, the right way to do that, at least that what matlab h5
    %files seem to be doing
    try
        info = h5info(filepath, datasetname);
    catch ME
        if strcmp(ME.identifier, 'MATLAB:imagesci:h5info:unableToFind')
            exists = false;
            return;
        else
            rethrow(ME);
        end
    end
    exists = true;
end
