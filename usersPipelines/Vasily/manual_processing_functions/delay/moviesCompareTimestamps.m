function moviesCompareTimestamps(basepath, varargin)
    

    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end
    %%
    
    if (~isfolder(options.processingdir)) mkdir(options.processingdir); end
    %%
   
    timestamps_filestruct1 = dir(fullfile(basepath, "LVMeta", "*cG.dcimg.txt"));
    timestamps_filestruct2 = dir(fullfile(basepath, "LVMeta", "*cR.dcimg.txt"));
    
    timestamps_filename1 = fullfile(timestamps_filestruct1.folder, timestamps_filestruct1.name);
    timestamps_filename2 = fullfile(timestamps_filestruct2.folder, timestamps_filestruct2.name);
    %%

%     filename_out = fullfile(options.processingdir, timestamps_filestruct1.name + "_between.fig");
%     if(isfile(filename_out))
%         if(options.skip)
%             disp("moviesCompareTimestamps: Output file exists. Skipping: "  + filename_out)
%             return;
%         else
%             warning("moviesCompareTimestamps: Output file exists. Overwriting: " + filename_out);
%         end    
%     end
    %%

    timestamps1 = readmatrix(timestamps_filename1, 'Delimiter', '\t');
    timestamps2 = readmatrix(timestamps_filename2, 'Delimiter', '\t');
        
    if(options.droplast) 
        timestamps1 = timestamps1(1:(end-1));
        timestamps2 = timestamps2(1:(end-1));
    end
    
    if(length(timestamps1) ~= length(timestamps2))
        warning("moviesCompareTimestamps: different number of timestamps in two channels");
        nstamps = min(length(timestamps1),length(timestamps2));
        timestamps1 = timestamps1(1:nstamps);
        timestamps2 = timestamps1(1:nstamps);
    end
    
    %%
    fig1 = plt.getFigureByName("moviesCompareTimestamps: Channels timestamps");

    subplot(2,2,1)
    histogram(diff(timestamps1)*options.mult);
    xlabel("sequential timestamps difference, " + options.units);
    title(timestamps_filestruct1.name, 'Interpreter', 'none', 'FontSize', 5)

    subplot(2,2,2)
    histogram(diff(timestamps2)*options.mult);
    xlabel("sequential timestamps difference, " + options.units);
    title(timestamps_filestruct2.name, 'Interpreter', 'none', 'FontSize', 5)

    subplot(2,2,3)
    plot(diff(timestamps1)*options.mult, '.-');
    xlim([1, length(timestamps1)]);
    xlabel("frame #")
    ylabel("difference, " + options.units);

    subplot(2,2,4)
    plot(diff(timestamps2)*options.mult, '.-');
    xlim([1, length(timestamps1)]);
    xlabel("frame #")
    ylabel("difference, " + options.units);
    %%
    diff_channels = timestamps1 - timestamps2;

    fig2 = plt.getFigureByName("moviesCompareTimestamps: Difference between channels");
    
    subplot(1,2,1)
    histogram(diff_channels*options.mult); set(gca,'YScale','log');
    xlabel("difference between channels, " + options.units);

    subplot(1,2,2)
    plot(diff_channels*options.mult);

    xlabel("frame #");
    ylabel("difference between channels, " + options.units);

    sgtitle({timestamps_filestruct1.name, timestamps_filestruct2.name}, 'Interpreter', 'none', 'FontSize', 12)
    %%
   
    saveas(fig1, fullfile(options.processingdir, timestamps_filestruct1.name + "_diffs.png"))
    saveas(fig1, fullfile(options.processingdir, timestamps_filestruct1.name + "_diffs.fig"))
    saveas(fig2, fullfile(options.processingdir, timestamps_filestruct1.name + "_between.png"))
    saveas(fig2, fullfile(options.processingdir, timestamps_filestruct1.name + "_between.fig"))
    %%

    dt_median = median(diff(timestamps1));
    if(any(abs(diff_channels) >  dt_median*options.tol))
        error("Timestamp difference between channels")
    end
    
    if(any(abs(diff(timestamps1)-dt_median) >  dt_median*options.tol))
        error("Timestamp difference for channel 1")
    end
    
    if(any(abs(diff(timestamps2)-dt_median) >  dt_median*options.tol))
        error("Timestamp difference for channel 2")
    end

end
%%

function options = defaultOptions(basepath)
    
    options.processingdir = basepath + "\processing\compareTimestamps\";
%     options.skip = true;
    
    options.droplast = true;
    
    options.mult = 1e3;
    options.units = "ms";
    
    options.tol = 10e-2; % relative difference between timestamps above that will case an error
end
%%