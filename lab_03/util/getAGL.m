function agl = getAGL( sitename )
% getAGL returns the altitude above ground layer for a site specified by
% the parameter sitename
% Examples:
%   altitude = getAGL( 'F6' );

    agl = 37; % per default!
    
    if( strcmpi( sitename, 'F6' ) )
       agl = 33; 
    elseif( strcmpi( sitename, 'F5' ) )
        agl = 30;
    elseif( strcmpi( sitename, 'F0' ) )
        agl = 45;
	elseif( strcmpi( sitename, 'F1' ) )
        agl = 30;
    elseif( strcmpi( sitename, 'F2' ) )
        agl = 38;
    elseif( strcmpi( sitename, 'F3' ) )
        agl = 40;
    elseif( strcmpi( sitename, 'F4' ) )
        agl = 40;
    elseif( strcmpi( sitename, 'T2' ) )
        agl = 32;
    elseif( strcmpi( sitename, 'T3' ) )
        agl = 33;
    elseif( strcmpi( sitename, 'T4' ) )
        agl = 33;
    elseif( strcmpi( sitename, 'T6' ) )
        agl = 32;
    end


end