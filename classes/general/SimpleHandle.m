classdef (Abstract) SimpleHandle < handle
    % class such as handle but without default notifier and listener
    % methotds.
    % taken and modified  by from SI2016 (originally Class.m)
    %
    % RC '19-02-21_17:29:09'
    % - % 2019-09-25 13:55:47 RC - updated with help and summary methods
    % - 2020-09-13 15:32:08 - renamed simpleHandle -> SimpleHandle RC
    
    properties
    end
    
    methods
        function obj = SimpleHandle()
            
        end
        
        function help(obj)
            % just a help for the child class
            %             disp('This method is inherrited from simpleHandle class and hasn''t been implemented yet!');
            help(class(obj))
        end
        
        
        function graph_obj=summary(obj)
            % graphical and text summary of methods of the children class.
            fprintf('Displaying a class summary for the %s class. This method has been inherited from the supperclass simpleHandle and can be used for other children classes too.\n\n',class(obj))
            graph_obj=summary_handle(class(obj));
            methods(class(obj))
        end
        
        function methodsCell=methods(obj)
            % graphical and text summary of methods of the children class.
            methodsCell=methods(class(obj));
        end
        
        function open(obj)
            % opening any related folder path. Function searches for a
            % class field containing 'folder' string. If nothing found, it
            % makes an analogous search for 'path' field
            FIELD_NAMES_TO_TEST={'folder','path'};
            
            fprintf('Opening a related folder for the %s class. This method has been inherited from the supperclass simpleHandle and can be used for other children classes too.\n',class(obj))
            field_cell=fields(obj);
            
            open_successful=false;
            for fn_idx=1:length(FIELD_NAMES_TO_TEST)
                for ii=1:length(field_cell)
                    foundfolderstring=strfind(field_cell{ii},FIELD_NAMES_TO_TEST{fn_idx});
                    if ~isempty(foundfolderstring)
                        if isfolder(obj.(field_cell{ii}))
                            try
                                winopen(obj.(field_cell{ii}));
                                open_successful=true;
                            catch ME
                                util.errorHandling(ME)
                                warning('Opening of %s didn'' work apparently',field_cell{ii})
                            end
                            break
                        end
                    end
                end
                if open_successful; break; end
            end
            
            if ~open_successful; disp('Din''t find any folder path related fields to open in this object...'); end
            
        end
        
        
        
        
    end %%% END OF PUBLIC METHODS
    
    %Overload matlab handle methods to hide them
    methods(Sealed,Hidden)
        function lh = addlistener(varargin)
            lh = addlistener@handle(varargin{:});
        end
        function notify(varargin)
            notify@handle(varargin{:});
        end
        
        function Hmatch = findobj(varargin)
            Hmatch = findobj@handle(varargin{:});
        end
        function p = findprop(varargin)
            p = findprop@handle(varargin{:});
        end
        function TF = eq(varargin)
            TF = eq@handle(varargin{:});
        end
        function TF = ne(varargin)
            TF = ne@handle(varargin{:});
        end
        function TF = lt(varargin)
            TF = lt@handle(varargin{:});
        end
        function TF = le(varargin)
            TF = le@handle(varargin{:});
        end
        function TF = gt(varargin)
            TF = gt@handle(varargin{:});
        end
        function TF = ge(varargin)
            TF = ge@handle(varargin{:});
        end
        % RC added '19-02-21_17:24:54'
        
        function TF = listener(varargin)
            TF = listener@handle(varargin{:});
        end
    end %%% END OF SEALED AND HIDDEN METHODS
    
    %     methods (Hidden) cannot be redefined as it is Sealed in hanlde class
    %         function TF = isvalid(varargin)
    %             TF = isvalid@handle(varargin{:});
    %         end
    %     end
    
    methods (Static)
        function demo()
            figure1 = figure('Name','Demo of the class','Position',[200 153 999.2000 445.6000],'Units','Pixels');
            
            % Create textbox
            annotation(figure1,'textbox',...
                [0.350680544435548 0.615798921901833 0.13450760905317 0.0601436274698007],...
                'String',{'obj=MyClass(arg1)'});
            
            % Create arrow
            annotation(figure1,'arrow',[0.411529223378703 0.411529223378703],...
                [0.611208258527828 0.473967684021544]);
            
            % Create textbox
            annotation(figure1,'textbox',...
                [0.379903923138511 0.413824056551745 0.064851882812784 0.0601436274698008],...
                'String',{'obj.plot'});
            
            % Create textbox
            annotation(figure1,'textbox',...
                [0.226180944755805 0.226109513633772 0.861489211653976 0.090664274517039],...
                'String','Since this is not defined for this class yet, use "obj.summary" instead',...
                'LineStyle','none',...
                'FontName','Candara',...
                'FitBoxToText','off');
            
            % Create textbox
            annotation(figure1,'textbox',...
                [0.0592473979183346 0.754834827816895 0.861489211653976 0.0906642745170388],...
                'String',{'Demo exampless of the class should go here to quickly grasp how to use the class!'},...
                'LineStyle','none',...
                'FontSize',18,...
                'FontName','Candara',...
                'FitBoxToText','off');
        end
        
    end %%% end of Static methods
    
end

