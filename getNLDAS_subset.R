###########################################################
### Downloading NLDAS2 data for meteorological hourly forcing
### http://ldas.gsfc.nasa.gov/nldas/NLDAS2forcing.php
### Author: Hilary Dugan hilarydugan@gmail.com
### Date: 2019-09-30
###########################################################

library(RCurl)
library(lubridate)
library(raster)
library(ncdf4)
library(sf)
library(httr)
library(curl)
library(stringr)
# library(tidyverse)
library(yaml)

#read yml file
setup = read_yaml('setup.yml')
if(!dir.exists(setup$dumpdir_nc)){dir.create(setup$dumpdir_nc)}
if(!dir.exists(setup$dumpdir_csv)){dir.create(setup$dumpdir_csv)}


# sequence the datetime over your desired time period
out.ts = seq.POSIXt(as.POSIXct(setup$startdatetime, tz = setup$loc_tz),as.POSIXct(setup$enddatetime,tz=setup$loc_tz), by = 'hour')

# Create output list of tables
output = list()

###########################################################
### Run hourly loop
###########################################################
# Start the clock!
ptm <- proc.time()

for (i in 1:length(out.ts)) {
  print(out.ts[i])
  yearOut = year(out.ts[i])
  monthOut = format(out.ts[i], "%m")
  dayOut = format(out.ts[i], "%d")
  hourOut = format(out.ts[i], "%H%M")
  doyOut = format(out.ts[i],'%j')

  filename = format(out.ts[i], "%Y%m%d%H%M")
  

  ## Patricia Tran note (2020-12-03 : I updated the link the webpage)
  URL <- paste0('https://hydro1.gesdisc.eosdis.nasa.gov/daac-bin/OTF/HTTP_services.cgi?FILENAME=%2Fdata%2FNLDAS%2FNLDAS_FORA0125_H.002%2F',
               yearOut, '%2F',
               str_pad(as.numeric(yday(as.Date(paste0(yearOut,"-", monthOut,'-' ,dayOut)))), 3, pad = "0"), ## The URL changes for every chunk of 24 hours
               '%2FNLDAS_FORA0125_H.A',
               yearOut, monthOut, dayOut, '.',
               hourOut,  '.002.grb&FORMAT=bmM0Lw&BBOX=', 
               round(as.numeric(setup$extent[2]), 2),'%2C', # In the new version of the URL, the coordinates are only up to 2 digits
               round(as.numeric(setup$extent[1]), 2),'%2C',
               round(as.numeric(setup$extent[4]), 2),'%2C',
               round(as.numeric(setup$extent[3]), 2),
               'SERVICE=L34RS_LDAS&DATASET_VERSION=002&LABEL=NLDAS_FORA0125_H.A',
               yearOut,monthOut,dayOut,'.',
               hourOut,
               '.002.grb.SUB.nc4&SHORTNAME=NLDAS_FORA0125_H&VERSION=1.02&FORMAT=bmM0Lw&VARIABLES=DSWRF%2CSPFH%2CUGRD%2CVGRD')
  lk <- URL
  
  # or this with curl
  h <- curl::new_handle()
  
  curl::handle_setopt(
    handle = h,
    httpauth = 1,
    userpwd = paste0(setup$username, ':', setup$password)
  )

  # resp <- curl::curl_fetch_memory(lk, handle = h)
  resp <- curl::curl_fetch_disk(url = lk, 
                                path = paste0(setup$dumpdir_nc,filename,'.nc4'), 
                                handle = h)

  #Sys.sleep(2)
  
}
# Stop the clock
proc.time() - ptm

