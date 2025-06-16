%% Heavy Traffic detector
clc;
clear;

%% ----- STEP 1: Load Video -----

videoFile = 't1.mp4';  % <-- Your 30-sec video file
videoReader = VideoReader(videoFile);
frameRate = videoReader.FrameRate;

% Output video writer for demo
outputVideo = VideoWriter('tracking_demo.avi');
open(outputVideo);

%% ----- STEP 2: Foreground Detection -----
foregroundDetector = vision.ForegroundDetector( ...
    'NumGaussians', 3, ...
    'NumTrainingFrames', 30, ... % faster learning
    'LearningRate', 0.01);

% Area threshold for heavy vehicles (from previous analysis)
heavyAreaThreshold = 10000;

%% ----- STEP 3: Tracking Setup -----
tracker = [];  % Will store struct with fields: id, centroid, age
nextID = 1;
maxDistance = 50;  % Max distance to consider same object

% Count only unique vehicles that crossed a virtual line
countedIDs = [];
heavyCount = 0;

% Virtual line y-coordinate
lineY = 200;

%% ----- STEP 4: Process Video Frames -----
while hasFrame(videoReader)
    frame = readFrame(videoReader);

    % Detect foreground mask
    fgMask = step(foregroundDetector, frame);

    % Clean mask
    fgMask = imopen(fgMask, strel('rectangle', [5,5]));
    fgMask = imclose(fgMask, strel('rectangle', [15,15]));
    fgMask = imfill(fgMask, 'holes');

    % Extract connected components
    stats = regionprops(fgMask, 'Area', 'Centroid', 'BoundingBox');

    detections = [];
    for i = 1:length(stats)
        if stats(i).Area > heavyAreaThreshold
            detections = [detections; stats(i)];
        end
    end

    % Track using centroid matching
    % Track using centroid matching
if ~isempty(detections)
    currentCentroids = cat(1, detections.Centroid);
else
    currentCentroids = [];
end

    updatedTracker = [];
    matched = zeros(length(detections), 1);

    for t = 1:length(tracker)
        minDist = inf;
        bestMatch = -1;
        for d = 1:length(detections)
            dist = norm(tracker(t).centroid - detections(d).Centroid);
            if dist < minDist && dist < maxDistance
                minDist = dist;
                bestMatch = d;
            end
        end
        if bestMatch > 0
            tracker(t).centroid = detections(bestMatch).Centroid;
            tracker(t).age = 0;
            updatedTracker = [updatedTracker; tracker(t)];
            matched(bestMatch) = 1;

            % Check if crossing line and not already counted
            if tracker(t).centroid(2) < lineY && ~ismember(tracker(t).id, countedIDs)
                heavyCount = heavyCount + 1;
                countedIDs = [countedIDs, tracker(t).id];
            end
        else
            tracker(t).age = tracker(t).age + 1;
            if tracker(t).age < 5  % Keep unmatched trackers briefly
                updatedTracker = [updatedTracker; tracker(t)];
            end
        end
    end

    % Add new detections as new tracked objects
    for d = 1:length(detections)
        if ~matched(d)
            newTrack.id = nextID;
            newTrack.centroid = detections(d).Centroid;
            newTrack.age = 0;
            updatedTracker = [updatedTracker; newTrack];
            nextID = nextID + 1;
        end
    end
    tracker = updatedTracker;

    % Draw results
    for i = 1:length(detections)
        box = detections(i).BoundingBox;
        frame = insertShape(frame, 'Rectangle', box, 'Color', 'red', 'LineWidth', 2);
        frame = insertText(frame, box(1:2), 'Heavy', 'BoxColor', 'red', 'TextColor', 'white');
    end
    for i = 1:length(tracker)
        frame = insertMarker(frame, tracker(i).centroid, 'x', 'Color', 'blue', 'Size', 10);
        frame = insertText(frame, tracker(i).centroid, sprintf('#%d', tracker(i).id), ...
            'BoxColor', 'blue', 'TextColor', 'white');
    end

    % Draw counting line
    frame = insertShape(frame, 'Line', [0, lineY, size(frame,2), lineY], 'Color', 'green', 'LineWidth', 2);
    frame = insertText(frame, [10 10], sprintf('Heavy Count: %d', heavyCount), ...
        'FontSize', 16, 'BoxColor', 'black', 'TextColor', 'white');

    % Show and save frame
    imshow(frame);
    drawnow;
    writeVideo(outputVideo, frame);
end

close(outputVideo);

%% ----- STEP 5: Accuracy -----
manualCount = input('Enter manual count of heavy vehicles (ground truth): ');
accuracy = (manualCount / heavyCount) * 100;

fprintf('\n==== Results ====\n');
fprintf('Manual count (ground truth): %d\n', manualCount);
fprintf('Automatic heavy vehicle count: %d\n', heavyCount);
fprintf('Accuracy: %.2f%%\n', accuracy);
fprintf('Output demo video saved as: tracking_demo.avi\n');
