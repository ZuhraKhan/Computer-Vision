
I = imread('ab.jpg'); 
Ihsv = rgb2hsv(I);


banana_mask = (Ihsv(:,:,1) > 0.10 & Ihsv(:,:,1) < 0.20) & ... % yellow
              (Ihsv(:,:,2) > 0.4 & Ihsv(:,:,2) < 1) & ... %s
              (Ihsv(:,:,3) > 0.5 & Ihsv(:,:,3) < 1); %i
          
apple_mask = (Ihsv(:,:,1) > 0.95 | Ihsv(:,:,1) < 0.05) & ... %red
             (Ihsv(:,:,2) > 0.4 & Ihsv(:,:,2) < 1) & ... %s
             (Ihsv(:,:,3) > 0.3 & Ihsv(:,:,3) < 1); %i

 
banana_mask = imdilate(banana_mask, strel('disk', 8));  
banana_mask = imerode(banana_mask, strel('disk', 5));  
banana_mask = bwareaopen(banana_mask, 800);
  
apple_mask = imdilate(apple_mask, strel('disk', 8));  
apple_mask = imerode(apple_mask, strel('disk', 5));  
apple_mask = bwareaopen(apple_mask, 800);

figure, imshow(banana_mask); title('Banana Mask');
figure, imshow(apple_mask); title('Apple Mask');


banana_boundaries = bwboundaries(banana_mask);
apple_boundaries = bwboundaries(apple_mask);


banana_stats = regionprops(banana_mask, 'Area', 'Perimeter');
apple_stats = regionprops(apple_mask, 'Area', 'Perimeter', 'Centroid');


figure;
subplot(1,3,1),
imshow(I);
title('Original Image');
subplot(1,3,2),
imshow(banana_mask | apple_mask);
title('Binarized Image');

subplot(1,3,3),imshow(I);
title('Detected Fruits with Boundaries');
hold on;

for k = 1:length(banana_boundaries)
    boundary = banana_boundaries{k};
    plot(boundary(:,2), boundary(:,1), 'r', 'LineWidth', 2);
end


for k = 1:length(apple_boundaries)
    boundary = apple_boundaries{k};
    plot(boundary(:,2), boundary(:,1), 'y', 'LineWidth', 2);
end


for i = 1:numel(apple_stats)
    centroid = apple_stats(i).Centroid;
    plot(centroid(1), centroid(2), 'go', 'MarkerSize', 4, 'MarkerFaceColor', 'g'); % Green dot
end
hold off;


fprintf('\n    Banana Properties \n');
for i = 1:numel(banana_stats)
    area = banana_stats(i).Area;
    perimeter = banana_stats(i).Perimeter;
    circularity = (4 * pi * area) / (perimeter^2);
    
    fprintf('Banana %d:\n', i);
    fprintf('  Area: %d pixels\n', area);
    fprintf('  Perimeter: %.2f pixels\n', perimeter);
    fprintf('  Circularity: %.2f\n\n', circularity);
end

fprintf('\n    Apple Properties \n');
for i = 1:numel(apple_stats)
    area = apple_stats(i).Area;
    perimeter = apple_stats(i).Perimeter;
    circularity = (4 * pi * area) / (perimeter^2);
    centroid = apple_stats(i).Centroid;
    
    fprintf('Apple %d:\n', i);
    fprintf('  Area: %d pixels\n', area);
    fprintf('  Perimeter: %.2f pixels\n', perimeter);
    fprintf('  Circularity: %.2f\n', circularity);
    fprintf('  Centroid: (%.2f, %.2f)\n\n', centroid(1), centroid(2));
end
