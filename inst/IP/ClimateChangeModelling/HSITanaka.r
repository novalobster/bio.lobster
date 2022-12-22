#HSI Following Tanaka

require(bio.lobster)
require(bio.utilities)
require(lubridate)
require(devtools)
require(dplyr)
require(ggplot2)
options(stringAsFactors=F)
la()


fd=file.path(project.datadirectory('bio.lobster'),'analysis','ClimateModelling')
dir.create(fd,showWarnings=F)
setwd(fd)
sf_use_s2(FALSE) #needed for cropping

survey = readRDS(file=file.path(project.datadirectory('bio.lobster'),'data','BaseDataForClimateModelSize.rds'))
sf_use_s2(FALSE) #needed for cropping

# Project our survey data coordinates:

survey$lZ = log(survey$z)
survey = subset(survey,!is.na(lZ))

#what is the right offset for gear
#km2 for tows is estimated from sensors
#km2 for traps from Watson et al 2009 NJZ MFR 43 1 -- home radius of 17m, bait radius of 11m == 28m 'attraction zone'
# pi*(.014^2) # assuming traps are independent
survey$W = ceiling(yday(survey$DATE)/366*25)

mi= readRDS(file=file.path(project.datadirectory('bio.lobster'),'analysis','ClimateModelling','tempCatchability.rds'))

mi = mi[,c('temp','res')]
names(mi) = c('GlT','OFFSETcorr')
mi$GlT = round(mi$GlT,1)
mi = aggregate(OFFSETcorr~GlT,data=mi,FUN=mean)
survey$GlT = round(survey$GlT,1)
survey = dplyr::full_join(survey,mi)
survey$OFFSETcorr[which(survey$GlT< -.7)] <- 0
survey$OFFSETcorr[which(survey$GlT> 17)] <- 1

i = which(survey$OFFSET_METRIC == 'Number of traps')
survey$OFFSET[i] = survey$OFFSET[i] * pi*(.014^2) * survey$OFFSETcorr[i]

survey$LO = log(survey$OFFSET)
survey = subset(survey,OFFSET>0.00001 & OFFSET< 0.12)
survey$BT = survey$GlT

#defining groups

rL = readRDS(file.path( project.datadirectory("bio.lobster"), "data","maps","LFAPolysSF.rds"))
rL = st_as_sf(rL)
st_crs(rL) <- 4326
rL = st_transform(rL,32620) 
st_geometry(rL) <- st_geometry(st_as_sf(rL$geometry/1000)) 
	st_crs(rL) <- 32620


ff = st_join(survey,rL,join=st_within)
ff = st_as_sf(ff,)

saveRDS(ff,'HSIData.rds')

