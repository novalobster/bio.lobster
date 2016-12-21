#habitat model

			      p = bio.lobster::load.environment()
	require(bio.lobster)
	require(bio.utilities)
	loadfunctions('bio.utilities')
	loadfunctions('bio.temperature')
	loadfunctions('bio.habitat')
	loadfunctions('bio.indicators')
	loadfunctions('bio.spacetime')
require(dismo)
require(gbm)	
	#Prediction surface



	
require(mgcv)
	la()

	p$years = c(1969:2015)

	b = habitat.model.data('nefsc.surveys',p=p)
	a = habitat.model.data('dfo.summer',p=p)
	d = habitat.model.data('dfo.georges',p=p)
	pre = habitat.model.data('dfo.georges',p=p)


dat = rbind(a,b,d)
	dat$yr = year(dat$timestamp)
	dat$z = log(dat$z)
	      #cant run    bM = formula( Y ~ te(dyear, bs="cs" ) + te(t, bs ='cs') + te(ddZ, bs="cs" )
	       #     + te(z,bs='cs') + te(dZ, bs="cs" )  + te(substrate.mean, bs="cs" )             
	      #     + te(plon, plat, k=100, bs="cs", by=as.factor(yr) ) + as.factor(yr)  )

save(dat,file=file.path(project.datadirectory('bio.lobster'),'analysis','habitatmodellingdata.rdata'))

###GAM
    bM = formula( Y ~ s(dyear, bs="cr" ) + s(t, bs ='cr') + 
	            + s(z,bs='cr') + s(dZ, bs="cr" )         
	            + ti(plon, plat, k=40, bs="cs") + as.factor(yr)  )



	dat$Y = ifelse(dat$B>0,1,0)
#	dat = subset(dat,yr %in% 1999:2016)

			   W = bam( bM, data=dat, family=binomial())
			   #model started on hyperion 901am Sept6 using screen finished sometime between friday night and monday am
			   save(W,file='/backup/bio_data/bio.lobster/R/LobitatModelSept122016.rdata') 

load(file='/backup/bio_data/bio.lobster/R/LobitatModelSept122016.rdata') 

			   #screen -r to reattach
			   #ctrl-a d to detach



###Simple no space GAM
    bM = formula( Y ~ s(dyear, bs="cr" ) + s(t, bs ='cr') + 
	            + s(z,bs='cr') + s(dZ, bs="cr" )         
	            + s(yr)  )
	dat$Y = ifelse(dat$B>0,1,0)
#	dat = subset(dat,yr %in% 1999:2016)

			   W2 = bam( bM, data=dat, family=binomial())
			   #model started on hyperion 901am Sept6 using screen finished sometime between friday night and monday am
			   save(W,file='/backup/bio_data/bio.lobster/R/LobitatModelnospace') 

			   #screen -r to reattach
			   #ctrl-a d to detach

#temp by year			   

    bM = formula( Y ~ s(dyear, bs="cr" ) + s(t, bs ='cr',by=as.factor(yr)) + 
	            + s(z,bs='cr') + s(dZ, bs="cr" )         
	            + s(yr)  )



#	dat = subset(dat,yr %in% 1999:2016)

			   W3 = bam( bM, data=dat, family=binomial())



#Climate Envelop Model Booth 2014 Diversity and Distributions 20:1-9

require(dismo)
p = bio.lobster::load.environment()

load(file.path(project.datadirectory('bio.lobster'),'analysis','habitatmodellingdata.rdata'))
#presence only
	dat = dat[-24165,]
	dat$Y = ifelse(dat$B>0,1,0)
	
la()	
#prediction layer

dat.p = subset(dat,Y==1)
bc <- bioclim(dat.p[,c('dyear','t','z','dZ','ddZ')])

