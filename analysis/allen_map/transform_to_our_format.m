% Script to take the allen map from 
% Rob Campbell (2026). AllenAtlasTopDown 
% https://github.com/Zapit-Optostim/AllenAtlasTopDown/
% https://www.mathworks.com/matlabcentral/fileexchange/122877-allenatlastopdown
% and make a few minor adjustments to make it back-compatible with our data

load("atlas_data.mat")


%%

outlines  = cellfun(@(x) x(:), {atlas_data.dorsal_brain_areas.boundaries_stereotax}, 'UniformOutput', false);
outlines = vertcat(outlines{:});

names = {atlas_data.dorsal_brain_areas.names};
for i_n = 1:length(names)
    n_outlines = length(atlas_data.dorsal_brain_areas(i_n).boundaries);
    names{i_n} = repelem(names{i_n}, n_outlines);
end

names = [names{:}];

% removie Visceral area; it's all the way on the edge and basically
% invisible, and for consistency with previously used allen outlines
outlines(24) = [];
outlines(23) = [];

names(24) = [];
names(23) = [];

% split the areas next to midline defined above into two areas, one for
% each hemesphere. First, make extra room in the array.
areas_tosplit = [47, 48, 51, 52];
split_point = 60;
nextra = length(areas_tosplit)*2;

for i_o = (length(outlines) + nextra):-1:(split_point+nextra)
    outlines{i_o} = outlines{i_o-nextra};
    names{i_o} = names{i_o-nextra};
    outlines{i_o-nextra} = NaN(1,2);
    names{i_o-nextra} = {};
end


% split the areas next to midline defined above into two areas, one for
% each hemesphere
for i_a = 1:length(areas_tosplit)

    midline = mean(outlines{areas_tosplit(i_a)}(:,2));
    new_outline1 = outlines{areas_tosplit(i_a)}(outlines{areas_tosplit(i_a)}(:,2) > midline, :);
    new_outline1(end,:) = new_outline1(1,:);
    new_outline2 = outlines{areas_tosplit(i_a)}(outlines{areas_tosplit(i_a)}(:,2) < midline, :);
    new_outline2(end,:) = new_outline2(1,:);
    
    outlines{split_point + 2*(i_a-1)} = new_outline1;
    outlines{split_point + 1 + 2*(i_a-1)} = new_outline2;
    names{split_point + 2*(i_a-1)} = names{areas_tosplit(i_a)};
    names{split_point + 1 + 2*(i_a-1)} = names{areas_tosplit(i_a)};
end

% mirror w respect to midline
midline = mean(vertcat(outlines{:}));
for i_c = 1:length(outlines)
    outlines{i_c}(:, 2) = 2*midline(2) - outlines{i_c}(:, 2);
end
%%

plt.outlines(outlines)
for i_c = 1:length(outlines)
    outline = outlines{i_c};
    text(mean(outline(:,1)), mean(outline(:,2)), 0, num2str(i_c))
end
%%

plt.outlines(outlines)
for i_c = 1:length(outlines)
    outline = outlines{i_c};
    text(mean(outline(:,1)), mean(outline(:,2)), 0, names{i_c})
end
%%

allenmap.edgeOutline = outlines;
allenmap.names = names;

allenmap.reference = ...
    ['Rob Campbell (2026). AllenAtlasTopDown' ...
     'https://github.com/Zapit-Optostim/AllenAtlasTopDown/' ...
     'https://www.mathworks.com/matlabcentral/fileexchange/122877-allenatlastopdown' ...
      'with minor adjustments to make it back-compatible with our data' ];

% plt.outlines(allenmap.edgeOutline)
% for i_c = 1:length(allenmap.edgeOutline)
%     outline = allenmap.edgeOutline{i_c};
%     text(mean(outline(:,1)), mean(outline(:,2)), 0, num2str(i_c))
% end

%%

save('allenmap.mat', 'allenmap')

