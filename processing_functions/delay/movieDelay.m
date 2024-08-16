function fullpath_out = movieDelay(fullpath_movie, delay, varargin)
    
    [basepath, filename, ext, ~] = filenameParts(fullpath_movie);

    options = defaultOptions(basepath);
    if(~isempty(varargin))
        options = getOptions(options, varargin);
    end

    %%
    
    specs = rw.h5readMovieSpecs(fullpath_movie);
    delay_frames = delay*specs.getFps();
    %%

    postfix_new = "_df" + num2str(round(delay_frames, 1));
    %%
       
    if (~isfolder(options.outdir)) mkdir(options.outdir); end
    if (~isfolder(options.diagnosticdir)) mkdir(options.diagnosticdir); end

    filename_out = filename + postfix_new;
    fullpath_out = fullfile(options.outdir, filename_out + ext);
    
    if (isfile(fullpath_out))
        if(options.skip)
            disp("movieDelay: Output file exists. Skipping: " + fullpath_out)
            return;
        else
            warning("movieDelay: Output file exists. Deleting: " + fullpath_out);
            delete(fullpath_out);
        end     
    end

%%
    disp("movieDelay: computing delayed movie");
    [M, specs] = rw.h5readMovie(fullpath_movie);
    m = squeeze(mean(M, [1,2], 'omitnan'));

    [nx, ny] = size(M, [1,2]);

    % somehow parfor works better without nested loops... 
    M = reshape(M, [nx*ny, size(M, 3)]);
    Mmean = mean(M,2,'omitnan');
    
    h = hamming(2*options.nw);

%     ppm = ParforProgressbar(nx*ny, 'title', 'applyFilters: parfor progress');
    parfor i_s = 1:(nx*ny)
        
%         m0 = mean(M(i_s, (1+options.frame0):end))
        m = (M(i_s, :))' - Mmean(i_s);

        if(all(isnan(m))) continue; end
        
        x = [h(1:options.nw)*m(1+options.frame0);...
             m((1+options.frame0):end); 
             h(options.nw:end)*m(end)];
        md = delayseq(x, delay_frames);
        md = md( ((options.nw+1):(end-options.nw-1)));
        md = [repelem(md(1), options.frame0)'; md] ;
        
        % in-place to save ram
        M(i_s, :) = md + Mmean(i_s);
%         ppm.increment();
    end
%     delete(ppm)
    
    Md = reshape(M, [nx,ny,size(M,2)]);
    clear('M');
%%

    fig_mean = plt.getFigureByName("movieDelay: mean");
    md = squeeze(mean(Md, [1,2], 'omitnan'));

    plt.tracesComparison([m,md], 'labels', ["initial", "delayed"])
    % plt.tracesComparison([x(:,1), x(:,1)-x(:,2), x(:,1)-x(:,3)])
    sgtitle([basepath, filename], 'interpreter', 'none', 'FontSize', 8)
%%

    disp("movieDelay: saving delayed movie");
    
    specs_out = copy(specs);
    specs_out.AddToHistory(functionCallStruct({'fullpath_movie', 'delay', 'options'}));
    
    rw.h5saveMovie(fullpath_out, Md, specs_out);

    saveas(fig_mean, fullfile(options.diagnosticdir, filename_out + "_mean.png"))
    saveas(fig_mean, fullfile(options.diagnosticdir, filename_out + "_mean.fig"))
%%
end
%%

function options = defaultOptions(basepath)
    
    options.diagnosticdir = basepath + "\diagnostic\movieDelay\";
    options.outdir = basepath;
    options.skip = true;

    options.nw = 128;
    options.frame0 = 1;
end
%%

