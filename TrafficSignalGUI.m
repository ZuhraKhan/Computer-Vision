%% Assignment 1
function TrafficSignalGUI
    fig = figure('Name', 'Traffic Signal Detector', 'Position', [150, 120, 600, 500]);

    uicontrol('Style', 'pushbutton', 'String', 'Browse Image', 'FontSize', 14, ...
        'Position', [200, 400, 150, 40], 'Callback', @selectImage);

    
    ax = axes('Parent', fig, 'Position', [0.1, 0.2, 0.8, 0.6]);

   
    label = uicontrol('Style', 'text', 'String', 'Detected Signal: None', ...
        'FontSize', 14, 'Position', [200, 50, 240, 30], 'ForegroundColor', 'black');

    function selectImage(~, ~)
        [file, path] = uigetfile({'*.jpg;*.png;*.jpeg', 'Image Files (*.jpg, *.png, *.jpeg)'});
        if file == 0
            return; 
        end

        img_path = fullfile(path, file);
        img = imread(img_path);

        % detectcolour function call
        detected_color = detectTrafficLight(img);

        % clearing axes   
        cla(ax);  
        imshow(img, 'Parent', ax);
        title(ax, ['Detected Traffic Light: ', detected_color]);

       
        set(label, 'String', ['Detected Signal: ', detected_color], 'ForegroundColor', 'black');
    end
end

function detected_color = detectTrafficLight(img)
    
    hsv_img = rgb2hsv(img);
    % normalizing the Intensity to make sure it works on bright/low light
    I = hsv_img(:,:,3);
    I = adapthisteq(I);
    hsv_img(:,:,3) = I; 

    % colours ranges
    red = (hsv_img(:,:,1) < 0.05 | hsv_img(:,:,1) > 0.95) & hsv_img(:,:,2) > 0.4 & hsv_img(:,:,3) > 0.5;  
    yellow = (hsv_img(:,:,1) > 0.08 & hsv_img(:,:,1) < 0.2) & hsv_img(:,:,2) > 0.4 & hsv_img(:,:,3) > 0.5; 
    green = (hsv_img(:,:,1) > 0.25 & hsv_img(:,:,1) < 0.45) & hsv_img(:,:,2) > 0.4 & hsv_img(:,:,3) > 0.5;

    % Combine masks
    combined = red | yellow | green;
    combined = imopen(combined, strel('disk', 5));
    combined = imclose(combined, strel('disk', 5));
    % extracting region
    stats = regionprops(combined, 'BoundingBox', 'Area');
    % colour not found
    if isempty(stats)
        detected_color = 'None';
        return;
    end

    % defing and cropping the region of the expected traffic light
    [~, max_idx] = max([stats.Area]);
    bbox = stats(max_idx).BoundingBox;
    crop = imcrop(img, bbox);
    cropped_img = rgb2hsv(crop);

    % Count dominant color pixels in the cropped region
    red_count = sum(sum((cropped_img(:,:,1) < 0.05 | cropped_img(:,:,1) > 0.95) & cropped_img(:,:,2) > 0.4 & cropped_img(:,:,3) > 0.5));
    yellow_count = sum(sum((cropped_img(:,:,1) > 0.08 & cropped_img(:,:,1) < 0.2) & cropped_img(:,:,2) > 0.4 & cropped_img(:,:,3) > 0.5));
    green_count = sum(sum((cropped_img(:,:,1) > 0.25 & cropped_img(:,:,1) < 0.45) & cropped_img(:,:,2) > 0.4 & cropped_img(:,:,3) > 0.5));

    % Determine detected color
    [~, idx] = max([red_count, yellow_count, green_count]);
    colors = {'Red', 'Yellow', 'Green'};
    detected_color = colors{idx};

    % If no strong signal is found, return 'None's
    if max([red_count, yellow_count, green_count]) < 50
        detected_color = 'None';
    end
end
