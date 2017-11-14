clc, clear, close all;

image = imread('scenarios/wheresWaldo2.jpg');
ref = imread('references/waldo2.jpg');
[ih, iw, ~] = size(image);

imageHsv = rgb2hsv(image);
h = imageHsv(:, :, 1);
s = imageHsv(:, :, 2);
v = imageHsv(:, :, 3);

% Segment using color
redStripes = ((h < 0.05) | (h > 0.9)) & (s > 0.7) & (v > 0.8);
whiteStripes = (s < 0.2) & (v > 0.9);

% Create vertical (90 degree) linear structuring element
se = strel('line', ih * 0.01, 90);

% Dilate the stripes vertically
redDilated = imdilate(redStripes, se);
whiteDilated = imdilate(whiteStripes, se);

% Get their overlapped area
roi = redDilated & whiteDilated;
figure,imshow(roi), title('Segmentação por tiras vermelhas e brancas.');

% Remove smaller or bigger components that are not Wally
roi = bwareaopen(roi, floor(ih/85 * iw/85));
bigger = bwareaopen(roi, floor(ih/50 * iw/50));
roi = roi - bigger;
figure,imshow(roi), title('Remoção de elementos menores que o Wally.');

% Purify Wally
roi = roi & (redStripes | whiteStripes);
roi = imdilate(roi, se);
roi = bwareaopen(roi, 10);
figure,imshow(roi), title('Dilatação e abertura de elementos restantes.');

% Find Wally throught normalized cross correlation
roi = logical(roi);
c = regionprops(roi, 'Centroid');
centroids = cat(1, c.Centroid);
figure,imshow(image)
hold on
plot(centroids(:,1),centroids(:,2),'b*');
hold off

locus_x = round(centroids(10,2));
locus_y = round(centroids(10,1));

slice = image(locus_x-100:locus_x+100, locus_y-100:locus_y+100);
ref = rgb2gray(ref);
H = vision.TemplateMatcher;

LOC = step(H, slice, ref);

C = normxcorr2(ref,slice);