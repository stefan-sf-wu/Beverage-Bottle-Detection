%% Resize Single image
fprintf("Resize Single image data\n");
imds = imageDatastore('TeraData\Single');
parfor i = 1 : size(imds.Files, 1)
    img = imread(imds.Files{i});
    [x,y,~] = size(img);
    if x > y
        ratio = 227 / x;
    else
        ratio = 227 / y;
    end
    timg = zeros(227, 227, 3, 'uint8');
    img = imresize(img,[x y] * ratio);
    [x,y,~] = size(img);
    timg(1:x, 1:y, :) = img;
    s = split(imds.Files{i},'\');
    imwrite(timg, ['TeraData\Smod\' s{end}]);
end
clear
%% Resize Double image
fprintf("Resize Double image data\n");
imds = imageDatastore('TeraData\Double');
did = randperm(size(imds.Files, 1), round(size(imds.Files, 1) * 0.75));
imds.Files = imds.Files(did);
parfor i = 1 : size(imds.Files, 1)
    img = imread(imds.Files{i});
    [x,y,~] = size(img);
    if x > y
        ratio = 227 / x;
    else
        ratio = 227 / y;
    end
    timg = zeros(227, 227, 3, 'uint8');
    img = imresize(img,[x y] * ratio);
    [x,y,~] = size(img);
    timg(1:x, 1:y, :) = img;
    s = split(imds.Files{i},'\');
    imwrite(timg, ['TeraData\Dmod\' s{end}]);
end
clear
%%  Load Single Object Data
fprintf("loading Single data\n");
imds = imageDatastore('TeraData\Smod');
labels = cell(size(imds.Files));
coord = cell(size(imds.Files));
parfor i = 1 : length(imds.Files)
    s = strsplit(string(imds.Files(i)), "\");
    s = strsplit(s(length(s)), ".");
    s = strcat("TeraData\SingleLabel\", s(1), ".txt");
    [coord{i}, labels(i)] = loadLabel(s, true);
end
imds.Labels = categorical(labels);
labels = categories(imds.Labels);
%% AlexNet Transfer Learning
net = alexnet;
layersTransfer = net.Layers(1:end-3);
numClasses = numel(categories(imds.Labels));
layers = [
    layersTransfer
    fullyConnectedLayer(numClasses,'WeightLearnRateFactor',20,'BiasLearnRateFactor',20)
    softmaxLayer
    classificationLayer];

options = trainingOptions('sgdm', ...
    'MiniBatchSize',10, ...
    'MaxEpochs',12, ...
    'InitialLearnRate',1e-4, ...
    'Shuffle','every-epoch', ...
    'Verbose',false, ...,
    'LearnRateSchedule','piecewise', ...
    'LearnRateDropFactor',0.1, ...
    'LearnRateDropPeriod',4, ...
    'Plots','training-progress');

netTransfer = trainNetwork(imds,layers,options);
save netTransfer;
%%  Load Labels
clear
fprintf("loading Single Label\n");
imds = imageDatastore('TeraData\Single');
labels = cell(size(imds.Files));
parfor i = 1 : length(imds.Files)
    s = strsplit(string(imds.Files(i)), "\");
    s = strsplit(s(length(s)), ".");
    s = strcat("TeraData\SingleLabel\", s(1), ".txt");
    [~, labels(i)] = loadLabel(s, true);
end
tlabels = categories(categorical(labels));
%%  Load Single Object Data
fprintf("loading Single data\n");
imds = imageDatastore('TeraData\SPmod');
labels = cell(size(imds.Files));
coord = cell(size(imds.Files));
parfor i = 1 : length(imds.Files)
    s = strsplit(string(imds.Files(i)), "\");
    s = strsplit(s(length(s)), ".");
    s = strcat("TeraData\SingleLabel\", s(1), ".txt");
    [coord{i}, labels(i)] = loadLabel(s, true);
end
imds.Labels = categorical(labels);
labels = categories(imds.Labels);
%% load Double Object Data
fprintf("loading Double data\n");
double_imds = imageDatastore('TeraData\Dmod');
double_labels = cell(size(double_imds.Files));
double_coord = cell(size(double_imds.Files));
parfor i = 1 : length(double_imds.Files)
    s = strsplit(string(double_imds.Files(i)), "\");
    s = strsplit(s(length(s)), ".");
    s = strcat("TeraData\DoubleLabel\", s(1), ".txt");
    [double_coord{i}, double_labels{i}] = loadLabel(s, false);
end
%% Resize image
[x,y,~] = size(imread('TeraData\Single\B100_IMG_6110.jpg'));
if x > y
    ratio = 227 / x;
else
    ratio = 227 / y;
end
%%
parfor i = 1 : size(imds.Files, 1)
   coord{i} = round(coord{i} * ratio + [0.5 0.5 0 0]);
end
%%
parfor i = 1 : size(double_imds.Files, 1)
    double_coord{i}{1} = round(double_coord{i}{1} * ratio + [0.5 0.5 0 0]);
    double_coord{i}{2} = round(double_coord{i}{2} * ratio + [0.5 0.5 0 0]);
end
%% show
for i = 1 : 100
   imshow(insertShape(insertShape(imread(double_imds.Files{i}), 'Rectangle', double_coord{i}{2}, 'LineWidth', 5), 'Rectangle', double_coord{i}{1}, 'LineWidth', 5));
   imshow(insertShape(imread(imds.Files{i}), 'Rectangle', coord{i}, 'LineWidth', 5));
end
%% Configuring Training option
options = trainingOptions('sgdm', ...
    'MaxEpochs', 8, ...
    'MiniBatchSize', 8, ...
    'InitialLearnRate', 1e-5);
%% Load combine Ground Truth data
data = cell2table(cell(length(imds.Files) + length(double_imds.Files), size(tlabels, 1) + 1) ,'VariableNames', ['imageFilename' tlabels']);
data.imageFilename(1:length(imds.Files)) = imds.Files;
data.imageFilename(length(imds.Files) + 1 : end) = double_imds.Files;

for i = 1:length(imds.Files)
    data{i, string(imds.Labels(i))} = coord(i);
end

for i = 1:length(double_imds.Files)
    data{length(imds.Files) + i, string(double_labels{i}{1})} = double_coord{i}(1);
    data{length(imds.Files) + i, string(double_labels{i}{2})} = double_coord{i}(2);
end
data = data(randperm(size(data, 1)), :);
%% Double Ground Truth data
data = cell2table(cell(length(double_imds.Files), size(tlabels, 1) + 1) ,'VariableNames', ['imageFilename' tlabels']);
data.imageFilename = double_imds.Files;

for i = 1:length(double_imds.Files)
    data{i, string(double_labels{i}{1})} = double_coord{i}(1);
    data{i, string(double_labels{i}{2})} = double_coord{i}(2);
end
data = data(randperm(size(data, 1)), :);

%% Single Ground Truth data
data = cell2table(cell(length(imds.Files), size(labels, 1) + 1) ,'VariableNames', ['imageFilename' labels']);
data.imageFilename(1:length(imds.Files)) = imds.Files;

for i = 1:length(imds.Files)
    data{i, string(imds.Labels(i))} = coord(i);
end

data = data(randperm(size(data, 1)), :);
%% Training
load detector.mat
[detector, info] = trainFasterRCNNObjectDetector(data, detector, options);

%% Test for the Average Accuracy
fprintf('Testing for the Aver. accuracy\n');

numImages = height(mixed_testData);
results = table('Size',[numImages 3],...
                'VariableTypes',{'cell','cell','cell'},...
                'VariableNames',{'Boxes','Scores','Labels'});
    
    % Run detector on each image in the test set and collect results.
for i = 1:numImages
        
    % Read the image.
    I = zeros(227,227,3,'uint8');
    I(1:170, 1:227, :) = imresize(imread(mixed_testData.path{i}), [170 227]);
        
    % Run the detector.
    [bboxes, scores, labels] = detect(detector, I);
        
    % Collect the results.
    % Collect the results.
    results.Boxes{i} = bboxes;
    results.Scores{i} = scores;
    results.Labels{i} = labels;
end

% Extract expected bounding box locations from test data.
expectedResults = mixed_testData(:, 2:end);

% Evaluate the object detector using Average Precision metric.
[ap, recall, precision] = evaluateDetectionPrecision(results, expectedResults);

% Plot precision/recall curve
figure
plot(recall, precision)
xlabel('Recall')
ylabel('Precision')
grid on
title(sprintf('Average Precision = %.2f', ap))