%% Autores:
% Breno Vinicius Viana de Oliveira - 726498 (1)
% Gabriel Rodrigues Rocha          - 726518 (2)
% Henrique Shinki Kodama           - 726537 (3)
%
% Contato
% (1) breno.oliveira@dcomp.sor.ufscar.br
% (2) gabrielrocha.comp@gmail.com
% (3) hskodama@gmail.com

%% �nicio
% Limpeza do ambiente
clc, clear, close all;

%% Abertura das imagens
scenario = 'scenarios/wheresWaldo1.jpg';
reference = dir('references/*.jpg');

% Imagem cen�rio
image = imread(scenario);
[ih, iw, ~] = size(image);

% Imagens de refer�ncia
files = {reference.name};
ref = cell(1,numel(files));
for k=1:numel(files)
    ref{k} = imread(strcat('references/',files{k}));
    ref{k} = rgb2gray(ref{k});
end

% Obten��o do tamanho do Waldo
waldo_size = 0;
for k = 1:numel(ref)
    waldo_size = waldo_size + mean(size(ref{k}))/numel(ref);
end

% Convers�o da imagem cen�rio de RGB para HSV
imageHsv = rgb2hsv(image);
h = imageHsv(:, :, 1);
s = imageHsv(:, :, 2);
v = imageHsv(:, :, 3);

%%
% Segmenta��o por meio de cor
redStripes = ((h < 0.01) | (h > 0.9)) & (s > 0.7) & (v > 0.9);
whiteStripes = (s < 0.2) & (v > 0.9);

%%
% Cria��o de elemento estruturante: linha vertical
se = strel('line', waldo_size * 0.15, 90);

%%
% Dilata��o das listras verticalmente
redDilated = imdilate(redStripes, se);
whiteDilated = imdilate(whiteStripes, se);

%%
% Obten��o da �rea sobreposta das listras
roi = redDilated & whiteDilated;
figure,imshow(roi), title('Segmenta��o por tiras vermelhas e brancas.');

%%
% Remo��o de elementos menores ou maiores que n�o s�o o Waldo
rg = regionprops(roi, 'Centroid');
if numel(rg) <= 10 % Tratamento de caso em que o Waldo � muito pequeno
    roi = imdilate(roi, strel('square', round(waldo_size * 0.1)));
end
roi = bwareaopen(roi, floor(waldo_size * 0.9));
roi = imdilate(roi, se);
roi = bwareaopen(roi, 20);
bigger = bwareaopen(roi, floor(25 * waldo_size));
roi = roi - bigger;
figure,imshow(roi), title('Remo��o de elementos menores que o Waldo.');

%%
% Remo��o de ru�do dos objetos resultantes
roi = roi & (redStripes | whiteStripes);
roi = imdilate(roi, strel('square', round(waldo_size * 0.1)));
roi = bwareaopen(roi, 12);
figure,imshow(roi), title('Dilata��o e abertura de elementos restantes.');

%%
% Obten��o dos centroides da imagem
roi = logical(roi);
c = regionprops(roi, 'Centroid');
centroids = cat(1, c.Centroid);
locus_x = round(centroids(:,2));
locus_y = round(centroids(:,1));

x = size(centroids);
sizeref = size(ref);

%%
% Busca por Waldo atrav�s de itera��o e correla��o cruzada normalizada
color_image = image;
image = rgb2gray(image);

for i = 1:x(1)
    % Obten��o de um peda�o de interesse
    slice = image(max(1, locus_x(i)-100):min(ih, locus_x(i)+100), max(1, locus_y(i)-100):min(iw, locus_y(i)+100));
    sizeslice = size(slice);
    
    % Certifica��o de que o peda�o � maior que a imagem refer�ncia
    tmp = zeros(1,numel(ref));
    for k = 1:numel(ref)
        sizeref = size(ref{k});
        if sizeslice(1) >= sizeref(1) && sizeslice(2) >= sizeref(2)
            C = normxcorr2(ref{k},slice); % Correla��o normalizada cruzada
            tmp(k) = max(C(:)); % Ponto de m�ximo
        end
    end
    
    if ~exist('cmax','var') % Caso em que nada foi calculado ainda
        cmax = tmp;
    	coords = [locus_x(i), locus_y(i)];
    elseif sum(cmax) < sum(tmp) % Caso em que um ponto maior que o maior anterior foi obtido
        cmax = tmp;
        coords = [locus_x(i), locus_y(i)];
    end
    
end

%%
% Todos os centroides e a regi�o em que Waldo se encontra
figure,imshow(color_image),title('Centroides da imagem e Waldo.');
hold on
plot(centroids(:,1),centroids(:,2),'b*');
rectangle('Position', [coords(2)-50, coords(1)-50, 100, 100], 'LineWidth', 3);
hold off
%%
% Imagem ampliada de Waldo na imagem cen�rio
waldo = color_image(max(1,coords(1)-100):min(ih, coords(1)+100), max(1,coords(2)-100):min(iw, coords(2)+100), :);
figure,imshow(waldo), title('Waldo!');