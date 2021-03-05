###########################################################
### Downloading NLDAS2 data for meteorological hourly forcing
### http://ldas.gsfc.nasa.gov/nldas/NLDAS2forcing.php
### Author: Hilary Dugan hilarydugan@gmail.com
### Date: 2019-09-30
###########################################################

library(lubridate)
library(raster)
library(ncdf4)
library(rgdal)


###########################################################
### set dump directory for .csv files and lake name
###########################################################
dumpdir_csv = 'C:/Users/steeleb/Dropbox/gloeo_ME_lakes/data/modern gloeo/raw data/Auburn/NLDAS_download/raw_csv/'
lake_name = 'Auburn'

###########################################################
### Need to know how many cells your lake falls within
### Can download one instance of data from the earthdata site and see how many columns there are
### use 'nc_open(filename)' to see how many cells there are
###########################################################
cellNum = 1 
#How many output cells will there be? Need to check this beforehand by downloading a single netcdf file for your location


###########################################################
### Set up the output data frame
###########################################################

#save the variable names in nc files
vars_nc = c('TMP','SPFH', 'PRES', 'UGRD', 'VGRD', 'DLWRF', 'CONVfrac', 'CAPE', 'PEVAP', 'APCP', 'DSWRF')

output <- NULL
#set up output dataframe for the number of cells above and the number of columns of data
for (l in 1:length(vars_nc)){
  colClasses = c("POSIXct", rep("numeric",cellNum))
  col.names = c('dateTime',rep(vars_nc[l],cellNum))
  output[[l]] = read.table(text = "",colClasses = colClasses,col.names = col.names)
  attributes(output[[l]]$dateTime)$tzone = loc_tz
}


###########################################################
### Run hourly loop
###########################################################
# Start the clock!
ptm <- proc.time()

#make a list of the nc files that you want to extract
nc_files <- list.files(dumpdir_nc)

for (i in 1:length(nc_files)) {
    print(out.ts[i])
  
    for (v in 1:length(vars_nc)) {
      nldasvar <- vars_nc[v]
    br = nc_open(paste0(dumpdir_nc,nc_files[i]))
    output[[v]][i,1] = out.ts[i]
    output[[v]][i,-1] = ncvar_get(br, nldasvar)
  }
  rm(br)
}
# Stop the clock
proc.time() - ptm

###########################################################
### Save all 11 variables from the output list in separated .csv's
###########################################################
for (f in 1:11){
  write.csv(output[[f]],paste0(dumpdir_csv, lake_name,vars_nc[f],'.csv'),row.names=F)
}


