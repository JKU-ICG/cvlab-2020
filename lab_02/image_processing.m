% --- Image Processing Toolbox Tutorial ---
clear; close all; clc; % clean up!

%% Load and Display an Image
I = imread('data/pillsetc.png'); % Read and load image in the workspace
size(I) % display the image size

figure(1); % Create new figure
imshow(I); % Display the loaded image 


%% Convert color image to grayscale

if(size(I,3) == 3) % Color image has 3 color channels
    G = rgb2gray(I); % Color image converted to grayscale image 
else
    G = I;
end
figure(2); %Generate a new figure
subplot(1,2,1); imshow(I); title( 'color' );
subplot(1,2,2); imshow(G); title( 'grayscale' );

size(G) % display the image size

% Note: Images can also be converted also be converted to other colorspaces 
% for example rgb to xyz colorspace using rgb2xyz()
% see https://www.mathworks.com/help/images/color.html

%% analyse image distribution with a histogram

figure(3); %Generate a new figure
subplot(2,2,1); imshow(G); % show the image
subplot(2,2,2); imhist(G); % show its histogram
%% histogram equalization

E = histeq(G);
subplot(2,2,3); imshow(E); % equalized image
subplot(2,2,4); imhist(E); % equalized histogram
% Note: the image intensities are concentrated and not evenly spread in the
% original image. We perform histogram equalization which spreads out the 
% luminance values in the histogram.

%% Export the processed image
if ~exist( 'results', 'dir' ), mkdir( 'results' ); end;
imwrite (E, 'results/pillsetc_g_histeq.png');

%% Geometric operations
resized = imresize(G, 0.25); % resize an image to quater resolution
size(resized) % display the resized image size

rotated = imrotate(G, 90); % rotate the image by 90?

cropped = imcrop(G, [20 20 99 99]); % crop a subregion of the image
size(cropped) % display the resized image size

figure(4); % generate a new figure
subplot(2,2,1); imshow(G); title('original image');
subplot(2,2,2); imshow(resized); title('resized image');
subplot(2,2,3); imshow(rotated); title('rotated image');
subplot(2,2,4); imshow(cropped); title('cropped image');

%% Salt and Pepper noise
saltAndPepper = imnoise(G, 'salt & pepper', 0.125);
figure(5); % Generate a new figure
subplot(1,2,1); imshow(G); title('input image');
subplot(1,2,2); imshow(saltAndPepper); title('Salt and pepper on image');

%% Convolution - Gaussian Kernel
% Convolution is mathematical operation on two functions.
% For image processing one functions is the image, 
% while the other is the 'kernel'.
% A common kernel is the Gaussian function 
kernelSize = 13;
sigma = 2;
K = fspecial('gaussian',kernelSize,sigma);
figure(7);
imshow(K, []); title('Gaussian'); % show as image

%% Manual Gaussian Kernel
% Lets now compute our own manual gaussian kernel
ksHalf = floor( kernelSize / 2 );
x = linspace(-ksHalf,ksHalf,kernelSize);
[Y,X] = meshgrid(x,x);
manualK = exp( - ((X.^2)+(Y.^2))/(2*sigma^2));
manualK = manualK / sum(manualK(:)); % normalize
h_fig = figure(8); clf; set( h_fig, 'Color', 'white' ); %Generate a new figure
subplot(1,2,1); surface(X,Y,manualK, 'FaceColor', 'interp' ); view(3); title('manual Gaussian');
subplot(1,2,2); imshow(manualK, []); title('manual Gaussian'); 

%% Convolution
% Convolve Gaussian kernel with our image iteratively
F1 = imfilter(saltAndPepper, K, 'replicate'); 
F2 = imfilter(F1, K, 'replicate');
F3 = imfilter(F2, K, 'replicate');
figure(9); %Generate a new figure and display:
subplot(2,2,1); imshow(saltAndPepper); title('Salt and pepper added noisy image ');
subplot(2,2,2); imshow(F1); title('Gaussian filtered');
subplot(2,2,3); imshow(F2); title('2x Gaussian');
subplot(2,2,4); imshow(F3); title('3x Gaussian');

%% Image Filtering - Edge detection
sobel = edge(G, 'Sobel');
canny = edge(G, 'Canny');
laplace = edge(G, 'log');

figure(10); %Generate a new figure
subplot(2,2,1); imshow(G); title('original image');
subplot(2,2,2); imshow(sobel); title('Sobel');
subplot(2,2,3); imshow(canny); title('Canny');
subplot(2,2,4); imshow(laplace); title('Laplacian of Gaussian');

% Note: other operators can be found at: https://de.mathworks.com/help/images/image-analysis.html

%% Fourier Space transformation

% apply a 2D Fourier transformation on grayscale images
G_  = fft2(G);
N_  = fft2(saltAndPepper);
F1_ = fft2(F1);

% display
figure(11);
subplot(2,3,1); imshow(G); title('original image');
subplot(2,3,2); imshow(saltAndPepper); title('noise');
subplot(2,3,3); imshow(F1); title('filtered');
% the fourier domain is complex, thus we only display the magnitutes (abs)
% and we show it logarithmically (log) because the highest peak is always the
% zero frequency (in the center):
subplot(2,3,4); imshow(log(abs(fftshift(G_))), [0 17]);  title('Fourier space');
subplot(2,3,5); imshow(log(abs(fftshift(N_))), [0 17]);  title('Fourier space');
subplot(2,3,6); imshow(log(abs(fftshift(F1_))),[0 17]); title('Fourier space');


%% Further examples and readings
% For further examples and details see https://www.mathworks.com/help/images/index.html
