function graph_obj=summary(class_name)
% EXAMPLE USE WITH ARGUMENTS
% summary(class_name) - use 1
% summary(arg1,arg2) - use 2, etc.
%
% HELP
% Function summarizing graphically all the available methods of the class in a form of a graph. This function could be wrapped as a static method for a class, for instantce as Class.summary static method.
%
% HISTORY
% - 19-04-24 17:48:28 - created by Radek Chrapkiewicz
%
% ISSUES
% #1 - issue 1
%
% TODO
% *1 - get the first working version of the function!


%% CONSTANTS

%% VARIABLE CHECK

if nargin==0
    %do something when no arguments?
end


if nargin>=1
    %do something when more than 1 arguments?
end


if nargin>=2
    %do something when more than 2 arguments?
end

%% PATHS


%% CORE
%The core of the function should just go here.

% check out Fig.summary to see all available methods
try
    handle_methods={'delete' ,'isvalid'};
    fig_methods=methods(class_name);
    
    
    for jj=1:length(handle_methods)
        for ii=1:length(fig_methods)
            if strcmp(fig_methods{ii},handle_methods{jj})
                ind_remove=ii;
            else 
                ind_remove=[];
            end
        end
        fig_methods(ind_remove)=[];
    end
    
    graph_adjacency=zeros(length(fig_methods));
    
    graph_adjacency(1,2:end)=1;
    
    
    
    hSummary=figure('Name',sprintf('Methods of the class %s',class_name),'Color','white');
    hSummary.WindowStyle='docked';
    
    graph_obj=graph(graph_adjacency,fig_methods,'upper','OmitSelfLoops');
    
    plot(graph_obj,'Layout','force');
    axis square
    axis off
    t=title(sprintf('This is summary of methods of the class %s',class_name));
    t.FontWeight='normal';
    t.FontName='Candara';
    
    
catch ME
    util.errorHandling(ME)
    keyboard
end

end  %%% END SUMMARY
