clc, clear, close all;

image = imread('scenarios/wheresWaldo3.jpg');
ref = imread('references/waldo1.jpg');
[ih, iw, ~] = size(image);
[rh, rw, ~] = size(ref);

imageHsv = rgb2hsv(image);
h = imageHsv(:, :, 1);
s = imageHsv(:, :, 2);
v = imageHsv(:, :, 3);

% Segment using color
redStripes = ((h < 0.01) | (h > 0.9)) & (s > 0.7) & (v > 0.7);
whiteStripes = (s < 0.2) & (v > 0.9);

% Create vertical (90 degree) linear structuring element
se = strel('line', ih * 0.01, 90);

% Dilate the stripes vertically
redDilated = imdilate(redStripes, se);
whiteDilated = imdilate(whiteStripes, se);

% Get their overlapped area
roi = redDilated & whiteDilated;
figure,imshow(roi), title('Segmentação por tiras vermelhas e brancas.');

% Remove smaller or bigger components that are not Waldo
roi = bwareaopen(roi, floor((ih * iw)/185^2));
roi = imdilate(roi, se);
roi = bwareaopen(roi, 20);
bigger = bwareaopen(roi, floor((ih * iw)/23^2));
roi = roi - bigger;
figure,imshow(roi), title('Remoção de elementos menores que o Waldo.');

% Purify Wally
roi = roi & (redStripes | whiteStripes);
roi = imdilate(roi, se);
roi = bwareaopen(roi, 10);
figure,imshow(roi), title('Dilatação e abertura de elementos restantes.');

% Find Wally through normalized cross correlation
roi = logical(roi);
c = regionprops(roi, 'Centroid');
centroids = cat(1, c.Centroid);

locus_x = round(centroids(:,2));
locus_y = round(centroids(:,1));

x = size(centroids);
sizeref = size(ref);
ref = rgb2gray(ref);

refPoints = detectSURFFeatures(ref);
[refFeatures, refPoints] = extractFeatures(ref, refPoints);

%figure;
%imshow(ref);
%title('10 Strongest Feature Points from Box Image');
%hold on;
%plot(selectStrongest(refPoints, 10));

image = rgb2gray(image);
for i = 1:x(1)
    slice = image(max(1, locus_x(i)-100):min(ih, locus_x(i)+100), max(1, locus_y(i)-100):min(iw, locus_y(i)+100));
    sizeslice = size(slice);
    slicePoints = detectSURFFeatures(slice);
    
    %figure;
    %imshow(slice);
    %title('100 Strongest Feature Points from Scene Image');
    %hold on;
    %plot(selectStrongest(slicePoints, 100));
    %hold off;
    
    [sliceFeatures, slicePoints] = extractFeatures(slice, slicePoints);
    
    refPairs = matchFeatures(refFeatures, sliceFeatures);
    
    matchedRefPoints = refPoints(refPairs(:, 1), :);
    matchedSlicePoints = slicePoints(refPairs(:, 2), :);
    
    %figure;
    %imshow(slice);
    %title('10 Strongest Feature Points from Slice Image');
    %hold on;
    %plot(selectStrongest(slicePoints, 10));

    %figure;
    %showMatchedFeatures(ref, slice, matchedRefPoints, ...
    %    matchedSlicePoints, 'montage');
    %title('Putatively Matched Points (Including Outliers)');
    
    if sizeslice(1) >= sizeref(1) && sizeslice(2) >= sizeref(2)
        C = normxcorr2(ref,slice);
        tmp = max(abs(C(:)));
        if ~exist('cmax','var')
            cmax = tmp;
            coords = [locus_x(i), locus_y(i)];
            %figure,imshow(slice)
            %figure,imshow(C);
        elseif cmax < tmp
            cmax = tmp;
            coords = [locus_x(i), locus_y(i)];
            %figure,imshow(slice);
            %figure,imshow(abs(C));
        end
    end
    %figure,imshow(slice);
    
end
figure,imshow(image)
hold on
plot(centroids(:,1),centroids(:,2),'b*');
rectangle('Position', [coords(2)-50, coords(1)-50, 100, 100], 'LineWidth', 3);
hold off

figure,imshow(image(max(1,coords(1)-100):min(ih, coords(1)+100), max(1,coords(2)-100):min(iw, coords(2)+100)));