clc; clear;
% for f1, f5, f6, f7

I = imread(['f1.jpg']);
Igray = rgb2gray(I);
Igray = imadjust(Igray);

% Use Otsu's thresholding 
level = graythresh(Igray);
Ibw = imbinarize(Igray, level);
Ibw = ~Ibw;

Ibw = bwareaopen(Ibw, 1000);


Ibw = imfill(Ibw, 'holes');
se = strel('disk', 5);
Ibw = imclose(Ibw, se);


Ilabel = bwlabel(Ibw);
stat = regionprops(Ilabel, 'Area', 'Perimeter', 'Eccentricity', 'BoundingBox', ...
    'Solidity', 'MajorAxisLength', 'MinorAxisLength');


figure,
imshow(I);
hold on;


for x = 1:numel(stat)
    area = stat(x).Area;
    perimeter = stat(x).Perimeter;
    eccentricity = stat(x).Eccentricity;
    aspect_ratio = stat(x).MajorAxisLength / stat(x).MinorAxisLength;
    solidity = stat(x).Solidity;
    
  
    if perimeter > 0
        circularity = (4 * pi * area) / (perimeter^2);
    else
        circularity = 0; 
    end
    
    label = ''; 
    color = 'w'; 

   
    if aspect_ratio > 2.5 && eccentricity > 0.8 && solidity < 0.9
        label = 'Banana';
        color = 'y';
        
    
    elseif aspect_ratio < 2 && circularity > 0.3 && solidity > 0.85 && area > 500
        label = 'Strawberry';
        color = 'r';
    end
    
   
    if ~isempty(label)
        disp(['Detected: ', label, ' at Object ', num2str(x)]);
        rectangle('Position', stat(x).BoundingBox, 'EdgeColor', color, 'LineWidth', 2);
        text(stat(x).BoundingBox(1), stat(x).BoundingBox(2) - 10, label, 'Color', color, 'FontSize', 14, 'FontWeight', 'bold');
    end
end

hold off;
