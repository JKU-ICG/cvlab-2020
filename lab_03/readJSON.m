function [js] = readJSON(filepath)
%READJSON Summary of this function goes here
%   Detailed explanation goes here
    fid = fopen(filepath, 'r'); 
    raw = fread(fid,inf); 
    str = char(raw'); 
    fclose(fid); 
    
    js = jsondecode(str);
end

