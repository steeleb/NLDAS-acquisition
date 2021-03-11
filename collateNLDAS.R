#v09Mar2021 BGS: removed references to combineNLDAS.R; note that this was only tested for NLDAS data that were downloaded for a single box/cell, further debugging may be necessary for downloads that include multiple cells/boxes
#v05Mar2021 BGS: updated to remove hardcoding after line 14; NOTE, this refers to values created in combineNLDAS.R

library(tidyverse)
library(dplyr)
library(lubridate)

###########################################################
### set-up and define directories, files, etc
###########################################################

#where you stored your .csv's
dumpdir_csv = 'C:/Users/steeleb/Dropbox/gloeo_ME_lakes/data/modern gloeo/raw data/Auburn/NLDAS_download/raw_csv/'
# define the dump directory for your final .csv files
dumpdir_final = 'C:/Users/steeleb/Dropbox/gloeo_ME_lakes/data/modern gloeo/raw data/Auburn/NLDAS_download/final/'

#define the lakename, and the box number
LakeName = 'Auburn'

cellNum = 1 #number of cells in your area of interest
box = 1 # Chosen cell of 'cellNum' from combineNLDAS.R, you'll have to look at these to figure out which one is best. use nc_get(filename.nc, 'lat'), etc to find bounding boxes and choose which one you want

# define the time range
startdatetime = '2017-01-01 00:00:00'
enddatetime = '2019-12-31 23:00:00'
loc_tz = 'GMT' #this should be the same as previous entries

#enter the timezone you would like to have the final data in. see OlsonNames() for options
local_tz = 'EST'

#save the variable names in nc files
vars_nc = c('TMP','SPFH', 'PRES', 'UGRD', 'VGRD', 'DLWRF', 'CONVfrac', 'CAPE', 'PEVAP', 'APCP', 'DSWRF')

###########################################################
### run loop to collate all data
###########################################################

# make a list of the files previously collated
files = list.files(dumpdir_csv, pattern = '.csv')

#make a null dataframme with the sequence of datetimes from above
final.box = data.frame(dateTime = seq.POSIXt(as.POSIXct(startdatetime, tz= loc_tz),as.POSIXct(enddatetime,tz=loc_tz),by = 'hour'))

#index each box csv to break out each of the cells
for (i in 1:11){
  fileIndx = grep(vars_nc[i],files)
  
  df = read_csv(paste0(dumpdir_csv,files[fileIndx[1]]),
                col_types = c('cn')) %>% 
    dplyr::mutate(dateTime = as.POSIXct(dateTime, tz=loc_tz)) %>% 
    arrange(dateTime) # chronological order   
  
  if(length(fileIndx) >1) {
    for (f in 2:length(fileIndx)){
      df2 = read.csv(files[fileIndx[f]])
      df = rbind(df,df2)
    }
  }

  # Total time series
  out = data.frame(dateTime = seq.POSIXt(as.POSIXct(startdatetime, tz= loc_tz),as.POSIXct(enddatetime,tz=loc_tz),by = 'hour'))
  
  missingDates = out %>% 
    anti_join(df)
  print(nrow(missingDates)) # Check for missing dates. 
  
  out = out %>% 
    left_join(df)
  print(nrow(out))
  # out <- distinct(out) #check for duplicate time stamps
  
  out %>% 
    mutate(dateTime = as.character(dateTime)) %>% 
    write_csv(.,paste0(dumpdir_final,LakeName,format(as.POSIXct(startdatetime), '%Y-%m-%d'), '_', format(as.POSIXct(enddatetime), '%Y-%m-%d'),'_', vars_nc[i],'.csv'))
  
  final.box <- final.box %>% 
    left_join(out)
}

####### Create a Single Dataframe and adjust time zone###########
head(final.box)
tail(final.box)
which(duplicated(final.box)) #check for duplicate time stamps - if this list is long, something is wrong!! There should be ZERO duplicated timestamps.
# final.box <- distinct(final.box)
which(is.na(final.box$TMP)) # check for NA values

