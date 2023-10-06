#
require(devtools)
require(bio.lobster)
require(bio.utilities)
require(sf)
load_all('C:/Users/Cooka/Documents/git/bio.utilities')


la()
wd = ('C:\\Users\\Cooka\\OneDrive - DFO-MPO\\CanUsCollabEffortMapping')
setwd(wd)


layerDir=file.path(project.datadirectory("bio.lobster"), "data","maps")
r<-readRDS(file.path( layerDir,"GridPolysSF.rds"))
r = st_as_sf(r)

a =  lobster.db('process.logs')
a = subset(a,SYEAR>2004 & SYEAR<2023)
b = lobster.db('seasonal.landings')
b = subset(b,!is.na(SYEAR))
b$SYEAR = 1976:2023
b$LFA38B <- NULL
b = subset(b,SYEAR>2004 & SYEAR<2023)
b = reshape(b,idvar='SYEAR', varying=list(2:6),direction='long')
b$LFA=rep(c(33,34,35,36,38),each=18)
b$time <- NULL
names(b)[1:2]=c('YR','SlipLand')


d = lobster.db('annual.landings')
d = subset(d,YR>2004 & YR<2023, select=c(YR,LFA27,LFA28,LFA29,LFA30,LFA31A,LFA31B,LFA32))
d = reshape(d,idvar='YR', varying=list(2:8),direction='long')
d$LFA=rep(c(27,28,29,30,'31A','31B',32),each=18)
d$time <- NULL
names(d)[1:2]=c('YR','SlipLand')
bd = rbind(d,b)

bup = aggregate(cbind(WEIGHT_KG,NUM_OF_TRAPS)~SYEAR+LFA,data=a,FUN=sum)
bup$CPUE = bup$WEIGHT_KG/bup$NUM_OF_TRAPS
bAll = merge(bd,bup,by.x=c('YR','LFA'),by.y=c('SYEAR','LFA'))

sL= split(a,f=list(a$LFA, a$SYEAR))
sL = rm.from.list(sL)
cpue.lst<-list()
cpue.ann = list()

  for(i in 1:length(sL)){
    tmp<-sL[[i]]
    tmp = tmp[,c('DATE_FISHED','WEIGHT_KG','NUM_OF_TRAPS')]
    names(tmp)<-c('time','catch','effort')
    tmp$date<-as.Date(tmp$time)
    first.day<-min(tmp$date)
    tmp$time<-julian(tmp$date,origin=first.day-1)
    g<-biasCorrCPUE(tmp,by.time = F)
    cpue.lst[[i]] <- c(lfa=unique(sL[[i]]$LFA),yr = unique(sL[[i]]$SYEAR),g)
  }
  
  cc =as.data.frame(do.call(rbind,cpue.lst))
  
cAll = merge(bAll,cc,by.x=c('LFA','YR'),by.y=c('lfa','yr'))

cAll$NTRAPs = cAll$SlipLand*1000/as.numeric(cAll$unBCPUE)
cAll$NTRAPSU = cAll$SlipLand*1000/as.numeric(cAll$l95)
cAll$NTRAPSL = cAll$SlipLand*1000/as.numeric(cAll$u95)


###########################################
#part the effort to grids

partEffort = list()

for(i in 1:length(sL)){
  tmp = sL[[i]]
  tTH = aggregate(NUM_OF_TRAPS~LFA,data=tmp,FUN=sum)
  tC = subset(cAll, LFA==unique(tmp$LFA) & YR == unique(tmp$SYEAR)) 
  pTH = aggregate(NUM_OF_TRAPS~GRID_NUM+LFA+SYEAR,data=tmp,FUN=sum)
  pTH$BTTH = pTH$NUM_OF_TRAPS / tTH$NUM_OF_TRAPS * tC$NTRAPs
  pTH$BlTH = pTH$NUM_OF_TRAPS / tTH$NUM_OF_TRAPS * tC$NTRAPSL
  pTH$BuTH = pTH$NUM_OF_TRAPS / tTH$NUM_OF_TRAPS * tC$NTRAPSU
  
  partEffort[[i]] = pTH
}

partEffort = do.call(rbind, partEffort)

#pe = merge(partEffort,r,by.x=c('GRID_NUM','LFA'),by.y=c('GRID_NO','LFA'))

saveRDS(partEffort,'DiscretizedData/TrapHaulsWithinGrid.rds')


#############################################
# PartitionLandings to Grids

partLandings = list()

