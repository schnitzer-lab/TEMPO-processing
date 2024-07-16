
function [fullpath_out, existed]=movieConvolutionPerPixel(fullpath_movie,...
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
    
    [M, specs] = rw.h5readMovie(fullpath_movie);
    conv_trans = readmatrix(fullpath_filter);
    
    m_raw = squeeze(mean(M,[1,2], 'omitnan'));

    if(options.remove_mean) M = M - mean(M,3); end
    M = convn(M, reshape(conv_trans, 1,1,[]), 'same');

    m_filtered = squeeze(mean(M,[1,2], 'omitnan'));
    %%
    
    offset = ceil(length(conv_trans)*0.5);
    valid_range = [offset, size(M, 3) - offset];
    %%
    
    specs_out = copy(specs);
    specs_out.AddToHistory(functionCallStruct(...
            {'fullpath_movie', 'fullpath_filter', 'options'}));

    if(strcmp(options.shape, 'valid'))
        M = M(:,:,valid_range(1):valid_range(2));
        specs_out.AddFrameDelay(valid_range(1)-1);
    end

    rw.h5saveMovie(fullpath_out, M, specs_out);    
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

    options.diagnosticdir = basepath + "\diagnostic\convolutionPerPixel\";
    
    options.remove_mean = false;
    options.shape = 'same'; %'same' or 'valid'

    options.outdir = basepath;
    options.postfix_new = "_conv";
    options.skip=true;
end

