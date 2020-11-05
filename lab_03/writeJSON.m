function writeJSON(js, filepath)
    
    str = jsonencode( js );

    raw = char(str);

    fid = fopen(filepath, 'w'); 
    fwrite(fid,raw); 
    fclose(fid); 
end

