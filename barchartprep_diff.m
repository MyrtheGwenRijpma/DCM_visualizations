clear all;close all;clc


%% Set directories  and files
rootdir = '/Volumes/macdata/groups/rankin/Users/Myrthe/2019/rSMS_DCM/RSMS-DCM/DCMscripts/spreadsheet';


% Set parameters
THRESHOLD = 0.74;
GROUPSELECTOR = 'diff';
savefile = ['bargraph_' GROUPSELECTOR '.csv'];
PEBfile = ['PEB3_' GROUPSELECTOR '.mat'];
GCMfile = ['GCM3_' GROUPSELECTOR '.mat'];
ROIfile = 'ROIs_full_8mm.xlsx';

%% Load PEB, GCM, and Pp files
load(fullfile(rootdir, PEBfile));
load(fullfile(rootdir, GCMfile));

% NEED TO SET THE VARIABLE HERE
BMA = eval('PEB3');
GCM = eval('GCMs');


%% Retrieve Edges
df_edges = readtable(fullfile(rootdir,ROIfile));
nodes = df_edges.ROI_name;
edges = {};
counter = 1;
for i = 1:length(nodes)

    for j = 1:length(nodes)
        edges{counter,1} = strcat(nodes{i},'-' , nodes{j});
        counter = counter + 1;
    end
end

% Set number of ROIs and connections
nROIs = length(nodes);
nConnections = nROIs^2;
ncovariates = length(PEB3.Ep)/nConnections;
totalConnections = nConnections*ncovariates;


%% Retrieve the Pp from xPEB
% First run the spm_dcm_peb_review(PEB, GCM);
% Then select any covariates to view. The Pp is the same, and it will be
% generated once you can see the graph. 
% Then run Pp = xPEB.Pp; to retrieve the Pp for the group.
spm_dcm_peb_review(BMA, GCM);
Pp = xPEB.Pp;


%% Get the Ep Values
Ep = full(PEB3.Ep(:,ncovariates));


%% Get the CIs
Cp = zeros(totalConnections,1);
for i = 1:totalConnections
    Cp(i,1) = PEB3.Cp(i,i);
end

% Get the CI
startingindx = (ncovariates-1)*nConnections;
CI_0 = Cp(startingindx+1:totalConnections,:);
ci = spm_invNcdf(1 - 0.05);  
CI = ci * sqrt(CI_0);

%% Concat data into table
group = repmat({GROUPSELECTOR},nConnections,1);

barchattable = table(group, edges, Ep, Pp, CI);

% Save table
writetable(barchattable, fullfile(rootdir,savefile));