# adjust to local timezone #
final.box <- final.box %>% 
  mutate(local_dateTime = with_tz(dateTime, tzone = local_tz))
head(final.box)

# Air saturation as a function of temperature and pressure
# Used to calculate relative humidity 
qsat = function(Ta, Pa){
  ew = 6.1121*(1.0007+3.46e-6*Pa)*exp((17.502*Ta)/(240.97+Ta)) # in mb
  q  = 0.62197*(ew/(Pa-0.378*ew))                              # mb -> kg/kg
  return(q)
}


# Variable names for NLDAS2 forcing file:
# PDS_IDs:Short_Name:Full_Name [Unit]
# 63:ACPCPsfc:Convective precipitation hourly total [kg/m^2]
# 61:APCPsfc:Precipitation hourly total [kg/m^2]
# 118:BRTMPsfc:Surface brightness temperature from GOES-UMD Pinker [K]
# 157:CAPEsfc:Convective Available Potential Energy [J/kg]
# 205:DLWRFsfc:LW radiation flux downwards (surface) [W/m^2]
# 204:DSWRFsfc:SW radiation flux downwards (surface) [W/m^2]
# 101:PARsfc:PAR Photosynthetically Active Radiation from GOES-UMD Pinker [W/m^2]
# 201:PEDASsfc:Precipitation hourly total from EDAS [kg/m^2]
# 202:PRDARsfc:Precipitation hourly total from StageII [kg/m^2]
# 1:PRESsfc:Surface pressure [Pa]
# 206:RGOESsfc:SW radiation flux downwards (surface) from GOES-UMD Pinker [W/m^2]
# 51:SPFH2m:2-m above ground Specific humidity [kg/kg]
# 11:TMP2m:2-m above ground Temperature [K]
# 33:UGRD10m:10-m above ground Zonal wind speed [m/s]
# 34:VGRD10m:10-m above ground Meridional wind speed [m/s]

# Following code used to reformat dataframe to format used with GLM-AED

drivers <- final.box %>% 
  dplyr::rename(PotentialEvap = PEVAP,
                LongWave.W_m2=DLWRF,
                ShortWave.W_m2=DSWRF,
                ConvectivePrecip = CONVfrac,
                ConvectivePotentialEnergy = CAPE,
                Precipitation = APCP,
                SpecHumidity.kg_kg=SPFH,
                WindSpeed_Zonal = VGRD, 
                WindSpeed_Meridional = UGRD,
                AirTemp2m = TMP,
                SurfPressure.Pa = PRES) %>% 
  dplyr::mutate(RelHum = 100*SpecHumidity.kg_kg/qsat(AirTemp2m-273.15, SurfPressure.Pa*0.01),
                WindSpeed.m_s=sqrt(WindSpeed_Zonal^2+WindSpeed_Meridional^2),
                AirTemp.C = AirTemp2m - 273.15, 
                Rain.m_day = Precipitation*24/1000) %>% 
  dplyr::select(local_dateTime,AirTemp.C,ShortWave.W_m2,LongWave.W_m2,
                SpecHumidity.kg_kg,RelHum,WindSpeed.m_s,Rain.m_day,SurfPressure.Pa)
drivers %>% 
  mutate(local_dateTime = as.character(local_dateTime)) %>% 
  write_csv(.,paste0(dumpdir_final,LakeName,format(as.POSIXct(startdatetime), '%Y-%m-%d'), '_', format(as.POSIXct(enddatetime), '%Y-%m-%d'),'_box',box,'_alldata.csv'))

drivers %>% 
  group_by(dateTime) %>% 
  filter(n()>1)

plot(drivers$dateTime,drivers$Rain,type = 'l')
plot(drivers$dateTime,drivers$ShortWave,type = 'l')



