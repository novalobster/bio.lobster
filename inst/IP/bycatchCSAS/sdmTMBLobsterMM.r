setting up for sdmTMB

require(sdmTMB)
require(bio.lobster)
require(bio.utilities)
require(lubridate)
require(devtools)
require(dplyr)
require(ggplot2)
require(INLA)
options(stringAsFactors=F)
	require(PBSmapping)
require(SpatialHub)
require(sf)
la()

p = bio.lobster::load.environment()
p = spatial_parameters(type='canada.east')
wd = ('~/dellshared/Bycatch in the Lobster Fishery')

setwd(wd)




aA = read.csv(file=file.path('results','CompliedDataForModelling.csv'))
aA$X.1 = NULL
aA = subset(aA,X< -30 | Y>30)
aA$DATE_FISHED = as.Date(aA$DATE_FISHED)
attr(aA,'projection') = "LL"
aA = lonlat2planar(aA,input_names=c('X','Y'),proj.type = p$internal.projection)

	ba = lobster.db('bathymetry')
	locsmap = match( 
	array_map( "xy->1", aA[,c("plon","plat")], gridparams=p$gridparams ), 
	array_map( "xy->1", ba[,c("plon","plat")], gridparams=p$gridparams ) )

baXY = planar2lonlat(ba,proj.type=p$internal.projection)
	
aA$Depth = ba$z[locsmap]
i = which(aA$Depth<0)
aA = aA[-i,] 
i = which(aA$plon>0)
aA = aA[-i,] 
aA$DOS =  NA
i = which(aA$LFA %in% c(33,34,35))
j = which(aA$SYEAR %in% 2019)

k = intersect(i,j)
aA$DOS[k] = aA$DATE_FISHED[k] - min(aA$DATE_FISHED[k])

j = which(aA$SYEAR %in% 2020)

k = intersect(i,j)
aA$DOS[k] = aA$DATE_FISHED[k] - min(aA$DATE_FISHED[k])

j = which(aA$SYEAR %in% 2021)

k = intersect(i,j)
aA$DOS[k] = aA$DATE_FISHED[k] - min(aA$DATE_FISHED[k])


aT = as_tibble(aA)
aT$WOS = ceiling(aT$DOS/7)
####making mesh
						map_data <- rnaturalearth::ne_countries(
								   scale = "medium",
						        	returnclass = "sf", country = "canada")
						  
						     # Crop the polygon for plotting and efficiency:
						      st_bbox(map_data)
						      ns_coast <- suppressWarnings(suppressMessages(
						        st_crop(map_data,
						          c(xmin = -67, ymin = 42, xmax = -53, ymax = 46))))
						 crs_utm20 <- 2961
						     
						     st_crs(ns_coast) <- 4326 # 'WGS84'; necessary on some installs
						     ns_coast <- st_transform(ns_coast, crs_utm20)
						     
						     # Project our survey data coordinates:
						     survey <- aT %>%   st_as_sf(crs = 4326, coords = c("X", "Y")) %>%
						       st_transform(crs_utm20)
						     
						     # Plot our coast and survey data:
						     ggplot(ns_coast) +
						       geom_sf() +
						       geom_sf(data = survey, size = 0.5)
						     
						     # Note that a barrier mesh won't don't much here for this
						     # example data set, but we nonetheless use it as an example.
						     
						     # Prepare for making the mesh
						     # First, we will extract the coordinates:
						     surv_utm_coords <- st_coordinates(survey)
						     
						     # Then we will scale coordinates to km so the range parameter
						     # is on a reasonable scale for estimation:
						
						  aT$X1000 <- surv_utm_coords[,1] / 1000
						     aT$Y1000 <- surv_utm_coords[,2] / 1000
						     
						     spde <- make_mesh(aT, xy_cols = c("X1000", "Y1000"),
						       n_knots = 200, type = "kmeans")
						     plot(spde)
						     

						     # Add on the barrier mesh component:
						     bspde <- add_barrier_mesh(
						       spde, ns_coast, range_fraction = 0.1,
						       proj_scaling = 1000, plot = TRUE
						     )
						     
						     # In the above, the grey dots are the centre of triangles that are in the
						     # ocean. The red crosses are centres of triangles that are over land. The
						     # spatial range will be assumed to be 0.1 (`range_fraction`) over land compared
						     # to over water.
						     
						     # We can make a more advanced plot if we want:
						     mesh_df_water <- bspde$mesh_sf[bspde$normal_triangles, ]
						     mesh_df_land <- bspde$mesh_sf[bspde$barrier_triangles, ]
						     ggplot(ns_coast) +
						       geom_sf() +
						       geom_sf(data = mesh_df_water, size = 1, colour = "blue") +
						       geom_sf(data = mesh_df_land, size = 1, colour = "green")
						  
						 # the land are barrier triangles..

##prediction grids


     	gr<-read.csv(file.path( project.datadirectory("bio.lobster"), "data","maps","GridPolys.csv"))
		attr(gr,'projection') <- "LL"
		gr = subset(gr,PID %in% 33:35)
				baXY$EID = 1:nrow(ba)
				baXY$X = baXY$lon
				baXY$Y = baXY$lat
		ff = findPolys(baXY,gr,maxRows=dim(baXY)[1])
		baXY = merge(baXY,ff,by='EID')

				baXY$Depth = baXY$z	
	     baT <- baXY %>%     st_as_sf(crs = 4326, coords = c("lon", "lat")) %>%
							   #st_crop(c(xmin = -68, ymin = 42, xmax = -53, ymax = 47)) %>%						
						       st_transform(crs_utm20) 
		b = st_coordinates(baT)
		baT$X1000 = b[,1]/1000
		baT$Y1000 = b[,2]/1000
		baT$X = b[,1]
		baT$Y = b[,2]

		ba = baT[,c('X','Y','Depth','X1000','Y1000','SID','PID')]
		ba = subset(ba,Depth>5)
		ba$geometry <- NULL
		be = as.data.frame(sapply(ba,rep.int,41))
		be$WOS = rep(0:40,each=dim(ba)[1])
