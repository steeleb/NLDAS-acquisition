# NLDAS-acquisition
This repository contains the scripts from Hilary Dugan (hdugan@wisc.edu) for downloading and processing NLDAS-2 data. Code should be properly attributed.

B. Steele has made updates since that time (updates below 'Mar 2021')

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


## Prior updates from other labs:

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




