


require(bio.survey)
require(bio.lobster)
require(bio.groundfish)
la()

p = bio.lobster::load.environment()
p$libs = NULL
fp1 = file.path(project.datadirectory('bio.lobster'),"analysis","LFA34-38")
fpf1 = file.path(project.figuredirectory('bio.lobster'),"LFA3438Framework2019")

load_all('~/git/bio.survey/')
p1 = p


stratifiedAnalysesRecruits = function(p=p1, survey,lfa, fpf = fpf1, fp = fp1){

#NEFSC Setup
if(survey=='NEFSC'){
      p$reweight.strata = F #this subsets 
      p$years.to.estimate = c(1969:2018)
      p$length.based = T
      p$size.class= c(50,82)
      p$by.sex = T
      p$sex = c(1,2) # male female berried c(1,2,3)
      p$bootstrapped.ci=T
      p$strata.files.return=F
      p$strata.efficiencies=F
      p$clusters = c( rep( "localhost", 7) )
    p = make.list(list(yrs=p$years.to.estimate),Y=p)
   
      p$season =c('spring')# p$series =c('spring');p$series =c('fall')
      p$define.by.polygons = T
      p$lobster.subunits=F
      p$area = lfa
      p$reweight.strata = T #this subsets 
      
   aout= nefsc.analysis(DS='stratified.estimates.redo',p=p)


                              #Figure
                              p$add.reference.lines = F
                              p$time.series.start.year = p$years.to.estimate[1]
                              p$time.series.end.year = p$years.to.estimate[length(p$years.to.estimate)]
                              p$metric = 'numbers' #numbers
                              p$measure = 'stratified.mean' #'stratified.total'
                              p$figure.title = ""
                              p$reference.measure = 'median' # mean, geomean
                              p$file.name =  file.path('LFA3438Framework2019',paste(lfa,'NEFSCSpringrestratifiednumbersrecruits.png',sep=''))

                          p$y.maximum = NULL # NULL # if ymax is too high for one year
                        p$show.truncated.numbers = F #if using ymax and want to show the numbers that are cut off as values on figure

                                p$legend = FALSE
                                p$running.median = T
                                p$running.length = 3
                                p$running.mean = F #can only have rmedian or rmean
                               p$error.polygon=F
                              p$error.bars=T
                       p$ylim2 = c(0,500)
                        xx = aggregate(ObsLobs~yr,data=aout,FUN=sum)
                              names(xx) =c('x','y')
                              p$ylim=c(0,2)
                       
                       ref.out=   figure.stratified.analysis(x=aout,out.dir = 'bio.lobster', p=p, x2 = xx, sampleSizes=T)
                              p$ylim=NULL
                    p$file.name =  file.path('LFA3438Framework2019',paste(lfa,'NOYNEFSCSpringrestratifiednumbersrecruits.png'))
                      ref.out=   figure.stratified.analysis(x=aout,out.dir = 'bio.lobster', p=p, x2 = xx, sampleSizes=T)
                      
     
aout$subset = 'NEFSCSpringrecruits'
write.csv(aout,file=file.path(fp,'indicators',paste(lfa,'NEFSC.spring.restratified.recruits.csv',sep="")))
rm(aout)

     

#Fall 
      p$season =c('fall')# p$series =c('spring');p$series =c('fall')
      
   aout= nefsc.analysis(DS='stratified.estimates.redo',p=p)

            p$file.name =  file.path('LFA3438Framework2019',paste(lfa,'NEFSCFallrestratifiednumbersrecruits.png',sep=""))

                          p$y.maximum = NULL # NULL # if ymax is too high for one year
                        p$show.truncated.numbers = F #if using ymax and want to show the numbers that are cut off as values on figure

                                p$legend = FALSE
                                p$running.median = T
                                p$running.length = 3
                                p$running.mean = F #can only have rmedian or rmean
                               p$error.polygon=F
                              p$error.bars=T

                     p$ylim2 = c(0,500)
                        xx = aggregate(ObsLobs~yr,data=aout,FUN=sum)
                              names(xx) =c('x','y')
                       
                           ref.out=   figure.stratified.analysis(x=aout,out.dir = 'bio.lobster', p=p, x2 = xx, sampleSizes=T)
                    p$ylim=NULL
                    p$file.name =  file.path('LFA3438Framework2019',paste(lfa,'NOYNEFSCFallrestratifiednumbersrecruits.png',sep=""))
                   ref.out=   figure.stratified.analysis(x=aout,out.dir = 'bio.lobster', p=p, x2 = xx, sampleSizes=T)
                   p$ylim=c(0,4)
                aout$subset = 'NEFSCFallrecruits'
        write.csv(aout,file=file.path(fp,'indicators',paste(LFA,'NEFSC.fall.restratified.recruits.csv',sep="")))
    rm(aout)
}
if(survey=='DFO'){
      p$series =c('summer')# p$series =c('georges');p$series =c('fall')
      p$area = lfa
      p$years.to.estimate = c(1970:2018)
      p$length.based = T
      p$by.sex = T
      p$size.class = c(70,82)
      p$sex = c(1,2)
      p$bootstrapped.ci=T
      p$strata.files.return=F
      p$vessel.correction.fixed=1.2
      p$strat = NULL
      p$clusters = c( rep( "localhost", 7) )
      p$strata.efficiencies = F
      p = make.list(list(yrs=p$years.to.estimate),Y=p)
      p$define.by.polygons = T
      p$lobster.subunits=F
      p$reweight.strata = T #this subsets 
  
    aout= dfo.rv.analysis(DS='stratified.estimates.redo',p=p)
      

         #Figure
                              p$add.reference.lines = F
                              p$time.series.start.year = p$years.to.estimate[1]
                              p$time.series.end.year = p$years.to.estimate[length(p$years.to.estimate)]
                              p$metric = 'numbers' #numbers
                              p$measure = 'stratified.mean' #'stratified.total'
                              p$figure.title = ""
                              p$reference.measure = 'median' # mean, geomean
                              p$file.name =  file.path('LFA3438Framework2019',paste(lfa,'DFOrestratifiednumbersrecruits.png',sep=""))
                          p$y.maximum = NULL # NULL # if ymax is too high for one year
                        p$show.truncated.numbers = F #if using ymax and want to show the numbers that are cut off as values on figure
                                p$legend = FALSE
                                p$running.median = T
                                p$running.length = 3
                                p$running.mean = F #can only have rmedian or rmean
                               p$error.polygon=F
                              p$error.bars=T


                     p$ylim2 = c(0,500)
                        xx = aggregate(ObsLobs~yr,data=aout,FUN=sum)
                              names(xx) =c('x','y')
                       
                       ref.out=   figure.stratified.analysis(x=aout,out.dir = 'bio.lobster', p=p, x2 = xx, sampleSizes=T)
                      p$ylim=NULL
                      p$file.name =  file.path('LFA3438Framework2019',paste(lfa,'NOYDFOrestratifiednumbersrecruits.png',sep=""))

                      ref.out=   figure.stratified.analysis(x=aout,out.dir = 'bio.lobster', p=p, x2 = xx, sampleSizes=T)
     aout$subset = 'DFOrecruits'
      write.csv(aout,file=file.path(fp,'indicators','DFO.restratified.recruits.csv'))
 rm(aout)
   p$ylim=c(0,5)

  }
}

stratifiedAnalysesRecruits(survey='NEFSC',lfa='LFA34')
stratifiedAnalysesRecruits(survey='DFO',lfa='LFA34')
stratifiedAnalysesRecruits(survey='DFO',lfa='LFA35')
stratifiedAnalysesRecruits(survey='DFO',lfa='LFA36')
stratifiedAnalysesRecruits(survey='NEFSC',lfa='LFA38')
stratifiedAnalysesRecruits(survey='DFO',lfa='LFA38')
stratifiedAnalysesRecruits(survey='DFO',lfa='LFA35-38')
