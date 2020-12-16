function [hAxes,summary]=formatPlot(varargin)
% HELP FORMATPLOT.M
% Formatting regular single axis plot for publication quality.
% SYNTAX
% [hAxes,summary]=formatPlot() - use gca 
% [hAxes,summary]=formatPlot(hAxes) - if empty, then using gca 
% [hAxes,summary]= formatPlot(...,'optionName',optionValue,...) - passing options using a 'Name', 'Value' paradigm frequently used by Matlab native functions.
% [hAxes,summary]= formatPlot(...,'options',options) - passing options as a structure.
%
% INPUTS:
%
% OUTPUTS:
% OPTIONS:
% - see below the section of code showing all possible input options and comments for their meaning. 

% HISTORY
% - 15-Dec-2020 15:00:52 - created by Radek Chrapkiewicz (radekch@stanford.edu)

%% OPTIONS - configure full display here
options=struct; % add your options below 
options.exponents=false; % allow exponent labels (not allowed for publication);
options.box='off';
options.tick='out';
options.font='Arial';
options.fontsize=10;
options.width=1.5; % for line widht
options.axis='tight';
options.setcolor=true; % setting colors of lines 
options.legend={'Camera1','Camera2','Unmixed'};
options.brewerset='Set1'; % Set1 - recommended; Spectral set of colors from the brewer colormap; see 'brewermap_view' for more choices 
% Other options: Set1-3, Pastel1-2, Dark2, Accent or some divergent
% colormaps

%% VARIABLE CHECK 

if nargin==0
    hAxes=gca;
else
    hAxes=varargin{1};
end

if isempty(hAxes)
    hAxes=gca;
end

if nargin>=2
options=getOptions(options,varargin(2:end)); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
end
summary=initSummary(options);


%% CORE
%The core of the function should just go here.

set(gcf','color','white')

axis(options.axis);
box(options.box);
hAxes.YRuler.Exponent = options.exponents;
hAxes.XRuler.Exponent = options.exponents;
hAxes.TickDir=options.tick;
hAxes.FontName=options.font;
hAxes.FontSize=options.fontsize;



% recoloring lines
hLines=findall(hAxes,'Type','Line');
mycolors=brewermap(length(hLines),options.brewerset);
mycolors=flipud(mycolors); % as the lines appear in the reverse order if created by hold on

if ~isempty(options.legend)
    summary.legend=legend(options.legend{1:length(hLines)},'Box','off','Location','north','orientation','horizontal');
end
for iLine=1:length(hLines)
    formatLine(hLines(iLine),mycolors(iLine,:)); % nested functions below
end




%% CLOSING
summary=closeSummary(summary);
disps('Plot formatted')

%% NESTED FUNCTIONS
    function formatLine(hLine,color)
        hLine.LineWidth=options.width;
        if options.setcolor
            hLine.Color=color;
        end
    end
        
end  %%% END FORMATPLOT
