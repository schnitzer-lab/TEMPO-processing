function [box_crop] = getCropBoxNaN(image_in)

   [nonZeroRows,nonZeroColumns] = find(~any(isnan(image_in),3));

   topRow = min(nonZeroRows(:));
   bottomRow = max(nonZeroRows(:));
   leftColumn = min(nonZeroColumns(:));
   rightColumn = max(nonZeroColumns(:));

   box_crop = [leftColumn, topRow, rightColumn-leftColumn+1, bottomRow-topRow+1];
end

