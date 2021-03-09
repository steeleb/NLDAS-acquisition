###########################################################
### Downloading NLDAS2 data for meteorological hourly forcing
### http://ldas.gsfc.nasa.gov/nldas/NLDAS2forcing.php
### Author: Hilary Dugan hilarydugan@gmail.com
### Date: 2019-09-30
###########################################################

#v09Mar21 BGS: removed reliance on other script objects; nc_open timing out after about 3 months of data, so added an additional loop in the read function to open by month and added nc_close to script.
#v05Mar21 BGS: removed hardcoding after line 37

library(lubridate)
library(ncdf4)
library(tidyverse)


###########################################################
### set dump directory for .csv files and lake name
###########################################################
#where your .nc files are stored -- make sure all .nc files have a size >0, otherwise your loop will get hung up!
dumpdir_nc = 'C:/Users/steeleb/Dropbox/gloeo_ME_lakes/data/modern gloeo/raw data/Auburn/NLDAS_download/raw/'

#where you want to dump your monthly .csv's
dumpdir_csv = 'C:/Users/steeleb/Dropbox/gloeo_ME_lakes/data/modern gloeo/raw data/Auburn/NLDAS_download/raw_csv/'

lake_name = 'Auburn'

###########################################################
### Need to know how many cells your lake falls within
### Can download one instance of data from the earthdata site and see how many columns there are
### use 'nc_open(filename)' to see how many cells there are
###########################################################
cellNum = 1 
#How many output cells will there be? Need to check this beforehand by downloading a single netcdf file for your location

loc_tz = 'Etc/GMT+5' #EST with no DST observed

###########################################################
### Set up the output data frame
###########################################################

#save the variable names in nc files
vars_nc = c('TMP','SPFH', 'PRES', 'UGRD', 'VGRD', 'DLWRF', 'CONVfrac', 'CAPE', 'PEVAP', 'APCP', 'DSWRF')

#set up output dataframe for the number of cells above and the number of columns of data
output <- NULL
for (l in 1:length(vars_nc)){
  colClasses = c("POSIXct", rep("numeric",cellNum))
  col.names = c('dateTime',rep(vars_nc[l],cellNum))
  output[[l]] = read.table(text = "",colClasses = colClasses,col.names = col.names)
  attributes(output[[l]]$dateTime)$tzone = loc_tz
}

###########################################################
### Run file list loop
###########################################################
# Start the clock!
ptm <- proc.time()

nc_files <- list.files(dumpdir_nc)

for (i in 1:length(nc_files)) {
  print(nc_files[i])
    
  for (v in 1:length(vars_nc)) {
    nldasvar <- vars_nc[v]
    br = nc_open(paste0(dumpdir_nc,nc_files[i]))
    output[[v]][i,1] = (paste0(substr(nc_files[i], 1, 4),'-', substr(nc_files[i], 5,6), '-', substr(nc_files[i], 7,8), ' ', substr(nc_files[i], 9,10), ':', substr(nc_files[i], 11,12)))
    output[[v]][i,-1] = ncvar_get(br, nldasvar)
    nc_close(br)
  }
  rm(br)
}

# Stop the clock
proc.time() - ptm

###########################################################
### save each variable in a .csv
###########################################################
for (f in 1:length(vars_nc)){
  write.csv(output[[f]],paste0(dumpdir_csv, lake_name, vars_nc[f],'.csv'),row.names=F)
}



