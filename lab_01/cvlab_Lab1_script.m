%Graphical User Interface
%Get Familiar With Matlab GUI -- Working Directory, CommandWindow,
%Workspace and Editor
%%
%Matlab as a calculator
%Enter Command in Command Window
%Execute Command and Statement in Command Window By Pressing Enter after
%the command or statement
%Check Display Similiar to Calculator
5
%Check Some Arithmetic Expressions in Matlab
5+7
23.5-35.6
3.14*4
3/2
%Change how matlab display Floating numbers using the command format. For
%Ex:- To Format long
format long
% Now Check How Floating Numbers are Displayed
3/2
%Similarly Check short  scientific format 
format short e
3/2
%Revert Back to Default 
format
%Get More Info About Any Command
%help commandname  
help format
%Visualize Matlab Documentation Of Command
%doc commandname
doc format
%%
%Upper Case and Lower Case are Different Variables i.e Variable Name are
%Case Sensitive
A = 5
a = 10
%Variables name should start with letters only and then can be 
%followed by letters, digits or underscores. 
%X54_K = 4 is valid however 5X4 = 6 is not.
X54_k = 4
5X4 = 6
%Maximum Length of Variable Name
namelengthmax
%Check Variable Name is Keyword 
iskeyword('X54_k')
%Check Key Word List 
iskeyword
%Check Variable Name is Valid
isvarname('X54_k')
%Check If Variable Name Exist
exist X54_k
%New Version of Addressing Commands
exist('X54_k')
%Standard Value Variables
eps
pi
inf
%Delete Particular Variable
%clear varname 
clear X54_k
%Delete All Variable
clear
%%
%Matrices and arrays
%1D Vector
x = [0,0.1*pi,0.2*pi,0.3*pi,0.4*pi,0.5*pi,0.6*pi,0.7*pi,0.8*pi,0.9*pi, pi]
x = [0  0.1*pi 0.2*pi 0.3*pi 0.4*pi 0.5*pi 0.6*pi 0.7*pi 0.8*pi 0.9*pi pi]
%Regularly Spaced 1 D Vector 
x = [0:0.1:1]*pi
%Matlab 1D array Adrressing Starts with 1
x(1)
%Matrices -- Concanate Rows With Semicolon 
x = [0  0.1*pi]
x = [0  0.1*pi; 0.2*pi 0.3*pi]
x = [0  0.1*pi; 0.2*pi 0.3*pi; 0.4*pi 0.5*pi; 0.6*pi 0.7*pi; 0.8*pi 0.9*pi; pi 2*pi]
%Also Concanate Rows Using Command Vertcat
vertcat(x,[3*pi 4*pi]) 
%2D Array Addressing System (row,column) 
x(1,2)
x(3,1)
%%
%Matrices and arrays Operators -- Semicolon, Colon, Transpose
%Semicolon Operator to Suppress Output
vertcat(x,[3*pi 4*pi]) ;
x(3,1)*4
x(3,1)/4;
%Colon Operator Usages -- generate Vector, Access SubArrays and Matrices
y = 1.3:0.1:2.8
y(3:8) 
x(3:5,:) 
x(:,2) = 1
%delete them using a blank square brackets Show 5th example.
x(5,:) = []
%Colon Operator Usages -- Reshape to Column, Row Vector
cv = x(:)
rv = x(1:end)
%Transpose Operator -- Column to Row Transpose   
cvt = x(:)'
%%
%Matrices and arrays functions
%Linspace -- Generate Linear spaced Vector with defined number of Elements
lsv = linspace(3,5,20)
%LogSpace -- Generate Logarahmic spaced Vector with defined number of Elements 
losv =logspace(0,2,4)
%Matrix Filled With Zeros
zsm = zeros(4)
%Vector Filled With Ones 
oa = ones(1,3)
%Identity Matrix
em = eye(2)
%Repeteative Matrix Using repmat
rm = repmat([1 2; 3 4],2,3)
%Reshape AMtrix using reshape 
rsm = reshape(rm, 2,12) 
%%
%Matrices and arrays Operations
%Matrix Operators -- Following Linear Algebrea Rules 
A = [1 2 3; 3  4 6; 7 8 9] 
B = ones(3)
NU = eye(3,4)
A+B
A-B
A*B
B*NU
A-1
A+NU
B-NU
NU*A
%Array Operators -- Dot Preceeding Operators With elementwise operations.
%Works With Both Array and Matrices
DA = [ 1 2 3 4]
EA = ones(1,4)*12
DA .* EA
A .* B 
%%
%Multidimensional arrays -- 3D Matrix Similiar to RGB Image
C(:,:,1) = A
C(:,:,2) = B 
C(:,:,3) = eye(3) 
%Multidimensional arrays -- 3D Addressing System, Last Index is Page Number
C(1,3,1)
%Create Sub Matrices -- Similiar to Accessing  Single Pixel Value in Image
C(2,3,:) 
%%
%Numeric Data Types -- TypeCasting
tn = 5.8
spn = single(tn)
inn = int16(tn)
%Maximum Length
inmx = intmax('uint16')
realmax('double')
realmax('single')
%%
%Text DataType -- Character and String Arrays 
chr = 'Hello, world' 
chr(3)
%String
str = "Hello, world"
str(3)
%String Advantages
str(2) = " Computer Vision Lab" 
strm = " Matlab : " + str(1) + string(pi)
str(3) = 3
%%
%Mixed Data Type -- Cell Arrays
CA= cell(3,2)
%Acess Cell With Curly Braces
CA{1,1}=[1,2]
CA{1,2}=[3,4]
CA{2,1}=[5 6;7 8]
CA{2,2}=[ 9 10 11;12 13 14]
CA{3,1}= ones(3)
CA{3,2}='Hello'
%Acess Element Within Cell With normal Brackets
CA{2,2}(1,3) 
%%
%Matlab 2D Visualization
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
%%
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
%%
% Save Workspace and Load Workspace
save('test_cvlab_export.mat')
clear
load('test_cvlab_export.mat')
