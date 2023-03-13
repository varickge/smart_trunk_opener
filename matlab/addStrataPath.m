function addStrataPath
    clear wrapper_matlab % unload Strata module if currently loaded

    addpath('.') % Make sure Strata is in path, so rmpath() will not give a warning
    rmpath('.') % Remove Strata from path, so it will always be added at the beginning
    addpath('.') % Add Strata to beginning of path
    
    disp(['Strata Software Version: ' strata.getVersion()]);
end
