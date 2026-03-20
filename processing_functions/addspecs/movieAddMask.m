function  movieAddMask(fullpath_movie, fullpath_mask, varargin)
    
    [basepath, basefilename, ext, postfix] = filenameSplit(fullpath_movie, '_');

    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end
    
    %%
    
    if (~isfolder(options.diagnosticdir)) mkdir(options.diagnosticdir); end
    %%
    
    displog("movieAddMask: reading movie and mask")

    mask_image = imread(fullpath_mask);
    if(size(mask_image, 3) > 1) mask_image = rgb2gray(imread(fullpath_mask)); end
    mask = logical((mask_image));
    %%

    specs = rw.h5readMovieSpecs(fullpath_movie);
    specs_out = copy(specs);
    specs_out.extra_specs("mask") = repelem(mask, specs_out.binning, specs_out.binning);
     
    rw.h5writeStruct(char(fullpath_movie), specs_out.extra_specs("mask"), '/specs/extra_specs/mask');
    %%

    if(options.plot)
        [M, specs] = rw.h5readMovie(fullpath_movie);
        Mmean = std(M, [], 3, 'omitnan');%std(M, [],3, 'omitnan');% mean(M,3, 'omitnan');%

        mask = cast(specs.getMask(), class(M));
           
        fig_mask = plt.getFigureByName("Movie masking");
        subplot(1,3,1); imshow(Mmean, []); title("mean");
        subplot(1,3,2); imshow(mask, []); title("mask");
        subplot(1,3,3); imshow(Mmean.*mask, []); title("mean masked");   
        
        m = squeeze(mean(M, [1,2], 'omitnan'));
        mout = squeeze(mean(M.*mask, [1,2], 'omitnan'));

        fig_trace = plt.getFigureByName("Traces comparison");
        plt.tracesComparison([m, mout],  'fps', specs.getFps(), 'fw', 0.2,...
            'labels', ["spatially-averaged trace",  "spatially-averaged trace after masking"]) 
        
        %%
        
        saveas(fig_mask, fullfile(options.diagnosticdir, basefilename+postfix + "_masking.png"))
        saveas(fig_mask, fullfile(options.diagnosticdir, basefilename+postfix + "_masking.fig"))
        saveas(fig_trace, fullfile(options.diagnosticdir, basefilename+postfix + "_traces.png"))
        saveas(fig_trace, fullfile(options.diagnosticdir, basefilename+postfix + "_traces.fig"))
    end
    
 end
%%

function options = defaultOptions(basepath)
    
    options.diagnosticdir = basepath + "\diagnostic\addMask\";
    options.plot = true;
end
%%