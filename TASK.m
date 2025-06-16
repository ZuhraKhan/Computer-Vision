clc;
clear;
camList = webcamlist;
cam = webcam(camList{1});  % Use first listed webcam

% cam = webcam;  % Connect to webcam
% PrevFrame = rgb2gray(snapshot(cam));  % Initial frame for motion comparison

load gong.mat;  % Load sound file for alert

for idx = 1:100
    rgbFrame = snapshot(cam);  % Get new frame
    NextFrame = rgb2gray(rgbFrame);  % Convert to grayscale
    
    % Frame difference for motion detection
    Dist = sqrt(sum((PrevFrame(:) - NextFrame(:)).^2));
    
    % Skin detection using YCbCr color space
    ycbcr = rgb2ycbcr(rgbFrame);
    Cb = ycbcr(:,:,2);
    Cr = ycbcr(:,:,3);
    skinMask = (Cb >= 77 & Cb <= 127) & (Cr >= 133 & Cr <= 173);
    
    % Clean the skin mask
    skinMask = medfilt2(skinMask, [5 5]);
    skinMask = imfill(skinMask, 'holes');
    skinMask = bwareaopen(skinMask, 200);  % Remove small objects

    % Final condition: motion + skin must be present
    if Dist > 2000 && nnz(skinMask) > 1000
        msg = 'Human motion detected';
        sound(y);  % Play gong sound
    else
        msg = 'No human motion';
    end

    % Show frame with message
    imshow(rgbFrame);
    title(msg);
    drawnow;

    PrevFrame = NextFrame;  % Update for next comparison
end

clear cam;  % Turn off camera
