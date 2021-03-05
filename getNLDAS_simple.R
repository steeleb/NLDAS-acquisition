###########################################################
### Downloading NLDAS2 data for meteorological hourly forcing
### http://ldas.gsfc.nasa.gov/nldas/NLDAS2forcing.php
### Author: Hilary Dugan hilarydugan@gmail.com
### Date: 2019-09-30
###########################################################

# v 04Mar2021: BGS updated to remove hardcoding: only first 47 lines need to be edited

library(RCurl)
library(lubridate)
library(raster)
library(ncdf4)
library(sf)
library(httr)
library(curl)
library(stringr)

###########################################################
### Point to dump directory where data will be saved
###########################################################
dumpdir_nc = 'C:/Users/steeleb/Dropbox/gloeo_ME_lakes/data/modern gloeo/raw data/Auburn/NLDAS_download/raw/'

###########################################################
### Enter password information
###########################################################
#https://urs.earthdata.nasa.gov/profile <-- GET A EARTHDATA LOGIN
username = 'steeleb'
password = 'B8e!S3KAt@D54hz'
#in addition, make sure you have authorized your account access to the GEODISC archives, you won't actually download any data unless you activate it:
# https://disc.gsfc.nasa.gov/earthdata-login

###########################################################
### Use shapefile of lake to set bounding box
###########################################################
# read in lake file (as a .shp file) to get bounding box
lake_name = 'Auburn'
# lakeShape = st_read('shapefile.shp') 
extent = as.numeric(c(-70.27, 44.15, -70.25, 44.17)) 
#if the extent is loaded from the shapefile (above), make sure the values are in decimal degrees, otherwise this code will not work

###########################################################
### Set timeframe
###########################################################
startdatetime = '2013-01-01 00:00:00'
enddatetime = '2019-12-31 23:00:00'
loc_tz = 'EST'
#note, download time is approximately 2-3 seconds per hour.  you should now do something else until tomorrow. :)

# sequence the datetime over your desired time period
out.ts = seq.POSIXt(as.POSIXct(startdatetime, tz = loc_tz),as.POSIXct(enddatetime,tz=loc_tz), by = 'hour')

# list vars you are interested in
vars = c('PEVAPsfc_110_SFC_acc1h', 'DLWRFsfc_110_SFC', 'DSWRFsfc_110_SFC', 'CAPE180_0mb_110_SPDY',
         'CONVfracsfc_110_SFC_acc1h', 'APCPsfc_110_SFC_acc1h', 'SPFH2m_110_HTGL',
         'VGRD10m_110_HTGL', 'UGRD10m_110_HTGL', 'TMP2m_110_HTGL', 'PRESsfc_110_SFC')

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

  URL <- paste('https://hydro1.gesdisc.eosdis.nasa.gov/daac-bin/OTF/HTTP_services.cgi?FILENAME=%2Fdata%2FNLDAS%2FNLDAS_FORA0125_H.002%2F',
               yearOut, '%2F',
               str_pad(as.numeric(yday(as.Date(paste0(yearOut,"-", monthOut,'-' ,dayOut)))), 3, pad = "0"), ## The URL changes for every chunk of 24 hours
               '%2FNLDAS_FORA0125_H.A',
               yearOut, monthOut, dayOut, '.',
               hourOut,  '.002.grb&FORMAT=bmM0Lw&BBOX=', 
               round(extent[2], 2),'%2C', # In the new version of the URL, the coordinates are only up to 2 digits
               round(extent[1], 2),'%2C',
               round(extent[4], 2),'%2C',
               round(extent[3], 2),
               '&LABEL=NLDAS_FORA0125_H.A',
               yearOut,monthOut,dayOut,'.',
               hourOut,
               '.002.grb.SUB.nc4&SHORTNAME=NLDAS_FORA0125_H&SERVICE=L34RS_LDAS&VERSION=1.02&DATASET_VERSION=002',
               sep='')
  
  lk <- URL
  
  h <- curl::new_handle()
  
  curl::handle_setopt(
    handle = h,
    httpauth = 1,
    userpwd = paste0(username, ':', password)
  )

  # resp <- curl::curl_fetch_memory(lk, handle = h)
  resp <- curl::curl_fetch_disk(url = lk, 
                                path = paste(dumpdir_nc,filename,'.nc',sep=''), 
                                handle = h)

  #Sys.sleep(2)
  
}
# Stop the clock
proc.time() - ptm
