#figureLengthFreqs
require(bio.lobster)
la()

a = c(        file.path(project.datadirectory('bio.lobster'),'analysis','LengthFrequenciesLFA41baseSummerRV.rdata  '),  
			  file.path(project.datadirectory('bio.lobster'),'analysis','LengthFrequenciesLFA41polygonSummerRV.rdata  '),
		      file.path(project.datadirectory('bio.lobster'),'analysis','LengthFrequenciesLFA41adjacentpolygonSummerRV.rdata  '),
			  file.path(project.datadirectory('bio.lobster'),'analysis','LengthFrequenciesLFA41NEFSCspringbase.rdata  '),
	    	  file.path(project.datadirectory('bio.lobster'),'analysis','LengthFrequenciesLFA41NEFSCspringrestratified.rdata  '),
      		  file.path(project.datadirectory('bio.lobster'),'analysis','LengthFrequenciesLFA41NEFSCspringadjrestratified.rdata  '),
   		      file.path(project.datadirectory('bio.lobster'),'analysis','LengthFrequenciesLFA41NEFSCfallbase.rdata  '),
		      file.path(project.datadirectory('bio.lobster'),'analysis','LengthFrequenciesLFA41NEFSCfallrestratified.rdata  '),
              file.path(project.datadirectory('bio.lobster'),'analysis','LengthFrequenciesLFA41NEFSCfalladjrestratified.rdata  '),
   			  file.path(project.datadirectory('bio.lobster'),'analysis','LengthFrequenciesLFA41dfogeorges.rdata  '))
    	
for(i in 1:length(a)) {
		out = c()
	load(a[i])
	if(grepl('NEFSC',a[i])) {
		aa <- aa[which(aa$FLEN>49),]
		print(i)
	}
	yll = max(aa$n.yst)
	af = aggregate(ObsLobs~yr,data=aa,FUN=sum)
	names(af) = c('x','y')
	h = split(aa,f=aa$yr)
	for(j in 1:length(h)) {
			g = h[[j]]
			g$ff = round(g$FLEN/3)*3
			y = unique(g$yr)
			u = aggregate(n.yst~ff,data=g,FUN=sum)              
			fn = paste(strsplit(strsplit(a[i],"/")[[1]][6],"\\.")[[1]][1],y,'pdf',sep=".")
            nn = sum(g$ObsLobs)
            pdf(file.path(project.figuredirectory('bio.lobster'),fn))
			plot(u$ff,u$n.yst,lwd=3,xlab='Carapace Length',ylab = 'Stratified Mean Number',type='h',ylim=c(0,yll))
			legend('topleft',bty='n',pch="", legend=c(y,paste('N=',nn,sep=" ")),cex=2)
			dev.off()
			print(fn)
			lm = median(rep(g$FLEN,times=g$n.yst*1000))
			ll = quantile(rep(g$FLEN,times=g$n.yst*1000),0.25)
			lu = quantile(rep(g$FLEN,times=g$n.yst*1000),0.75)
			
			out = rbind(out,c(y,lm,ll,lu))
			}
			out = as.data.frame(out)
			names(out) = c('yr','medL','medLlower','medLupper')

				p=list()
			                  p$add.reference.lines = F
                              p$time.series.start.year = min(aa$yr)
                              p$time.series.end.year = max(aa$yr)
                              p$metric = 'medianL' #weights
                              p$measure = 'stratified.mean' #'stratified.total'
                              p$figure.title = ""
                              p$reference.measure = 'median' # mean, geomean
                              p$file.name = paste('medianL',strsplit(strsplit(a[i],"/")[[1]][6],"\\.")[[1]][1],'png',sep=".")
    		                  print(p$file.name)

                        p$y.maximum = NULL # NULL # if ymax is too high for one year
                        p$show.truncated.numbers = F #if using ymax and want to show the numbers that are cut off as values on figure
                        		p$ylim = c(60,155)
                                p$legend = FALSE
                                p$running.median = T
                                p$running.length = 3
                                p$running.mean = F #can only have rmedian or rmean
                               p$error.polygon=T
                              p$error.bars=F

                              p$ylim2 = c(0,500)
                             
                       figure.stratified.analysis(x=out,out.dir = 'bio.lobster', x2 = af, p=p,sampleSizes=T)
		}



