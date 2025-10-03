
load allenmap.mat

f = plt.getFigureByName("ref points");

for i_r = 1:length(allenmap.edgeOutline)
%     region_outline = allenmap.edgeOutline{i_r};
    region_outline =allenmap.edgeOutline{i_r}(:,[1,2]);
%     region_outline(:,2) = -region_outline(:,2);
    plot(region_outline(:,1), region_outline(:,2), 'color', [1,1,1], 'LineWidth', 1); hold on;
%     text(mean(region_outline(:,1)), mean(region_outline(:,2)), string(i_r))
end

points_ref = [250,440; 230,340; 370,340;  420,440]; % For large fov
% points_ref = [250,440; 350,480; 370,400;  480,440]; % For V1-centered fov
points_colors = [linspace(0.5, 1, size(points_ref,1))', zeros(size(points_ref,1), 1), linspace(1, 0.5, size(points_ref,1))'];


scatter(points_ref(:,1), points_ref(:,2), 80,  points_colors, '.'); 
hold off;

set(f, 'InvertHardcopy', 'off')
set(f, 'Color', [0,1,0]); % Sets axes background
set(gca, 'Color', [0,1,0]); % Sets axes background
pbaspect([1 1 1])
axis off
drawnow;

saveas(f, 'allen_reference_image.png')
writematrix([points_ref, points_colors], 'allen_reference_points.txt' )