out = c()
for(i in 1:length(p$yrs)) {
		a = p$yrs[i]
		pI = J[,c('z','dZ','ddZ')]
		k = grep(a,names(J))
		pI = data.frame(pI,J[,k])
		names(pI)[ncol(pI)] <- 't'
		pI$dyear = p$dyear
		pI$z = log(pI$z)
		bcp = predict(bc,pI) 
		datarange = range( bcp[ which(is.finite(bcp))])
    	dr = seq( 0,1, length.out=100)
    	png(file=file.path(project.figuredirectory('bio.lobster'),paste('bioclim',a,'.png',sep="")),units='in',width=15,height=12,pointsize=18, res=300,type='cairo')
	o = levelplot(bcp~J$plon+J$plat,aspect='iso',xlim=c(-600,100),ylim=c(-450,100),at=dr,col.regions=color.code('blue.yellow.red',dr))
	print(o)
	dev.off()
	}

require(gbm)

#probability of occurence

#ignoring time and treating all years equally
dat$Y = ifelse(dat$B>0,1,0)
	aa <- gbm.step(data=na.omit(dat), gbm.x = c(1,5,6,7,8), gbm.y = 12, family = "bernoulli", tree.complexity = 5, learning.rate = 0.01, bag.fraction = 0.5) #bernoulli is same as binomial in this formulation


dyear = seq(0.1,1,0.1) #autumn 
p$yrs = unique(dat$yr)

outs = matrix(NA,ncol=length(dyear),nrow=length(p$yrs))

for(j in dyear) {
	p$dyear=j
	J = habitat.model.data('prediction.surface',p=p)
for(i in 1:length(p$yrs)) {
		a = p$yrs[i]
		pI = J[,c('z','dZ','ddZ')]
		k = grep(a,names(J))
		pI = data.frame(pI,J[,k])
		names(pI)[ncol(pI)] <- 't'
		pI$dyear = p$dyear
		pI$z = log(pI$z)
		ab = predict.gbm(aa,pI,n.trees = aa$gbm.call$best.trees,type='response')
		

		###need to prune to lfa41 and then calculate teh area above a threshold
		

		dr = seq( 0,1, length.out=100)
		if(p$dyear==0.8) {
    	png(file=file.path(project.figuredirectory('bio.lobster'),paste('boostedRegTree',a,'.png',sep="")),units='in',width=15,height=12,pointsize=18, res=300,type='cairo')
	o = levelplot(ab~J$plon+J$plat,aspect='iso',xlim=c(-600,100),ylim=c(-450,100),at=dr,col.regions=color.code('blue.yellow.red',dr))
	print(o)
	dev.off()
		}
	}
}

###using cotinuous time with decimal years
############playing with Dec 2016



dat$Y = ifelse(dat$B>0,1,0)
dat$Time = year(dat$timestamp) + dat$dyear
	aa2 <- gbm.step(data=na.omit(dat), gbm.x = c('Time','t','z','dZ','ddZ'), gbm.y = 'Y', family = "bernoulli", tree.complexity = 5, learning.rate = 0.01, bag.fraction = 0.5) #bernoulli is same as binomial in this formulation

save(aa2,file=file.path(project.datadirectory('bio.lobster'),'data','products','brtContinuousTime.rdata'))
load(file=file.path(project.datadirectory('bio.lobster'),'data','products','brtContinuousTime.rdata'))

dyear = seq(0.1,1,0.1) #autumn 
p$yrs = unique(dat$yr)

outs = matrix(NA,ncol=length(dyear),nrow=length(p$yrs))
p$annual.T.means=TRUE


	J = habitat.model.data('prediction.surface',p=p)
	
#Index of prediction surface within LFA41
	jj = J[,c('plon','plat')]
	jj$EID = 1:nrow(jj)
	names(jj)[1:2] <- c('X','Y')