#LFAs for prediction grids

aT$LegWt10 = aT$LegalWt*10
fit0 =  sdmTMB(LegWt10~
 				s(Depth,k=5) + DID,
 				data=aT,
 				time='WOS', 
 				mesh=bspde, 
 				family=tweedie(link='log'),
 				spatial='on',
 				spatialtemporal='ar1'
 				)
 

 fit = sdmTMB(LegWt10~
 				s(Depth,k=5),
 				data=aT,
 				time='WOS', 
 				mesh=bspde, 
 				family=tweedie(link='log'),
 				spatial='on',
 				spatialtemporal='ar1'
 				)
g = predict(fit,newdata=be)



saveRDS(list(fit,g),file='lobstersdmTMBFull.rds')


 fit1 = sdmTMB(LegalWt~
 				s(Depth,k=5),
 				data=aT,
 				mesh=bspde, 
 				family=tweedie(link='log'),
 				spatial='on'
 				)
g1 = predict(fit1,newdata=be)



saveRDS(list(fit1,g1),file='lobstersdmTMBSpace.rds')



 fit2 = sdmTMB(LegalWt~
 				s(Depth,k=5),
 				data=aT,
 				mesh=bspde, 
 				family=tweedie(link='log'),
 				spatial='off'
 				)
g2 = predict(fit2,newdata=be)



saveRDS(list(fit2,g2),file='lobstersdmTMBDepth.rds')




AIC(fit)
AIC(fit1)
AIC(fit2)

aT = cv_SpaceTimeFolds(aT,idCol = 'TRIP',nfolds=5)
aT$LegWt10=aT$LegalWt*10

 fit_cv = sdmTMB_cv(LegWt10~
 				s(Depth,k=5)+DID,
 				data=aT,
 				time='WOS', 
 				mesh=bspde, 
 				family=tweedie(link='log'),
 				spatial='on',
 				fold_ids = 'fold_id',
 				spatialtemporal='ar1',
 				k_folds=5,
 				constant_mesh=F)
 				

fit1_cv = sdmTMB_cv(LegWt10~
				s(Depth,k=5)+DID,
				data=aT,
				mesh=bspde, 
				family=tweedie(link='log'),
				spatial='on',
				fold_ids = 'fold_id',
				k_folds=5,
				constant_mesh=F
				)

fit2_cv = sdmTMB_cv(LegWt10~
				s(Depth,k=5),
				data=aT,
				mesh=bspde, 
				family=tweedie(link='log'),
				spatial='off',
				fold_ids = 'fold_id',
				k_folds=5,
				constant_mesh=F
				)


fit3_cv = sdmTMB_cv(LegWt10~
 				s(Depth,k=5) + DID,
 				data=aT,
 				mesh=bspde, 
 				family=tweedie(link='log'),
 				spatial='off',
 				fold_ids = 'fold_id',
 				k_folds=5,
 				constant_mesh=F
 				)

mae<- function(x,y){
	sum(abs(x-y))/length(x)
}

rmse = function(x,y){
	sqrt((sum(y-x)^2)/length(x))

}

with(fit_cv$data,mae(as.numeric(LegWt10),as.numeric(cv_predicted)))

with(fit1_cv$data,mae(as.numeric(LegWt10),as.numeric(cv_predicted)))

with(fit2_cv$data,mae(as.numeric(LegWt10),as.numeric(cv_predicted)))

with(fit3_cv$data,mae(as.numeric(LegWt10),as.numeric(cv_predicted)))


with(fit_cv$data,rmse(as.numeric(LegWt10),as.numeric(cv_predicted)))

with(fit1_cv$data,rmse(as.numeric(LegWt10),as.numeric(cv_predicted)))

with(fit2_cv$data,rmse(as.numeric(LegWt10),as.numeric(cv_predicted)))

with(fit3_cv$data,rmse(as.numeric(LegWt10),as.numeric(cv_predicted)))



#highest elpd has predictions closest to those from true generating process

fit_cv$elpd
fit1_cv$elpd
fit2_cv$elpd

	sfit = simulate(fit,nsim=100) 
	rf = dharma_residuals(sfit,fit)

r <- dharma_residuals(sfit, fit, plot = FALSE)

     plot(r$expected, r$observed)
     abline(a = 0, b = 1)


 r1 = fit$family$linkinv(predict(fit))
 r2 = DHARMa::createDHARMa(simulatedResponse=sfit,
 									observedResponse=fit$data$LegWt10,
 									fittedPredictedResponse=r1)

 plot(r2)
aT$SRS = r2$scaledResiduals
	ggplot(data=ns_coast) + geom_sf() +
			geom_point(data = subset(aT,WOS %in% 1:42),aes(x = X1000*1000, y = Y1000*1000,colour = SRS), shape = 19,size=0.3) +
			facet_wrap(~WOS) +
			scale_colour_gradient2(midpoint=.5,low='blue',mid='white',high='red',space='Lab')

