### Update!!! ####
 
#static tables need to be updated by CDenton
# logs41, annual.landings, seasonal.landings


p = bio.lobster::load.environment()

# run these to get and update data objects 
source( file.path(project.codedirectory('bio.lobster'),'inst','LFA41FrameworkandAssessment','Assessment','1.DataImport.r')) # on windows with connection
source( file.path(project.codedirectory('bio.lobster'),'inst','LFA41FrameworkandAssessment','Assessment','2.stratifiedAnalysis.r'))
source( file.path(project.codedirectory('bio.lobster'),'inst','LFA41FrameworkandAssessment','Assessment','2a.stratifiedLargeFemales.r'))
source( file.path(project.codedirectory('bio.lobster'),'inst','LFA41FrameworkandAssessment','Assessment','2b.stratifiedSexRatios.r'))
source( file.path(project.codedirectory('bio.lobster'),'inst','LFA41FrameworkandAssessment','Assessment','2c.stratifiedSizeFrequencies.r'))  ## this one takes a while
source( file.path(project.codedirectory('bio.lobster'),'inst','LFA41FrameworkandAssessment','Assessment','2d.stratifiedAnalysisCommercial.r'))
source( file.path(project.codedirectory('bio.lobster'),'inst','LFA41FrameworkandAssessment','Assessment','2e.femalestratifiedSizeFrequencies.r'))  ## this one takes a while
source( file.path(project.codedirectory('bio.lobster'),'inst','LFA41FrameworkandAssessment','Assessment','2g.stratifiedAnalysisRecruits.r'))
source( file.path(project.codedirectory('bio.lobster'),'inst','LFA41FrameworkandAssessment','Assessment','3.reproductivePotential.r'))
source( file.path(project.codedirectory('bio.lobster'),'inst','LFA41FrameworkandAssessment','Assessment','5a.figureLengthFreqs.r'))

# run this for update plots:
Update.plots=T

source( file.path(project.codedirectory('bio.lobster'),'inst','LFA41FrameworkandAssessment','Assessment','15.indicators.r'))
source( file.path(project.codedirectory('bio.lobster'),'inst','LFA41FrameworkandAssessment','Assessment','3a.reproductivePotentialRefPoints.r'))
source( file.path(project.codedirectory('bio.lobster'),'inst','LFA41FrameworkandAssessment','Assessment','16.refpoints.r'))