for(i in 1:length(sL)){
  tmp = sL[[i]]
  tTH = aggregate(WEIGHT_KG~LFA,data=tmp,FUN=sum)
  tC = subset(cAll, LFA==unique(tmp$LFA) & YR == unique(tmp$SYEAR)) 
  pTH = aggregate(WEIGHT_KG~GRID_NUM+LFA+SYEAR,data=tmp,FUN=sum)
  pTH$BL = pTH$WEIGHT_KG / (tTH$WEIGHT_KG )* (tC$SlipLand*1000)
  partLandings[[i]] = pTH
}

partLandings = do.call(rbind, partLandings)

saveRDS(partLandings,'DiscretizedData/LandingsWithinGrid.rds')

###################################################
##Licenses By Grid and Week

g = lobster.db('process.logs')
g = subset(g,SYEAR>2004 & SYEAR<2023)

gg = aggregate(SD_LOG_ID~LFA+GRID_NUM+SYEAR,data = g,FUN=function(x) length(unique(x)))

saveRDS(gg,'DiscretizedData/SDLOGSWithinGrid.rds')

#############merge


Tot = merge(merge(partEffort,partLandings),gg)

Tot = subset(Tot,select=c(SYEAR,LFA,GRID_NUM,BTTH,BL,SD_LOG_ID))
names(Tot)= c('FishingYear','LFA','Grid','TrapHauls','Landings','Trips')
Tot$PrivacyScreen = ifelse(Tot$Trips>4,1,0)

 # we lose 149
saveRDS(Tot,'DiscretizedData/PrivacyScreened_TrapHauls_Landings_Trips_Gridand.rds')

#making plots of Tot

eL = split(Tot,f=list(Tot$LFA,Tot$FishingYear))
eL = rm.from.list(eL)
eLm = aggregate(TrapHauls~LFA,data=Tot,FUN=function(x) quantile(x, seq(0.01,0.99,length.out = 7)))

gr = list()

for(i in 1:length(eL)){
  u = unique(eL[[i]]$LFA)
  k = subset(eLm,LFA==u)
  lv = c(0,round(unlist(k[2:length(k)])/10)*10)
  w = lobGridPlot(eL[[i]][,c('LFA','Grid','TrapHauls')],FUN=max,lvls=lv,cuts=T)$pdata
  w$yR = unique(eL[[i]]$FishingYear)
  gr[[i]] = w
}

o = do.call(rbind,gr)
oi = unique(o$PID)

for(i in 1:length(oi)){
  k = which(o$PID==oi[i])
  l = max(o$cuts[k])
  o$cuts[intersect(which(o$cuts==l),k)] = max(o$Z[k])
}

names(o)[1:2] <- c('LFA','GRID_NO')

x =  subset(o,LFA==27)
ux = c(min(x$Z),max(x$Z))

ggLobsterMap('27',bathy=T,attrData = subset(o,LFA==27&yR>2018),fw='yR',legLab='TrapHauls',addLFALabels = F,brks=ux)

x =  subset(o,LFA==29)
ux = c(min(x$Z),max(x$Z))
ggLobsterMap('29',bathy=T,attrData = subset(o,LFA==29&yR>2018),fw='yR',legLab='TrapHauls',addLFALabels = F,brks=ux)




##############################################################################################
#by Port#

partEffortCC = list()

for(i in 1:length(sL)){
  tmp = sL[[i]]
  tTH = aggregate(NUM_OF_TRAPS~LFA,data=tmp,FUN=sum)
  tC = subset(cAll, LFA==unique(tmp$LFA) & YR == unique(tmp$SYEAR)) 
  pTH = aggregate(NUM_OF_TRAPS~COMMUNITY_CODE+LFA+SYEAR,data=tmp,FUN=sum)
  pTH$BTTH = pTH$NUM_OF_TRAPS / tTH$NUM_OF_TRAPS * tC$NTRAPs
  pTH$BlTH = pTH$NUM_OF_TRAPS / tTH$NUM_OF_TRAPS * tC$NTRAPSL
  pTH$BuTH = pTH$NUM_OF_TRAPS / tTH$NUM_OF_TRAPS * tC$NTRAPSU
  
  partEffortCC[[i]] = pTH
}

partEffortCC = do.call(rbind, partEffortCC)
saveRDS(partEffortCC,'DiscretizedData/TrapHaulsWithinCommunityCode.rds')

partLandingsCC = list()

