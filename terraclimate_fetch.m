function [vals,time] = terraclimate_fetch(lat_bounds,lon_bounds,years,months,var,averaging)
% This function reads TerraClimate datasets directly into MATLAB. They can
% then be saved as e.g. csv for use elsewhere.
%
%Usage:
%[vals,time] = terraclimate_fetch(lat_bounds,lon_bounds,years,months,var,((averaging)));
%
%Example:
%[vals,time] = terraclimate_fetch([50 51.5],[-75.5 -74.5],[2000 2015],[1 12],'ppt','timeseries');
%
%The above will download a precipitation timeseries from Jan 2000 to Dec
%2015, spatially averaged over the region 50 to 51.5 N latitude, -75.5 to -74.5 W
%longitude.
%
%Inputs
%-lat_bounds: 1x2 array of latitude bounds (in ascending order); e.g. [50 51.5]
%-lat_bounds: 1x2 array of longitude bounds (in ascending order); e.g. [-75.5 -74.5]
%-years: 1x2 array of year bounds (in ascending order); e.g. [2000 2015]
%-months: 1x2 array of month bounds (in ascending order); e.g. [1 12]
%-var: TerraClimate variable of interest, e.g. rainfall, wind speed, etc.
%      See http://www.climatologylab.org/terraclimate-variables.html.
%      Possible values are:
%            aet (Actual Evapotranspiration, monthly total)
%            def (Climate Water Deficit, monthly total)
%            pet (Potential evapotranspiration, monthly total)
%            ppt (Precipitation, monthly total)
%            q (Runoff, monthly total)
%            soil (Soil Moisture, total column - at end of month)
%            srad (Downward surface shortwave radiation)
%            swe (Snow water equivalent - at end of month)
%            tmax (Max Temperature, average for month)
%            tmin (Min Temperature, average for month)
%            vap (Vapor pressure, average for month)
%            ws (Wind speed, average for month)
%            vpd (Vapor Pressure Deficit, average for month)
%            PDSI (Palmer Drought Severity Index, at end of month)
%-averaging: (Optional parameter) Averaging options for the data. This may
%            be the following:
%            'none' = no averaging, result will be a 3D array with
%            dimensions lat x long x time
%            'timeseries' = spatial averaging, result will be a 1D
%            vector dimension time
%            'spatial' = time averaging, result will be a 2D matrix
%            with dimensions lat x long. Note the averaging will be on a
%            monthly basis, so for e.g. yearly precipitation you must
%            multiply the result by 12.
%
%Outputs:
%-vals: array of values, depending on input parameters
%-time: array of times
%
%
%
%Written Jan 2021 by Max Van Wyk de Vries @ University of Minnesota
%Credit to TerraClimate team.



%% Error checking: were the correct inputs entered?

% Was any averaging option entered?
if nargin < 5 %Too few inputs!
    help terraclimate_fetch
    error('You need to enter at least 5 inputs: lat,long,years,months, and your variable of interest.');
elseif nargin < 6 %No averaging optin. Default to no averaging
    disp('No averaging option entered. Defaulting to no averaging (raw 3D array).');
    averaging = 'none';
end

% Check if the coordinate and time inputs are correct
if size(lat_bounds,2)~=2 || size(lat_bounds,1)~=1 ||...
        size(lon_bounds,2)~=2 || size(lon_bounds,1)~=1 ||...
        size(years,2)~=2 || size(years,1)~=1 ||...
        size(months,2)~=2 || size(months,1)~=1
    help terraclimate_fetch
    error('Latitude, longitude, year and month inputs must all be 1x2 vectors. See the help for more information.');
end

%Check if the longitude and lattitude bounds are ascending
if lat_bounds(1)>lat_bounds(2) || lon_bounds(1)>lon_bounds(2)
    help terraclimate_fetch
    error('Latitude and longitude must be listed in ascending order. If negative, the larger negative number goes first (e.g. [-71 -70]).');
end

% Check if a valid parameter is selected. The full list is available here:
% http://www.climatologylab.org/terraclimate-variables.html
if strcmpi(var,'aet')~=1 && strcmpi(var,'def')~=1 && strcmpi(var,'pet')~=1 &&...
        strcmpi(var,'ppt')~=1 && strcmpi(var,'q')~=1 && strcmpi(var,'soil')~=1 &&...
        strcmpi(var,'srad')~=1 && strcmpi(var,'swe')~=1 && strcmpi(var,'tmax')~=1 &&...
        strcmpi(var,'tmin')~=1 && strcmpi(var,'vap')~=1 && strcmpi(var,'ws')~=1 &&...
        strcmpi(var,'vpd')~=1 && strcmpi(var,'PDSI')~=1
    
    help terraclimate_fetch
    error('Variable parameter must be one of the following: aet, def, pet, ppt,q, soil, srad, swe,tmax,tmin, vap, ws, vpd, PDSI');
    
end

disp('Inputs are valid. Fetching data. Please be patient, this can take a while for large datasets.');

%% Get the data

%Process times
timebounds_start =datenum(years(1),months(1),1)-datenum(1900,1,1);
timebounds_end = datenum(years(2),months(2),1)-datenum(1900,1,1);
timebounds = [timebounds_start timebounds_end];

%Extract lat and long bounds
lat=ncread(strcat('http://thredds.northwestknowledge.net:8080/thredds/dodsC/agg_terraclimate_',var,'_1958_CurrentYear_GLOBE.nc'),'lat');
lon=ncread(strcat('http://thredds.northwestknowledge.net:8080/thredds/dodsC/agg_terraclimate_',var,'_1958_CurrentYear_GLOBE.nc'),'lon');
flati=find(lat>=lat_bounds(1) & lat<=lat_bounds(2));
floni=find(lon>=lon_bounds(1) & lon<=lon_bounds(2));

%Get correct times
time=ncread(strcat('http://thredds.northwestknowledge.net:8080/thredds/dodsC/agg_terraclimate_',var,'_1958_CurrentYear_GLOBE.nc'),'time');
ftimei=find(time>=timebounds(1) & time<=timebounds(2));
time = time(ftimei);

%Read data
vals=ncread(strcat('http://thredds.northwestknowledge.net:8080/thredds/dodsC/agg_terraclimate_',var,'_1958_CurrentYear_GLOBE.nc'),...
    var,[floni(1) flati(1) ftimei(1)],[length(floni) length(flati) length(ftimei)],[1 1 1]);

%Create time vector
time = datetime(datestr(time+datenum(1900,1,1)));

%% Post process (average) if required
if strcmpi(averaging,'timeseries')
    vals = squeeze(nanmean(vals,[1 2])); %Squeeze reduces to 1D vector
elseif strcmpi(averaging,'spatial')
    vals = squeeze(nanmean(vals,3));    %Squeeze reduces to 2D map
end


