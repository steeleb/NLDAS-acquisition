library(tidyverse)

files = list.files(dumpdir_csv, pattern = '.csv')

LakeName = 'Auburn'
cellNum = 1 #Number of cells
box = 1 # Chosen cell

vars = c('PEVAPsfc_110_SFC_acc1h', 'DLWRFsfc_110_SFC', 'DSWRFsfc_110_SFC', 'CAPE180_0mb_110_SPDY',
         'CONVfracsfc_110_SFC_acc1h', 'APCPsfc_110_SFC_acc1h', 'SPFH2m_110_HTGL', 
         'VGRD10m_110_HTGL', 'UGRD10m_110_HTGL', 'TMP2m_110_HTGL', 'PRESsfc_110_SFC')
final.box = data.frame(dateTime = seq.POSIXt(as.POSIXct('1980-01-01 01:00',tz = 'GMT'),as.POSIXct('2019-12-31 23:00',tz='GMT'),by = 'hour'))

for (i in 1:11){
  fileIndx = grep(vars[i],files)
  
  df = read_csv(files[fileIndx[1]]) %>% arrange(dateTime) # chronological order   # for (f in 2:length(fileIndx)){
  #   df2 = read.csv(files[fileIndx[f]])
  #   df = rbind(df,df2)
  # }
  
  # Total time series
  out = data.frame(dateTime = seq.POSIXt(as.POSIXct('1980-01-01 01:00',tz = 'GMT'),as.POSIXct('2019-12-31 23:00',tz='GMT'),by = 'hour'))
  
  missingDates = out %>% anti_join(df)
  nrow(missingDates) # Check for missing dates. 
  
  out = out %>% left_join(df)
  
  write_csv(out,paste(LakeName,'_Final/',LakeName,'_1980_2019_',vars[i],'.csv',sep=''))
  
  final.box[,i+1] = out[,box+1] 
}

####### Single Dataframe ###########
colnames(final.box) = c('dateTime',vars)
head(final.box)
which(duplicated(final.box$dateTime)) #check for duplicate time stamps
which(is.na(final.box$TMP2m_110_HTGL)) # check for NA values

# out = seq.POSIXt(as.POSIXct('1979-01-01 00:00',tz = 'GMT'),as.POSIXct('2009-12-31 23:00',tz='GMT'),by = 'hour')
# out[!out %in% final.box$dateTime] # Check for missing dates. 

# Air saturation as a function of temperature and pressure
# Used to calculate relative humidity 
qsat = function(Ta, Pa){
  ew = 6.1121*(1.0007+3.46e-6*Pa)*exp((17.502*Ta)/(240.97+Ta)) # in mb
  q  = 0.62197*(ew/(Pa-0.378*ew))                              # mb -> kg/kg
  return(q)
}

# Following code used to reformat dataframe to format used with GLM-AED
library(dplyr)
drivers <- final.box %>% dplyr::rename(PotentialEvap = PEVAPsfc_110_SFC_acc1h,
                                       LongWave.W_m2=DLWRFsfc_110_SFC,ShortWave.W_m2=DSWRFsfc_110_SFC,
                                       ConvectivePrecip = CONVfracsfc_110_SFC_acc1h,
                                       ConvectivePotentialEnergy = CAPE180_0mb_110_SPDY,
                                       Precipitation = APCPsfc_110_SFC_acc1h,SpecHumidity.kg_kg=SPFH2m_110_HTGL,
                                       WindSpeed_Zonal = VGRD10m_110_HTGL, WindSpeed_Meridional = UGRD10m_110_HTGL,
                                       AirTemp2m = TMP2m_110_HTGL,SurfPressure.Pa = PRESsfc_110_SFC) %>% 
  dplyr::mutate(RelHum = 100*SpecHumidity.kg_kg/qsat(AirTemp2m-273.15, SurfPressure.Pa*0.01),
                WindSpeed.m_s=sqrt(WindSpeed_Zonal^2+WindSpeed_Meridional^2),
                AirTemp.C = AirTemp2m - 273.15, 
                Rain.m_day = Precipitation*24/1000) %>% 
  dplyr::select(dateTime,AirTemp.C,ShortWave.W_m2,LongWave.W_m2,
                SpecHumidity.kg_kg,RelHum,WindSpeed.m_s,Rain.m_day,SurfPressure.Pa)
write.csv(drivers,paste0(LakeName,'_Final/',LakeName,'_1980_2019_box_',box,'_CT.csv'),row.names = F, quote = F)


# Change time zone to Central Time 
drivers_CT = drivers %>% mutate(dateTime = dateTime - hours(6))
write.csv(drivers_CT,paste0(LakeName,'_Final/',LakeName,'_1980_2019_box_',box,'_CT.csv'),row.names = F, quote = F)
# Check for duplicates 
drivers_CT %>% 
  group_by(dateTime) %>% 
  filter(n()>1)

plot(drivers$dateTime,drivers$Rain,type = 'l')
plot(drivers$dateTime,drivers$ShortWave,type = 'l')


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

