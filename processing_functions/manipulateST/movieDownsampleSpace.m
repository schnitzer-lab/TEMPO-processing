function fullpath_out = movieDownsampleSpace(fullpath, ns, varargin)
        
    [basepath, filename, ~] = fileparts(fullpath);
    
    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end

    paramssummary = [num2str(ns), 's'];
    postfix_new = "_down" + paramssummary;

    %%

    if (~isfolder(options.outdir)), mkdir(options.outdir); end
    if (~isfolder(options.processingdir)), mkdir(options.processingdir); end

    fullpath = fullfile(basepath, filename +  ".h5");

    filename_out = filename + postfix_new;
    fullpath_out = fullfile(options.outdir , filename_out + ".h5");
 
    if (isfile(fullpath_out))
        if(options.skip)
            displog("movieDownsample: Output file exists. Skipping: " + fullpath_out)
            return;
        else
            warning("movieDownsample: Output file exists. Deleting: " + fullpath_out);
            delete(fullpath_out);
        end     
    end
    %%
    

    nframes = rw.h5getDatasetSize(fullpath, '/mov', 3);
    if(options.nframes_read == Inf), options.nframes_read = nframes; end
    
    nchunks = ceil(nframes/options.nframes_read);
    if(nchunks == 0), nchunks=1; end
    %%

    [M_frame1, specs] = rw.h5readMovie(fullpath, 'frame_start', 1, 'frames_num', 1);

    if(isempty(options.class_out)), options.class_out = class(M_frame1); end

    M_frame1_d = mm.DownsampleSpace(M_frame1, ns);
    M_frame1_d = cast(M_frame1_d, options.class_out);
    central_pix = round(size(M_frame1, [1,2])/2);
    central_pix_d = round(size(M_frame1_d, [1,2])/2);

    Mdown = NaN([size(M_frame1_d), nframes], options.class_out);
    Mtot = zeros(size(M_frame1, [1,2]));
    m = NaN([nframes, 1]);
    m1 = NaN([nframes, 1]);
    %%

    for i_ch = 1:nchunks
        %%
        
        frame_start = options.nframes_read*(i_ch-1)+1;
        frame_end = min(options.nframes_read*(i_ch), nframes);
        
        [M_chunk, ~] = rw.h5readMovie(fullpath, 'frame_start', frame_start, ...
            'frames_num', frame_end-frame_start+1);
        Mdown_chunk = mm.DownsampleSpace(M_chunk, ns);

        Mdown(:,:,frame_start:frame_end) = cast(Mdown_chunk, options.class_out);
        
        m(frame_start:frame_end) = squeeze(mean(M_chunk, [1,2], 'omitnan'));
        m1(frame_start:frame_end) = squeeze(M_chunk(central_pix(1), central_pix(2), :));
        Mtot = Mtot + sum(M_chunk,3);
        %%
    end
    %%
    
    specs_out = copy(specs);
    specs_out.AddBinning(ns);
    
    specs_out.AddToHistory(functionCallStruct({'fullpath','ns','options'}));
    %%
    
    if(specs.extra_specs.isKey("F0"))
        specs_out.extra_specs("F0") =  mm.DownsampleSpace(specs.extra_specs("F0"), ns);
    elseif(specs.extra_specs.isKey("expBaseline_A"))
        specs_out.extra_specs("expBaseline_A") =  mm.DownsampleSpace(specs.extra_specs("expBaseline_A"), ns);
    elseif(specs.extra_specs.isKey("mean_substracted")) 
        specs_out.extra_specs("mean_substracted") =  mm.DownsampleSpace(specs.extra_specs("mean_substracted"), ns);
    end
    %%
    
    rw.h5saveMovie(fullpath_out, Mdown, specs_out);
    %%
    
    mdown = squeeze(mean(Mdown, [1,2], 'omitnan'));
    mdown1 = squeeze(Mdown(central_pix_d(1),central_pix_d(2),:));
    
    fig_mean = plt.getFigureByName("movieDownsampleSpace: mean traces");
    plt.tracesComparison([m, mdown], ...
        'labels', ["original", "downsampled"],...
        'fps', specs.getFps(), 'fw', 0.2, 'f0', specs.getFrequencyRange(1))

    fig_pix = plt.getFigureByName("movieDownsampleSpace: single pix traces");
    plt.tracesComparison([m1, mdown1], ...
        'labels', ["original", "downsampled"],...
        'fps', specs.getFps(), 'fw', 0.2, 'f0', specs.getFrequencyRange(1))
    
    fig_frame = plt.getFigureByName("movieDownsampleSpace: mean frame");
    subplot(1,2,1)
    imshow(Mtot/nframes, []);
    subplot(1,2,2)
    imshow(mean(Mdown,3), []);
    
    saveas(fig_mean, fullfile(options.processingdir, filename_out  + '_traces.png') )
    saveas(fig_mean, fullfile(options.processingdir, filename_out  + '_traces.fig') )
    saveas(fig_pix, fullfile(options.processingdir, filename_out  + '_pixtraces.png') )
    saveas(fig_pix, fullfile(options.processingdir, filename_out  + '_pixtraces.fig') )
    imwrite(mat2gray(Mtot/nframes), fullfile(options.processingdir, filename_out + "_mean_in.bmp"));
    imwrite(mat2gray(mean(Mdown,3)), fullfile(options.processingdir, filename_out + "_mean_out.bmp"));
end

function options = defaultOptions(basepath)
    
    options.processingdir = basepath + "\diagnostic\movieDownsampe\";
    options.outdir = basepath;
    options.skip = true;
    
    options.nframes_read = Inf;
    options.class_out = [];
end


