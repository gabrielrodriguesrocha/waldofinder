clc, clear, close all;

image = imread('scenarios\wheresWaldo4.jpg');
ref = imread('references\waldo2.jpg');
[ih, iw, ~] = size(image);
[rh, rw, ~] = size(ref);

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
figure,imshow(roi), title("Segmenta��o por tiras vermelhas e brancas.");

% Remove smaller or bigger components that are not Wally
roi = bwareaopen(roi, floor((ih * iw)/185^2));
roi = imdilate(roi, se);
roi = bwareaopen(roi, 20);
bigger = bwareaopen(roi, floor((ih * iw)/23^2));
roi = roi - bigger;
figure,imshow(roi), title("Remo��o de elementos menores que o Wally.");

% Purify Wally
roi = roi & (redStripes | whiteStripes);
roi = imdilate(roi, se);
roi = bwareaopen(roi, 10);
figure,imshow(roi), title("Dilata��o e abertura de elementos restantes.");

% Find Wally through normalized cross correlation
roi = logical(roi);
c = regionprops(roi, 'Centroid');
centroids = cat(1, c.Centroid);

locus_x = round(centroids(:,2));
locus_y = round(centroids(:,1));

x = size(centroids);
sizeref = size(ref);
ref = rgb2gray(ref);

for i = 1:x(1)
    slice = image(max(1, locus_x(i)-100):min(iw, locus_x(i)+100), max(1, locus_y(i)-100):min(ih, locus_y(i)+100));
    sizeslice = size(slice);
    if sizeslice(1) >= sizeref(1) && sizeslice(2) >= sizeref(2)
        C = normxcorr2(ref,slice);
        tmp = max(C(:));
        if ~exist('cmax','var')
            cmax = tmp;
            coords = [locus_x(i), locus_y(i)];
        elseif cmax < tmp
            cmax = tmp;
            coords = [locus_x(i), locus_y(i)];
        end
    end
end
figure,imshow(image)
hold on
plot(centroids(:,1),centroids(:,2),'b*');
rectangle('Position', [coords(2)-50, coords(1)-50, 100, 100], 'LineWidth', 3);
hold off

figure,imshow(image(max(1,coords(1)-100):min(iw, coords(1)+100), max(1,coords(2)-100):min(ih, coords(2)+100)));