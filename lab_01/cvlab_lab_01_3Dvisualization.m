%Matlab 3D Visualization -- Image Generation
x = -10:0.5:10
y = -10:0.5:10
[X Y] = meshgrid(x,y);
Z = sin(sqrt(X.^2+Y.^2)) ./ sqrt(X.^2+Y.^2) ;
figure; surfc(X,Y,Z)
view(-38,18)
figure
image(Z);colorbar;
imagesc(Z);colorbar;
