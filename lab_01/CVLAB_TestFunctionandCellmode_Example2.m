%CVLAB:-Test Function
%--'%'is used to add comments
clear ;%clear workspace
close all;%close all windows
%'%%' creates new section
%each section can be executed independently
%%
%calculate area of triangle
bs = 6;%base
ht = 3;%height
ar = 0.5*(bs*ht);
%%
ar1 = cta(5,3);
ar2 = cta(12,4);
ar3 = cta(2,1);
%%
%Control flow
%Loops and decision statements
for i= 1:1:24
    for j = 1:1:24
        ar_c = cta(i,j);
        if(ar_c == 24)
            fprintf('base%d and height%d\n',i,j);
        else
            fprintf('Area not equal to 24\n');
        end
    end
end
