function [fg dwi mriFile] = mctNfgSimulate(paramDir, bvecsFile, strandsDir, baseDir, nfgStageDir)
% Simulate fibers using the NFG toolbox by Tom Close.
%
%   fg = mctSimulateWithNFG([paramDir], [bvecsFile], [strandsDir], [baseDir], [nfgStageDir])
%
% We call the  NFG 'run' script 
% 
% The script will:
% (1) Load the simulation parameters stored in paramDir.
% (2) Load the bvecs from the bvecsFile
% (3) Simulate strands (the fibers).
% (4) Save the results in subdirectories of baseDir, 
%     on each new call the subdirectries are named as yymmddHHMMSS
% (5) Load the strands into a fiber groups compatible with 
%     Microtrack and mrDiffusion.
% 
% Input parameters are:
%
%   paramDir = directory containing the parameter files:
%              1_rand_initi_param.txt
%              2_optimise_params.txt
%              3_trim_params.txt
%              4_subdiv_param.txt
%              5_resample_param.txt
%              6_optimise_param.txt
%              7_trim_param.txt
%              8_mri_sim_param.txt
%              9_nosify_param.txt
%              Optional: [draw_rois_param.txt]
%
% Example:
%
%   fg = mctNfgSimulate; % will use default params
%
% See also: mctNfgLoadStrands.m, s_mct_simulated.m, mctNfgBuildDwi,
%           mctNfgStrand2fiber 
%
% by Franco Pestilli
%
% (C) 2012 Stanford VISTA team. 

nfgDir = fullfile(mctPath,'ext','nfg_1.1.1');
if notDefined('paramDir'), paramDir = fullfile(nfgDir,'parameters','mct_params'); end
if notDefined('bvecsFile'), bvecsFile = fullfile(nfgDir,'gradient_directions','encoding_dir60.txt'); end
if notDefined('baseDir'),  baseDir = fullfile(mctPath,'mct_simulations');  end

% if a stage directory is not returned use the last stage
if notDefined('nfgStageDir')    nfgStageDir = '7_trim'; end 
if notDefined('strandsDir'), strandsDir = sprintf('strands_%s',datestr(now,30)); end

% if a stage directory is not returned use the last stage
if notDefined('nfgDwiDir'), nfgDwiDir = '8_mri_sim'; end 

% build the directory name where the strands should be saved to or loaded
% from:
strandsDirFinal = fullfile(baseDir,strandsDir,nfgStageDir);

% run a simulation only if the strands were not already created.
if ~isdir(strandsDirFinal)
    % use the parameters to run the NFG simulator.
    run = fullfile(mctPath,'ext','nfg_1.1.1','run');
    cmd = sprintf('%s ''%s'' ''%s'' ''%s'' '' '' ''%s''',run,paramDir,bvecsFile,baseDir,strandsDir);
    
    % The simulation in NFG is invoked here
    tic;
    fprintf('[%s] Starting fibers simulation using NFG...\n',mfilename);
    [status result] = system(cmd);
    fprintf('[%s] Done simulating fibers using NFG -computing time %2.2fminutes.\n',mfilename,ceil(toc/60));
    fprintf('[%s] NFG ''strands'' files were saved in %s.\n',mfilename,strandsDir);
    
    if (status ~= 0)
        error(sprintf('[%s] Could not complete the simulation this is the unix error:\n %s\n',mfilename,result))
    end
else
    fprintf('[%s] Loading precomputed strands from directory:\n%s\n',mfilename,strandsDirFinal);
end

% Build a nifti file of the diffusion image generated by NFG from the fibers
% (1) noise-less dwi
dwiSimulationDirectory = fullfile(baseDir,strandsDir,nfgDwiDir);
[dwi mriFile] = mctNfgBuildDwi(dwiSimulationDirectory);

% load the strands just generated by NFG
strands = mctNfgLoadStrands(strandsDirFinal);

% transform the strands into a fiber group
fg = mctNfgStrand2fiber(strands,dwi.nifti.dim);

return