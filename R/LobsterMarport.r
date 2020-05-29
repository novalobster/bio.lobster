#' LobsterMarport
#' @param file is the marport file obtained during the 2015 ILTS survey which contains the net sensor information as well as the gps data feeds
#' @author Adam Cook
#' @return returns a list containing two elements: 1) the trawl sensor information 2) the gps track of the file
#' @export
LobsterMarport <- function(file,station=NULL) {
	#reading in and manipulating the marport data from lobster survey
	con = file(description=file, open="r")
	options(stringsAsFactors=F)	
	OSinfo = Sys.info()
	OS = OSinfo["sysname"]


if(OS=='Linux')	{com = paste("wc -l ", file, " | awk '{ print $1 }'", sep=""); n = system(command=com, intern=TRUE)}
if(OS=='Windows') {n =  length(readLines(file))}
	  

		jj=0
		out.sensors = NULL
		out.gps = NULL
		Collector = NULL


for(j in 1:n) {
		  tmp <- scan(file=file, skip=jj, nlines=1, quiet=TRUE,what='complex')
  		if(!is.na(tmp[4]) & length(tmp)>0) {
  				if(tmp[4]=='INFO') {
  					if(tmp[10] %in% c('CAPACITY_VOLTA','PITCH','BEAM','TEMPERATURE','DEPTH','DISTANCE',"ROLL")) {
  						out.sensors = rbind(out.sensors,tmp)
  					}		
  					if(!tmp[10] %in% c('CAPACITY_VOLTA','PITCH','BEAM','TEMPERATURE','DEPTH','DISTANCE',"ROLL")) {
  						Collector = c(Collector,tmp[10])
  						}
	  				
			  	}
			  if(any(strsplit(tmp[4],",")[[1]] %in% c('$GPGGA','$GPRMC'))) {
	  					out.gps = rbind(out.gps,c(tmp[1:3],strsplit(tmp[4],",")[[1]]))
	  				}	
  				}				
  				jj=jj+1  
				
			}	
		ose = NULL
		ogp = NULL
		if(!is.null(out.sensors)) {
		ose = data.frame(out.sensors)
		ose$X1 = do.call(rbind,strsplit(ose$X1,"\\."))[,1]
		ose$X1 = strptime(ose$X1,"%H:%M:%S")
		
		ose = ose[,c(1,10,15,16)]
		names(ose) = c('Time','Measure','X1','X2')
		ose$X1 = as.numeric(ose$X1)
		ose$X2 = as.numeric(ose$X2)
		if(is.null(station)) ose$Station = strsplit(strsplit(file,"/")[[1]],"\\.")[[9]][1]
		if(!is.null(station)) ose$Station = station
		}

		if(!is.null(out.gps)) {
		ogp = data.frame(out.gps)
		ogp$X1 = do.call(rbind,strsplit(ogp$X1,"\\."))[,1]
		ogp$X1 = strptime(ogp$X1,"%H:%M:%S")

		ogp = ogp[,c(1,7,9)]
		names(ogp) = c('Time','Y','X')
		ogp$X = convert.dd.dddd(as.numeric(ogp$X))*-1
		ogp$Y = convert.dd.dddd(as.numeric(ogp$Y))
		if(is.null(station)) ogp$Station = strsplit(strsplit(file,"/")[[1]],"\\.")[[10]][1]		
		if(!is.null(station)) ogp$Station = station
		
		}
		return(list(ose,ogp))
		}