for(i in 1:length(sL)){
  tmp = sL[[i]]
  tTH = aggregate(WEIGHT_KG~LFA,data=tmp,FUN=sum)
  tC = subset(cAll, LFA==unique(tmp$LFA) & YR == unique(tmp$SYEAR)) 
  pTH = aggregate(WEIGHT_KG~COMMUNITY_CODE+LFA+SYEAR,data=tmp,FUN=sum)
  pTH$BL = pTH$WEIGHT_KG / (tTH$WEIGHT_KG )* (tC$SlipLand*1000)
  partLandingsCC[[i]] = pTH
}

partLandingsCC = do.call(rbind, partLandingsCC)

saveRDS(partLandingsCC,'DiscretizedData/LandingsWithinCommunity.rds')

###################################################
##Trips By Grid and Week

g = lobster.db('process.logs.unfiltered')
g = subset(g,SYEAR>2004 & SYEAR<2023)

gg = aggregate(SD_LOG_ID~LFA+COMMUNITY_CODE+SYEAR,data = g,FUN=function(x) length(unique(x)))

saveRDS(gg,'DiscretizedData/SDLOGSWithinCommunity.rds')


###################################################
##Licenses By Grid and Week

g = lobster.db('process.logs')
g = subset(g,SYEAR>2004 & SYEAR<2023)

gKL = aggregate(LICENCE_ID~LFA+COMMUNITY_CODE+SYEAR,data = g,FUN=function(x) length(unique(x)))

saveRDS(gKL,'DiscretizedData/LicencesWithinCommunity.rds')

#############merge


TotCC = merge(merge(merge(partEffortCC,partLandingsCC),gg),gKL)

TotCC = subset(TotCC,select=c(SYEAR,LFA,COMMUNITY_CODE,BTTH,BL,SD_LOG_ID,LICENCE_ID))
names(TotCC)= c('FishingYear','LFA','Community','TrapHauls','Landings','Trips','NLics')

TotCC$PrivacyScreen = ifelse(TotCC$NLics>4,1,0)

saveRDS(TotCC,'DiscretizedData/PrivacyScreened_TrapHauls_Landings_Trips_Comunity.rds')


#maps with community code

pl = lobster.db('port_location')
pl = subset(pl, !is.na(CENTLAT) & CENTLAT>40)
pl = st_as_sf(pl,coords = c('CENTLON','CENTLAT'),crs=4326)
ggplot()+geom_sf(data=pl)

###oct 6 2023 this wont work for 35 
uu = unique(TotCC$Community)
uni = uu[which(uu %ni% pl$PORT_CODE )]
 subset(pl,PORT_CODE %in% uni)

 ###
 PortLandings = merge(TotCC,pl,by.x=c('Community','LFA'),by.y=c('PORT_CODE',"LFA"))
  PL = st_as_sf(PortLandings)
 
  
  
 ok = ggLobsterMap('custom',xlim=c(-60.8,-59.6),ylim=c(45.55,47.1),return.object = T,colourLFA = F,fill.colours = 'white')
 
 br = as.numeric(with(subset(PL,FishingYear>2018 & LFA==27 & PrivacyScreen==1),round(quantile(NLics,seq(0,1,length.out=6)))))
 labs = paste(br[-length(br)],'-',br[-1],sep='')
 PL$breaks = cut(PL$NLics,breaks=br,labels=labs)
 mp<- colorRampPalette("YlOrRd")(5)
 
 ok1 = ok+geom_sf(data=subset(PL,FishingYear>2018 & LFA==27), aes(color = breaks),size=2)+
   scale_color_manual(values=mp) +
   facet_wrap(~FishingYear)+
   guides(size=F)
 
 br = as.numeric(with(subset(PL,FishingYear>2018 & LFA==27 & PrivacyScreen==1),quantile(Landings,seq(0,1,length.out=6))))
 PL
 
 ok2 = ok+geom_sf(data=subset(PL,FishingYear>2018 & LFA==27 & PrivacyScreen==1), aes(color = Landings),size=2)+
   scale_fill_brewer(palette='Greens',breaks=br) +
   geom_sf(data=subset(PL,FishingYear>2018 & LFA==27 & PrivacyScreen==0), color = 'pink',size=2)+
   facet_wrap(~FishingYear)+
   guides(size=F)
 
 
 width_inch <- 8.5 * 0.8  # 80% of the paper width
 height_inch <- 11 * 0.8  # 80% of the paper height
 
 # Save the plot with the specified dimensions
 ggsave("my_plot.png", plot = ok1, width = width_inch, height = height_inch, units = "in") 
    

 
 