classdef Suffix
% HELP
% Minimalistic non-handle class to manipulate addind/removing/checking
% Suffixes of of file names
% HISTORY
% - 29-Jun-2020 18:25:51 - created by Radek Chrapkiewicz (radekch@stanford.edu)
% - 2020-09-13 15:32:50 - renamed to upper case 
% - 2020-10-29 18:37:25 - debugged searching suffixes in case they have the
% same core like '_umx','_umx_mask'
% - 2021-02-01 19:04:56 - adding checking for specific suffix in the 'has' method  RC

    properties
        fpath
        hasSuffix
        suff
    end
    
    properties (Constant)
        slist={'_res','_reg','_reg_bp','_bpmc','_moco','_moco_cropMovie','_umx','_umx_cropMovie','_umx_mask','_umx_detr'}; % allowed Suffixes in the file names, listed in the order of presedence , % empty suffix is a valid suffix
        % these suffixes should go from shortes to longest especially if
        % they have a repeated cores 
    end 
    
    properties (Constant, Access=private)
        exm='F:\GEVI_Wave\Raw\Visual\m2\20200613\meas00\7mm-side-visual-updown--BL100-fps116-cG_unmx.h5'; % just for debugging and testing, to be deleted % - 2020-06-29 19:05:31 -   RC 
    end
    
    methods
        function obj = Suffix(filepath)
            %Suffix Construct an instance of this class
            obj.fpath=filepath;
            [obj.hasSuffix, obj.suff]=Suffix.has(obj.fpath);
        end
        
        function newpath=change(obj,newSuffix)
           % changing Suffix of the filename. Function agnostic wheter Suffix already exists or not. 
           if Suffix.has(obj.fpath)
               newpath=Suffix.replace(obj.fpath,newSuffix);
           else
               newpath=Suffix.add(obj.fpath,newSuffix);
           end       
        end
    end %%% END OF PUBLIC METHODS
    
    %%% STATIC METHODS
    
    methods (Static)
        function Suffixes=list()
            % Outputs list of allowed Suffixes in the h5 file naming.
            Suffixes=Suffix.slist;            
        end  
        
        function isSuffix=is(Suffixstring)
            % check if string is a valid Suffix
            if isempty(Suffixstring), isSuffix=true; return; end; % empty suffix is a valid suffix
            
            slist=Suffix.list;            
            isSuffix=false;
            for ii=1:length(slist)
                isSuffix=strcmp(slist{ii},Suffixstring);
                if isSuffix; break; end
            end            
        end
        
        function [hasSuffix,suff]=has(fpath,varargin)
            %checks if the filename has a Suffix 
%             [hasSuffix,suff]=has(fpath)
%             [hasSuffix,suff]=has(fpath,suff) % - 2021-02-01 19:04:56 -   RC
            % [hasSuffix,suff]=has(fpath,suff,ignoreWarning)
            if nargin>=3
                ignoreWarning=varargin{2};
            else
                ignoreWarning=false;
            end
            [~,filename,~]=fileparts(fpath);
            hasSuffix=false;
            suff=[];
            if nargin==1
                for ii=fliplr(1:length(Suffix.list)) % scanning from longest to shortest ones % - 2020-10-29 18:37:25 -   RC
                    if contains(filename,Suffix.slist{ii})
                        hasSuffix=true;
                        suff=Suffix.slist{ii};
                        break
                    end
                end
            elseif nargin>=2 % - 2021-02-01 19:04:56 -   RC
                suff=varargin{1};
                if ~Suffix.is(suff) && ~ignoreWarning
                    warning('%s is not a proper suffix!',suff);
                end
                if contains(filename,suff)
                    hasSuffix=true;                 
                end                
            end
        end
        
        function newpath = replace(fpath,newsuff)
            if ~Suffix.is(newsuff)
                error('That''s not a valid Suffix')
            end
            
            [hasSuffix,oldsuff]=Suffix.has(fpath);
            if ~hasSuffix
                newpath=Suffix.add(fpath,newsuff);
            else
                newpath=strrep(fpath,oldsuff,newsuff);       
            end
        end
        
        function newpath = add(fpath,suff,varargin)
%             add(fpath,suff)
%             add(fpath,suff,'f') % forcing adding Suffix ignoring the
%             allowed list of ones 
            % adding Suffix to the file name if it is not present 
            if nargin>=3
                if strcmp(varargin{1},'f')
                    % ignoting Suffix
                else
                    suffcheck();
                end
            else
                suffcheck();
            end
            
            [folder,filename,ext]=fileparts(fpath);
            newpath=fullfile(folder,[filename, suff,ext]);
            % nested function 
            function suffcheck()
                if ~Suffix.is(suff)
                    error('That''s not a valid Suffix')
                end
                [hasSuffix]=Suffix.has(fpath);
                if hasSuffix
                    error('This file name has already a valid Suffix. Conider Suffix replacement');
                end
            end
        end
        
        function [path1rep,path2rep]=change2(path1,path2,suff)
            % replace Suffixes in two paths
            if ~Suffix.is(suff)
                error('%s - is not a valid Suffix',suff);
            end
            sobj1=Suffix(path1);
            path1rep=sobj1.change(suff);
            sobj2=Suffix(path2);
            path2rep=sobj2.change(suff);

        end
        
        function uniqueFilePath=addUnqInt(filePath)
            % adding a unique integer suffix to avoid overwriting 
            % - 2021-05-24 01:50:33 -   RC
            fileIdx=1;
            [folder,fname,ext]=fileparts(filePath);            
            while isfile([fullfile(folder,fname),sprintf('-%0.2d',fileIdx),ext])
                fileIdx=fileIdx+1;
            end
            uniqueFilePath=[fullfile(folder,fname),sprintf('-%0.2d',fileIdx),ext];            
        end

    end
end