###Length Freqs divided into five breaks with the last year being isolated for comparison

require(bio.lobster)
la()

a = c(        file.path(project.datadirectory('bio.lobster'),'analysis','LengthFrequenciesLFA41baseSummerRV.rdata  '),  
			  file.path(project.datadirectory('bio.lobster'),'analysis','LengthFrequenciesLFA41polygonSummerRV.rdata  '),
		      file.path(project.datadirectory('bio.lobster'),'analysis','LengthFrequenciesLFA41adjacentpolygonSummerRV.rdata  '),
			  file.path(project.datadirectory('bio.lobster'),'analysis','LengthFrequenciesLFA41NEFSCspringbase.rdata  '),
	    	  file.path(project.datadirectory('bio.lobster'),'analysis','LengthFrequenciesLFA41NEFSCspringrestratified.rdata  '),
      		  file.path(project.datadirectory('bio.lobster'),'analysis','LengthFrequenciesLFA41NEFSCspringadjrestratified.rdata  '),
   		      file.path(project.datadirectory('bio.lobster'),'analysis','LengthFrequenciesLFA41NEFSCfallbase.rdata  '),
		      file.path(project.datadirectory('bio.lobster'),'analysis','LengthFrequenciesLFA41NEFSCfallrestratified.rdata  '),
              file.path(project.datadirectory('bio.lobster'),'analysis','LengthFrequenciesLFA41NEFSCfalladjrestratified.rdata  '),
   			  file.path(project.datadirectory('bio.lobster'),'analysis','LengthFrequenciesLFA41dfogeorges.rdata  '))
    	
for(i in 1:length(a)) {
	load(a[i])
	if(grepl('NEFSC',a[i])) {
		aa <- aa[which(aa$FLEN>49),]
		print(i)
	}
	
	af = aggregate(ObsLobs~yr,data=aa,FUN=sum)
	names(af) = c('x','y')
	YG = 5 # year grouping
	y = unique(aa$yr)
	yL = y[length(y)] #last year
	yLL = length(y)-1
	yLm = yLL %% YG
	yLr = yLL %/% YG
	yw = y[which(y %in% y[1:yLm])] #add the early years to the first histogram and keep the rest at 5 years
	
	yLw = c(rep(1,yLm),rep(1:yLr,each = YG),yLr+1)
	grps = data.frame(yr = y,ry = yLw)
	aa = merge(aa,grps,by='yr',all.x=T)
	aa$ff = round(aa$FLEN/3)*3
	yll = max(aggregate(n.yst~ff+ry,data=aa,FUN=mean)$n.yst)
	yll = 1
	h = split(aa,f=aa$ry)
	
	for(j in 1:length(h)) {
			g = h[[j]]
			
			y = unique(g$yr)
			u = aggregate(n.yst~ff,data=g,FUN=mean)              
			u$n.yst = u$n.yst / max(u$n.yst)
			fn = paste(strsplit(strsplit(a[i],"/")[[1]][6],"\\.")[[1]][1],min(y),max(y),'pdf',sep=".")
            nn = sum(g$ObsLobs)
            pdf(file.path(project.figuredirectory('bio.lobster'),fn))
			plot(u$ff,u$n.yst,lwd=3,xlab='Carapace Length',ylab = 'Scaled Stratified Mean Number',type='h',ylim=c(0,yll))
			abline(v=82.5,lty=2,col='red')
			legend('topleft',bty='n',pch="", legend=c(paste(min(y),max(y),sep="-"),paste('N=',nn,sep=" ")),cex=1.5)
			dev.off()
			print(fn)
			}
		}

