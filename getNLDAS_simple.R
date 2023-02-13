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
library(yaml)

###########################################################
### Load YAML files
###########################################################
setup = read_yaml('setup.yml')
secrets = read_yaml('secrets.yml')

###########################################################
### Create dump directories if they do not exist
###########################################################
if(!dir.exists(setup$dumpdir_nc)) {dir.create(setup$dumpdir_nc)}
if(!dir.exists(setup$dumpdir_csv)) {dir.create(setup$dumpdir_csv)}

###########################################################
### Load password information
###########################################################
username = secrets$username
password = secrets$password

###########################################################
### Set bounding extent
###########################################################
if(length(setup$extent) != 4) {
  shape = st_read(setup$shapefile)
  shape_wgs = st_transform(shape, crs = 'EPSG:4326')
  extent = st_bbox(shape_wgs)
} else {extent = setup$extent}

###########################################################
### Set timeframe from config
###########################################################
startdatetime = setup$startdatetime
enddatetime = setup$enddatetime
loc_tz = setup$loc_tz

# sequence the datetime over your desired time period
out.ts = seq.POSIXt(as.POSIXct(startdatetime, tz = loc_tz),
                    as.POSIXct(enddatetime,tz=loc_tz), 
                    by = 'hour')

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
               round(as.numeric(extent[2]), 2),'%2C', # In the new version of the URL, the coordinates are only up to 2 digits
               round(as.numeric(extent[1]), 2),'%2C',
               round(as.numeric(extent[4]), 2),'%2C',
               round(as.numeric(extent[3]), 2),
               '&LABEL=NLDAS_FORA0125_H.A',
               yearOut,monthOut,dayOut,'.',
               hourOut,
               '.002.grb.SUB.nc4&SHORTNAME=NLDAS_FORA0125_H&SERVICE=L34RS_LDAS&VERSION=1.02&DATASET_VERSION=002'
               )
  

  lk <- URL
  
  h <- curl::new_handle()
  
  curl::handle_setopt(
    handle = h,
    httpauth = 1,
    userpwd = paste0(username, ':', password)
  )

  resp <- curl::curl_fetch_disk(url = lk, 
                                path = file.path(setup$dumpdir_nc,paste0(filename,'.nc')), 
                                handle = h)

  Sys.sleep(2)
  
}
# Stop the clock
proc.time() - ptm
