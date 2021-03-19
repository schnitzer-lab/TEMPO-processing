function [hAxes,summary]=formatPlot(varargin)
% HELP FORMATPLOT.M
% Formatting regular single axis plot for publication quality.
% SYNTAX
% [hAxes,summary]=formatPlot() - goes recursively over all found axes 
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
% - 2021-02-06 18:58:03 - handling empty axes handle   RC

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

options.verbose=false;

%% VARIABLE CHECK 

if nargin==0
    hAxes=findall(gcf,'Type','Axes');
elseif isempty(varargin{1})
    hAxes=findall(gcf,'Type','Axes');
else 
    hAxes=varargin{1};
end

if isempty(hAxes)
    hAxes=findall(gcf,'Type','Axes');
end

if nargin>=2
options=getOptions(options,varargin(2:end));
end
summary=initSummary(options);


%% CORE
%The core of the function should just go here.
if numel(hAxes)>1
    disps('Recursive settting')
    for iAx=1:numel(hAxes)
        if isa(hAxes(iAx),'matlab.ui.controls.AxesToolbar'), continue; end
        [~,summary.recursive(iAx)]=formatPlot(hAxes(iAx),'options',options);
    end
    return
end
        

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
if length(hLines)==1
    mycolors=brewermap(2,options.brewerset);
    mycolors=mycolors(2,:); % blue
    % blue
elseif length(hLines)==2
%         mycolors=brewermap(length(hLines),options.brewerset);
%         mycolors=flipud(mycolors); % as the lines appear in the reverse order if created by hold on
    mycolorsTmp=brewermap(length(hLines),options.brewerset);
    mycolors=mycolorsTmp;
    mycolors(1,:)=mycolorsTmp(2,:);
    mycolors(2,:)=mycolorsTmp(1,:);

elseif length(hLines)==3
    mycolorsTmp=brewermap(length(hLines),options.brewerset);
    mycolors=mycolorsTmp;
    mycolors(1,:)=mycolorsTmp(2,:);
    mycolors(2,:)=mycolorsTmp(1,:);

else
    mycolors=brewermap(length(hLines),options.brewerset);
    mycolors=flipud(mycolors); % as the lines appear in the reverse order if created by hold on
end
    
    
if ~isempty(options.legend)
    if ~iscell(options.legend)
        options.legend={options.legend};
    end
    summary.legend=legend(options.legend{1:min(length(hLines),length(options.legend))},'Box','off','Location','north','orientation','horizontal');
end
for iLine=1:length(hLines)
    formatLine(hLines(iLine),mycolors(iLine,:)); % nested functions below
end




%% CLOSING
summary=closeSummary(summary);
if options.verbose, disps('Plot formatted'); end

%% NESTED FUNCTIONS
    function formatLine(hLine,color)
        hLine.LineWidth=options.width;
        if options.setcolor
            hLine.Color=color;
        end
    end
        
end  %%% END FORMATPLOT
