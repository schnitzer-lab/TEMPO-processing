function [movie2D,origSize]=to2D(movie3D)
% HELP to2D.M
% Reshaping movie from 3D to 2D for 2D decomposition and filtering functions.
% SYNTAX
%[movie2D,origSize,summary]= to2D(movie3D) 
%
% INPUTS:
% - movie3D - ...
%
% OUTPUTS:
% - movie2D - ...
% - origSize - 

% HISTORY
% - 25-Mar-2021 11:27:36 - created by Radek Chrapkiewicz (radekch@stanford.edu)

origSize=size(movie3D);

movie2D=reshape(movie3D,size(movie3D,1)*size(movie3D,2),size(movie3D,3));