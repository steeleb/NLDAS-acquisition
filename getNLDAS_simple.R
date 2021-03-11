###########################################################
### Downloading NLDAS2 data for meteorological hourly forcing
### http://ldas.gsfc.nasa.gov/nldas/NLDAS2forcing.php
### Author: Hilary Dugan hilarydugan@gmail.com
### Date: 2019-09-30
###########################################################

# v 04Mar2021: BGS updated to remove hardcoding: only first 43 lines need to be edited

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
username = 'username'
password = 'password'
#in addition, make sure you have authorized your account access to the GEODISC archives:
# https://disc.gsfc.nasa.gov/earthdata-login

###########################################################
### Use shapefile of lake to set bounding box
###########################################################
# read in lake file (as a .shp file) to get bounding box
# lakeShape = st_read('shapefile.shp') 
extent = as.numeric(c(-70.27, 44.15, -70.25, 44.17)) 
#if the extent is loaded from the shapefile (above), make sure they are in decimal degrees, otherwise this code will not work

###########################################################
### Set timeframe
###########################################################
startdatetime = '2013-01-01 00:00:00'
enddatetime = '2019-12-31 23:00:00'
loc_tz = 'GMT' #only run in tz's without DST, otherwise you will be very sad when you go to collate and it's a mess. 


# sequence the datetime over your desired time period
out.ts = seq.POSIXt(as.POSIXct(startdatetime, tz = loc_tz),as.POSIXct(enddatetime,tz=loc_tz), by = 'hour')

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

  # URL3 = paste('http://',username,':',password,'@hydro1.gesdisc.eosdis.nasa.gov/daac-bin/OTF/HTTP_services.cgi?',
  #              'FILENAME=%2Fdata%2FNLDAS%2FNLDAS_FORA0125_H.002%2F',yearOut,'%2F',doyOut,'%2FNLDAS_FORA0125_H.A',yearOut,monthOut,dayOut,'.',hourOut,'.002.grb&',
  #              'FORMAT=bmV0Q0RGLw&BBOX=',extent[2],'%2C',extent[1],'%2C',extent[4],'%2C',extent[3],'&',
  #              'LABEL=NLDAS_FORA0125_H.A',yearOut,monthOut,dayOut,'.',hourOut,'.002.2017013163409.pss.nc&',
  #              'SHORTNAME=NLDAS_FORA0125_H&SERVICE=SUBSET_GRIB&VERSION=1.02&DATASET_VERSION=002',sep='')
  #
  # URL <- paste('http://hydro1.sci.gsfc.nasa.gov/daac-bin/OTF/HTTP_services.cgi?',
  #              'FILENAME=%2Fdata%2Fs4pa%2FNLDAS%2FNLDAS_FORA0125_H.002%2F',yearOut,
  #              '%2F',doyOut,
  #              '%2FNLDAS_FORA0125_H.A',yearOut,monthOut,dayOut,'.',
  #              hourOut,'.002.grb&',
  #              'FORMAT=bmV0Q0RGLw&BBOX=',
  #              extent[2],'%2C',
  #              extent[1],'%2C',
  #              extent[4],'%2C',
  #              extent[3],'&',
  #              'LABEL=NLDAS_FORA0125_H.A',yearOut,monthOut,dayOut,'.',
  #              hourOut,'.002.2016116144611.pss.nc&',
  #              'SHORTNAME=NLDAS_FORA0125_H&SERVICE=SUBSET_GRIB&VERSION=1.02&DATASET_VERSION=002',sep='')
  
  ## Patricia Tran note (2020-12-03 : I updated the link the webpage)

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
  

# IMPORTANT MESSAGE Dec 05, 2016    The GES DISC will be migrating from http to https throughout December
  # As part of our ongoing migration to HTTPS, the GES DISC will begin redirecting all HTTP traffic to HTTPS.
  # We expect to have all GES DISC sites redirecting traffic by January 4th. For most access methods, the redirect will be transparent to the user.
  # However, users with locally developed scripts or utilities that do not support an HTTP code 301 redirect may find that the scripts will fail.
  # If you access our servers non-interactively (i.e. via a mechanism other than a modern web browser), you will want to modify your scripts to
  # point to the HTTPS addresses to avoid the enforced redirect.

  # x = download.file(URL3,destfile = paste(filename,'.nc',sep=''),mode = 'wb',quiet = T)
  # x = download.file(URL,destfile = paste(filename,'.nc',sep=''),mode = 'wb',quiet = T)


  lk <- URL
  
  #wget:
  #r <- GET(lk,
  #          authenticate("ptran5@wisc.edu", "Earthdata1"),
  #          path = "~/Documents/MendotaRawData/")

  # or this with curl
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
