
function [fullpath_out, existed]=movieConvolutionPerPixelExt(fullpath_movie,...
    fullpath_filter, varargin)
%% 

    [basepath, filename, ext, basefilename, channel, postfix] = ...
        filenameParts(fullpath_movie);

%%

    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end
%%
    
    if (~isfolder(options.outdir)) mkdir(options.outdir); end
    if (~isfolder(options.diagnosticdir)) mkdir(options.diagnosticdir); end

    filename_out = basefilename+channel+postfix+options.postfix_new;
    fullpath_out = fullfile(options.outdir, filename_out + ext);
    
    if (isfile(fullpath_out))
        if(options.skip)
            disp("MovieConvolutionPerPixel: Output file exists. Skipping: " + fullpath_out)
            existed = true;
            return;
        else
            warning("MovieConvolutionPerPixel: Output file exists. Deleting: " + fullpath_out);
            delete(fullpath_out);
        end     
    end
    existed = false;
    %%

    if (~exist(fileparts(fullpath_out), 'dir')) mkdir(fileparts(fullpath_out)); end
    
    [status,cmdout] = ...
        ConvolutionPerPixelExt(...
            char(fullpath_movie), char(fullpath_filter), char(fullpath_out), ...
            'delete', true, 'num_cores', options.num_cores, ...
            'exepath', char(options.exepath), 'remove_mean', true);
    %%

    specs = rw.h5readMovieSpecs(fullpath_movie);
    specs_out = copy(specs);
    specs_out.AddToHistory(functionCallStruct(...
            {'fullpath_movie', 'fullpath_filter', 'options'}));
    rw.h5saveMovieSpecs(fullpath_out, specs_out);  
    %%

    conv_trans = readmatrix(fullpath_filter);
    m_raw = rw.h5getMeanTrace(fullpath_movie);
    m_filtered = rw.h5getMeanTrace(fullpath_out);
    %%

    offset = ceil(length(conv_trans)*0.5);
    valid_range = [offset, rw.h5getDatasetSize(fullpath_out, '/mov', 3) - offset];
    %%

    if(strcmp(options.shape, 'valid'))
        fullpath_out_temp = ...
            movieTimeCrop(fullpath_out, valid_range, 'postfix_new', "_temp");
        movefile(fullpath_out_temp, fullpath_out);        
    end
    %%

    fig_traces = plt.getFigureByName('movieConvolutionPerPixel: mean traces');
    
    plt.tracesComparison([m_raw, m_raw - m_filtered, m_filtered], ...
        'spacebysd', [0,0,3], 'fps', specs.getFps(), 'fw', 0.2, ...
        'labels', ["original", "difference", "convolved"]);
    sgtitle([filename_out, "mean traces"], 'interpreter', 'none', 'FontSize', 10)

    subplot(2,1,1); hold on;
    xline(valid_range(1)/specs.getFps(), '--'); xline(valid_range(end)/specs.getFps(), '--'); 
    hold off
    drawnow();
    %%
    
    saveas(fig_traces, fullfile(options.diagnosticdir, filename_out + '_traces.fig'))
    saveas(fig_traces, fullfile(options.diagnosticdir, filename_out + '_traces.png'))
    %%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function options =  defaultOptions(basepath)

    options.diagnosticdir = basepath + "\diagnostic\convolutionPerPixelExt\";
    
    options.remove_mean = false;
    options.shape = 'same'; %'same' or 'valid'

    options.num_cores = floor(feature('numcores') - 2);
    options.exepath = 'C:\Users\Vasily\repos\Voltage\TEMPO-processing\analysis\c_codes\compiled\hdf5_movie_convolution.exe';

    options.outdir = basepath;
    options.postfix_new = "_conv";
    options.skip=true;
end

