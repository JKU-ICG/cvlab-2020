function [js] = readJSON(filepath)
%READJSON read a json file and return it as Matlab structure.
%  
    fid = fopen(filepath, 'r'); 
    raw = fread(fid,inf); 
    str = char(raw'); 
    fclose(fid); 
    
    js = jsondecode(str);
end

