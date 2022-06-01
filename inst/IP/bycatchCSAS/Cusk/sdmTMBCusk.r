#Make sure to run 0.RunMeFirst.R and 5.CreateMesh_DataforModellingLFA33-35.R
rm(aT,be,bspde)
u = readRDS(file='results/dataForLFA33-35.rds')

aT = u$data
bspde = u$grid
be = u$predshsetting up for sdmTMB

 fit = sdmTMB(CuskWt~
 				s(lZ,k=5)+DID,
 				data=aT,
 				#time='WOS',
 				#extra_time=c(33), 
 				mesh=bspde, 
 				family=tweedie(link='log'),
 				spatial='on',
 				#spatialtemporal='ar1'
 				)

 tidy(fit, conf.int = TRUE)
tidy(fit, effects = "ran_pars", conf.int = TRUE)
#plot_smooth(fit, ggplot = TRUE)


be = subset(be,WOS==1)
g = predict(fit)
g$pred = fit$family$linkinv(g$est)


saveRDS(list(g),file='CusksdmTMB.rds')

g = predict(fit,newdata=be,nsim=50)
g1 = fit$family$linkinv(g)

be$pred = apply(g1,1,median)
be$sd = apply(g1,1,sd)
be$lQ = apply(g1,1,quantile,0.25)
be$uQ = apply(g1,1,quantile,0.75)

gsf = st_as_sf(be,coords = c("X","Y"),crs=32619,remove=F)


saveRDS(list(fit,be),file='CusksdmTMBsims.rds')
#r = readRDS(file='lobstersdmTMB.rds')
#fit=r[[1]]
#g=r[[2]]

png('Figures/ModelOutput/CusksdmTMB.png')
mm = c(0.,max(gsf$pred))
ggplot(subset(gsf,WOS %in% 1)) +
			geom_sf(aes(fill=pred,color=pred)) + 
			scale_fill_viridis_c(trans='sqrt',limits=mm) +
			scale_color_viridis_c(trans='sqrt',limits=mm) +
			#facet_wrap(~WOS) +
 			theme( axis.ticks.x = element_blank(),
        		   axis.text.x = element_blank(),
				   axis.title.x = element_blank(),
				   axis.ticks.y = element_blank(),
        		   axis.text.y = element_blank(),
        		   axis.title.y = element_blank()
        		   ) +
 			coord_sf()
dev.off()

ag = aggregate(cbind(pred,lQ,uQ)~SID+PID,data=be,FUN=mean)



ef = readRDS('results/BumpedUpEffortByGridNUM.rds')
ef = subset(ef,LFA %in% 33:35)
ef = aggregate(cbind(BTTH, BlTH,BuTH)~GRID_NUM+LFA,data=ef,FUN=function(x) sum(x)/3)
names(ef)[c(1,2)] = c('SID','PID')

ff = merge(ag,ef)

ff$L = ff$pred*ff$BTTH
ff$Ll = ff$lQ*ff$BTTH
ff$Lu = ff$uQ*ff$BTTH

L = aggregate(cbind(L,Ll,Lu)~PID,data=ff,FUN=sum)