#LFA41 polygon
	LFA41 = read.csv(file.path( project.datadirectory("bio.lobster"), "data","maps","LFA41Offareas.csv"))
	LFA41 = joinPolys(as.PolySet(LFA41),operation='UNION')
	LFA41 = subset(LFA41,SID==1)
	attr(LFA41,'projection') <- 'LL'
	aa = lonlat2planar(LFA41,input_names = c('X','Y'),proj.type = p$internal.projection)
	aa$plon = grid.internal(aa$plon,p$plons)
	aa$plat = grid.internal(aa$plat,p$plats)
	aa$X = aa$plon
	aa$Y = aa$plat

	s2 = findPolys(jj,aa,maxRows = 760000)
	s2 = subset(jj, EID %in% s2$EID)

outa = list()
outb = list()
for(i in 1:length(p$yrs)) {
		a = p$yrs[i]
		pI = J[,c('z','dZ','ddZ')]
		k = grep(a,names(J))
		pI = data.frame(pI,J[,k])
		names(pI)[ncol(pI)] <- 't'
		pI$dyear = p$dyear
		pI$z = log(pI$z)
		pI$Time= a+.0
		pI = pI
		ab = predict.gbm(aa2,pI,n.trees = aa2$gbm.call$best.trees,type='response')
		print(a)
		outa[[i]] = ab[s2$EID]
		###need to prune to lfa41 and then calculate teh area above a threshold
		
		dr = seq( 0,1, length.out=100)
		png(file=file.path(project.figuredirectory('bio.lobster'),paste('trial.continuousTimeboostedRegTree',a,'.png',sep="")),units='in',width=15,height=12,pointsize=18, res=300,type='cairo')
	o = levelplot(ab~J$plon+J$plat,aspect='iso',xlim=c(-600,100),ylim=c(-450,100),at=dr,col.regions=color.code('blue.yellow.red',dr))
	print(o)
	dev.off()
		}
	

###using time with decimal years



dat$Y = ifelse(dat$B>0,1,0)
dat$year = year(dat$timestamp)
	aa3 <- gbm.step(data=na.omit(dat), gbm.x = c('dyear','year','t','z','dZ','ddZ'), gbm.y = 'Y', family = "bernoulli", tree.complexity = 5, learning.rate = 0.01, bag.fraction = 0.5) #bernoulli is same as binomial in this formulation

save(aa3,file=file.path(project.datadirectory('bio.lobster'),'data','products','brtYearTime.rdata'))


dyear = seq(0.1,1,0.1) #autumn 
p$yrs = unique(dat$yr)

outs = matrix(NA,ncol=length(dyear),nrow=length(p$yrs))



	J = habitat.model.data('prediction.surface',p=p)
for(i in 1:length(p$yrs)) {
		a = p$yrs[i]
		pI = J[,c('z','dZ','ddZ')]
		k = grep(a,names(J))
		pI = data.frame(pI,J[,k])
		names(pI)[ncol(pI)] <- 't'
		pI$dyear = p$dyear
		pI$z = log(pI$z)
		pI$Time= a+.8
		ab = predict.gbm(aa3,pI,n.trees = aa2$gbm.call$best.trees,type='response')
		

		###need to prune to lfa41 and then calculate teh area above a threshold
		
		dr = seq( 0,1, length.out=100)
		png(file=file.path(project.figuredirectory('bio.lobster'),paste('decimalTimeboostedRegTree',a,'.png',sep="")),units='in',width=15,height=12,pointsize=18, res=300,type='cairo')
	o = levelplot(ab~J$plon+J$plat,aspect='iso',xlim=c(-600,100),ylim=c(-450,100),at=dr,col.regions=color.code('blue.yellow.red',dr))
	print(o)
	dev.off()
		}
	







##abundance


dat$Y = ifelse(dat$B>0,1,0)

	aa <- gbm.step(data=na.omit(dat), gbm.x = c(1,5,6,7,8), gbm.y = 12, family = "bernoulli", tree.complexity = 5, learning.rate = 0.01, bag.fraction = 0.5) #bernoulli is same as binomial in this formulation

