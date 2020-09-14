function [summaryOut] = mergeSummary(summary1,summary2)
%CONCSUMMARY Concatenates, merges, two summary structures summary2 intro summary 1
% - 2020-09-13 20:40:52 -  by RC
summaryOut = summary1;
fNames = fieldnames(summary2);
for iField=1:length(fNames)
    summaryOut.(fNames{iField})=summary2.(fNames{iField});
end

end

