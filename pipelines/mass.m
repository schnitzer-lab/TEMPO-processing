
diary(fullfile(logs_path, ...
        strcat(string(datetime('now','Format','yyyyMMddHHmmss')),'_',mfilename(),'.log')));
%%

MEs = {}; recording_ids_error = []; recording_ids_skipped = [];
for i_f = 1:length(recording_names)
    %%

    recording_name = recording_names(i_f);
    displog(string(i_f)+"/"+string(length(recording_names))+": "+recording_name);
    try
        pipeline_handle()
    catch ME
        MEs{length(MEs)+1} = {recording_name, ME};
        if(~contains(ME.message, "Final file exists, ending"))
            warning("Failed " + recording_name + ": "+ ME.message);
            recording_ids_error = [recording_ids_error, i_f];            
        else
            displog("Skipped " + recording_name+": "+ ME.message)
            recording_ids_skipped = [recording_ids_skipped, i_f];
        end
    end   
end
%%

diary off
