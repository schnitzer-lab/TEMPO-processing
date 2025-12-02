
load allenmap.mat

scale0 = 10/(689-140); % mm/pix, from https://www.mathworks.com/matlabcentral/fileexchange/122877-allenatlastopdown 
scale_target = 9/2170*8; 

a = -scale0/scale_target;


f = plt.getFigureByName("ref points");

for i_r = 1:length(allenmap.edgeOutline)
%     region_outline = allenmap.edgeOutline{i_r};
    region_outline = allenmap.edgeOutline{i_r}(:,[1,2])*a;
%     region_outline(:,2) = -region_outline(:,2);
    plot(region_outline(:,1), region_outline(:,2), 'color', [1,1,1], 'LineWidth', 1); hold on;
%     text(mean(region_outline(:,1)), mean(region_outline(:,2)), string(i_r))
end


points_ref = [250,440; 230,340; 370,340;  420,440]; % For large fov
% points_ref = [250,440; 350,480; 370,400;  480,440]; % For V1-centered fov
points_colors = [linspace(0.5, 1, size(points_ref,1))', zeros(size(points_ref,1), 1), linspace(1, 0.5, size(points_ref,1))'];


scatter(points_ref(:,1)*a, points_ref(:,2)*a, 80,  points_colors, '.'); 
hold off;

set(f, 'InvertHardcopy', 'off')
set(f, 'Color', [0,1,0]); % Sets axes background
set(gca, 'Color', [0,1,0]); % Sets axes background

pbaspect([1 1 1])
axis off; 
axis tight
drawnow;


lims = [xlim(); ylim()];
lims = [min(lims(:,1)), max(lims(:,2))];

hold on;
plot([lims(1)+10, lims(1)+10+round(1/scale_target)], [lims(1)+10, lims(1)+10], ...
    'LineWidth', 0.2/scale_target, 'Color', 'white')
hold off;

lims = [xlim(); ylim()];
lims = [min(lims(:,1)), max(lims(:,2))];
xlim(lims); ylim(lims);
%%

F = getframe(gca);
[X, Map] = frame2im(F);
X = imresize(X, (lims(2)-lims(1))/size(X,1));

%%

% saveas(f, 'allen_reference_image_scaled.png')

imwrite(X, 'allen_reference_image_scaled.png')
writematrix([points_ref, points_colors], 'allen_reference_points_scaled.txt' )