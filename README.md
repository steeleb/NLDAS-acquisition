# NLDAS-acquisition

## Why these scripts exists:

In the United States, a popular product is North American Land Data Assimilation System (NLDAS), which is a collaboration among NOAA, NASA, Princeton University, and the University of Washington. NLDAS is a spatially and temporally consistent land surface model constructed from climate models and observational data for the entire United States at an hourly resolution and retrospective to 1979. NLDAS-2 forcing data (https://ldas.gsfc.nasa.gov/nldas/v2/forcing) is often used in models that require hourly meteorological data (air temperature, precipitation, wind speed, relative humidity, shortwave and longwave radiation).

Unfortunately, for the average user, NLDAS-2 data, while publicly available, is difficult to obtain, especially when the focus is the time-optimized component rather than spatial data. There has been an attempt to overcome this “Digital Divide” in data representation (space vs. time) by NASA in the form of Data Rods (Teng et al., 2016). However, current implementation of Data Rods for NLDAS data masks all grid cells over water, which severely limits the use for limnological applications. 

Therefore, to download a time-series over water (say, a lake) in the R environment, requires a fairly advanced understanding of web service calls and working with multi-layer raster objects. The code in this repository provides a working implementation of this looped web call. Even with this code, to download an hourly decadal time series for a specific location can take hours to days to run. 

-Hilary Dugan

### Suggested Citation for NLDAS-2 forcing data:
Xia, Y., Mitchell, K., Ek, M., Sheffield, J., Cosgrove, B., Wood, E., Luo, L, Alonge, C., Wei, H., Meng, J., Livneh, B., Lettenmaier, D., Koren, V., Duan, Q., Mo, K., Fan, Y., & Mocko, D. (2012). Continental‐scale water and energy flux analysis and validation for the North American Land Data Assimilation System project phase 2 (NLDAS‐2): 1. Intercomparison and application of model products. Journal of Geophysical Research: Atmospheres, 117(D3), https://doi.org/10.1029/2011jd016048

## Contribution encouraged!

If you use these scripts and have to debug them, please let us know by making a pull request or by opening a new issue. We view these scripts as a community effort to further open science and appreciate the contribution of all people.


***

This repository contains the scripts from Hilary Dugan (hdugan@wisc.edu) for downloading and processing NLDAS-2 data. B. Steele (steeleb@caryinstitute.org) has made updates since that time (updates below 'Mar 2021')

## Mar 2021:
New workflow: run *getNLDAS_simple.R*, then *combineNLDAS.R*, then *collateNLDAS.R*

NOTE: getNLDAS_simple takes about 2-3 seconds per hour to download. (aka, 1 day of NLDAS data takes about a minute to download)

BGS update 09Mar2021: 
- added nc_close to file loop to stop hanging after ~ 2000 files
- removed referencing to values from other scripts (so now all are stand-alone and can be run separately)

BGS update 05Mar2021:
- B updated the getNLDAS_simple.R to remove the hardcoded information after line 43
- B updated combineNLDAS.R to use nc_open and nc_get to eliminate errors from brick() and extractValues() also, removed hardcoding after first handful of lines
- B updated collateNLDAS.R (formerly known as combineNLDAS_2.R) to remove hard coding. 


## Prior updates:

### Dec 2020:
Updated with getNLDAS_simple-PQT.R (archived, incorporated into Mar update) - there were bugs that were worked out by one of Hilary's postdocs Robert Ladwig.

### Nov 2020:
Information from Hilary:

First off, downloading a timeseries of NLDAS-2 data is a stunningly arduous task. It's set up for spatial downloads, not temporal. 
I wrote an R script to scrape data for every timestep by making a URL. It's not the best way, and everytime NASA changes something (which happens frequently), I have to debug it. 

Attached are some R scripts, you'll have to get a NASA Earthdata password if you haven't already (details in code). 

Things to note: It uses a shapefile to set the extent. You could also just hardcode this.

I can't really remember the exact details because I haven't looked at these scripts in a year but
1) getNLDAS_simple downloads data each hour, so you'll get a ton of tiny 8kb netcdf files. 
2) combineNLDAS The script reads the netcdf files and creates an output list. Based on the extent you set, it will download however many grid cells are within that extent. 
3) combineNLDAS_2 Stitches together the individual grid cells to have all 11 climate variables together. 

Also, I think I last used these for Mendota. So that string is hardcoded in in some places.




