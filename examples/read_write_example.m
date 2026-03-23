basefolder_analysis = "N:\GEVI_Wave\Analysis\";  
recording_name = "Visual\m48\20210824\meas00";
filename_in = "cG_unmixed_dFF.h5";

fullpath_in = fullfile(basefolder_analysis, recording_name, filename_in);
%%

% reading movie array /movie into M and /specs into specs. 
[M,specs] = rw.h5readMovie(fullpath_in);

% or independently read only the specs file
specs = rw.h5readMovieSpecs(fullpath_in);

%%

% M is a multi-dimensional MATLAB array with the last dimention being the frames axis, 
disp(size(M))

% specs is an object of a class MovieSpecs. It stores metadata and provides
% convenient setter/getter access to some parameters.
disp(specs)
disp(specs.getFps())
disp(specs.getPixSize())

%%
% stimulus input trace

plot(specs.getTTLTrace())

%%

filename_out = "cG_unmixed_dFF_stuffsdone.h5";
fullpath_out = fullfile(basefolder_analysis, recording_name, filename_out);

%%
% to save
specs_out = copy(specs);
specs.AddToHistory("did something", {});
rw.h5saveMovie(fullpath_out, M, specs_out)


