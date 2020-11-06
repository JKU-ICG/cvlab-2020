function writeJSON(js, filepath)
% write a structure to a json file
    
    str = jsonencode( js );

    raw = char(str);

    fid = fopen(filepath, 'w'); 
    fwrite(fid,raw); 
    fclose(fid); 
end

