rng('default');
img = imread('./source/retina_images_01_10/1.tif');
mask = imread('./source/mask_images/1.tif');
best = im2double(imread('./source/label_images/1.tif'));
img = im2double(rgb2gray(img));
mask = double(imbinarize(mask));
img = img.*mask;        % mask the image
[rows,columns] = size(img);
subplot(2,4,1);
imshow(best);
title('best');

%% image processing
% Histogram equalization
img=adapthisteq(img);

subplot(2,4,2);
imshow(img);
title('Histogram equalization');

% High-frequency emphasis
img=fftshift(fft2(img));  
d0=20;
m=fix(rows/2);
n=fix(columns/2);
for i=1:rows
   for j=1:columns
        d = ((i-m)^2+(j-n)^2);
        high_filter(i,j)=0.5 + 1 - exp(-(d)^2/(2*(d0^2)));        
   end
end
img=img.*high_filter;
img=real(ifft2(ifftshift(img)));  

subplot(2,4,3);
imshow(img);
title('High-frequency emphasis');

% Gaussian filter
gausFilter = fspecial('gaussian',[7 7],0.9);   %��˹�˲�
img = im2double(imfilter(img,gausFilter,'replicate'));

subplot(2,4,4);
imshow(img);
title('Gaussian filter');

% loG filter
hsize = 11;
sigma = 0.29;
filter = fspecial('log', hsize, sigma);
img=double(imfilter(img, filter));

subplot(2,4,5);
imshow(img);
title('loG filter');

% Remove boundary and equalization
img = img.*mask;
img=adapthisteq(img);
subplot(2,4,6);
imshow(img);
title('Remove boundary');

% Binarization
for i = 1:rows
    for j = 1:columns
        if img(i, j) <= 0.55
            img(i, j) = 0;
        else
            img(i, j) = 1;
        end
    end
end

subplot(2,4,7);
imshow(img);
title('Binarization');

% Morphology operations
img = bwareaopen(img, 50, 4);   % delete blocks less than 50 pixels

se = strel('square',2);         % close operation
img = imclose(img,se);

filled = imfill(img, 'holes');  % fill in small holes operation
holes = filled & ~img;
bigHoles = bwareaopen(holes, 150);
smallholes = holes & ~bigHoles;
img = img | smallholes;
img = bwareaopen(img, 70, 8);

subplot(2,4,8);
imshow(img);
title('Morphology operations');

%% accuracy calculation
pixel_num = sum(mask(:));
vessel_num = sum(best(:));
background_num = pixel_num - vessel_num;

background = im2double(imcomplement(best));
background = background.*mask; 

img_reverse = imcomplement(img);
img_reverse = img_reverse.*mask;

vessel_accurate = 0;
background_accurate = 0;
for i = 1:rows
    for j = 1:columns
        if best(i, j) == 1 && img(i, j) == 1
            vessel_accurate = vessel_accurate + 1;
        end
        if background(i, j) == 1 && img_reverse(i, j) == 1
            background_accurate = background_accurate + 1;
        end
    end
end
vessel_rate = vessel_accurate/vessel_num;
background_rate = background_accurate/background_num;
total_rate = (vessel_accurate+background_accurate)/pixel_num;
fprintf("P = %f N = %f T = %f\n", vessel_rate, background_rate, total_rate);