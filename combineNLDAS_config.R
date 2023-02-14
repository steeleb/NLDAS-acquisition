###########################################################
### Downloading NLDAS2 data for meteorological hourly forcing
### http://ldas.gsfc.nasa.gov/nldas/NLDAS2forcing.php
### Author: Hilary Dugan hilarydugan@gmail.com
### Author: B Steele steeleb@caryinstitute.org
### Date: 2019-09-30
### Last Updated: 2023-02-13
###########################################################

# library(lubridate)
library(ncdf4)
library(tidyverse)


###########################################################
### Set up the output data frame
###########################################################

#save the variable names in nc files
vars_nc = setup$params

test = nc_open(file.path(setup$dumpdir_nc, list.files(setup$dumpdir_nc)[1]))
cellNum = test$dim$time$len
nc_close(test)

#set up output dataframe for the number of cells above and the number of columns of data
output <- NULL
for (l in 1:length(vars_nc)){
  colClasses = c("POSIXct", rep("numeric",cellNum)) 
  col.names = c('dateTime',rep(vars_nc[l],cellNum))
  output[[l]] = read.table(text = "",colClasses = colClasses,col.names = col.names)
  attributes(output[[l]]$dateTime)$tzone = 'GMT'
}

###########################################################
### Run file list loop
###########################################################
# Start the clock!
ptm <- proc.time()

nc_files <- list.files(setup$dumpdir_nc)

for (i in 1:length(nc_files)) {
  print(nc_files[i])
    
  for (v in 1:length(vars_nc)) {
    nldasvar <- vars_nc[v]
    br = nc_open(paste0(setup$dumpdir_nc,nc_files[i]))
    output[[v]][i, 1] = as.POSIXct(paste0(substr(nc_files[i], 1, 4),'-', substr(nc_files[i], 5,6), '-', substr(nc_files[i], 7,8), ' ', substr(nc_files[i], 9,10), ':', substr(nc_files[i], 11,12)), tz='UTC')
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
  write.csv(output[[f]],paste0(setup$dumpdir_csv, setup$lake_name, vars_nc[f],'.csv'),row.names=F)
}



