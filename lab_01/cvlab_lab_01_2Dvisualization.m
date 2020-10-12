%Plot Line Plot Using Plot (xaxis, yaxis) 
xax = linspace(0,2*pi,100)
yax = sin(xax)
plot(xax,yax)
%Hold on to draw more and overlap with Existing Picture
hold on
slp = cos(xax)
plot(xax,slp, '--ro')
hold off
% Labels
xlabel('x')
ylabel('f(x)')
title('plotting functions of x')
% SubPlotting With subplots (row,column, index)
figure
subplot(1,2,1);plot(xax,yax);
subplot(1,2,2);plot(xax,slp, 'LineWidth',3);
