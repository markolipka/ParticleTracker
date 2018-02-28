## Helper functions for particle tracking
## - extract EXIF data from raster images of sinking particles
## - easily measure particle positions in image stacks

#FIXME: resizing of the plot window before locate()ing points leads to wrong results!

library(exif) # for extraction of EXIF data from image files
library(raster) # for import and processing of raster images

# Extracting timestamps from a set of image files of given file extension in a given directory
timestamp.from.images <- function(path = "test/FakeParticles/",
                                  format = "jpg", # pattern for file matching
                                  exif.attribute = "origin_timestamp"){ # name of exif attribute to extract
    images <- list.files(path, full.names = T, # get a list of images with their full path in the path ...
                         include.dirs = F, all.files = F, # ... without hidden files and directories ...
                         pattern = format) # ... matching a given pattern
    num.images = length(images) # number of files
    if (num.images < 2) stop("Number of images must be at least 2")
    
    # TODO: if is.na(exif.attribute) PRINT LIST OF ATTRIBUTES IN THE FILES
    df <- do.call(rbind, # combine into a data.frame the output of the loop:
                  # get EXIF data from every file
                  lapply(images,  FUN = function(file){ 
                      data.frame("filename" = file,  # filename in df for later merging!
                                 "timestamp" = strptime(read_exif(file)[, exif.attribute], 
                                                        format = "%Y:%m:%d %H:%M:%S", tz = "UTC"))
                  }))
    
    # Extract min and max time and their diff
    min <- min(df$timestamp)
    max <- max(df$timestamp)
    diff.s <- difftime(max, min, units = "sec")
    
    return(list(data = df, min = min, max = max, diff.s = diff.s))
}

# Track particle positions in composite image from stack of input files
particle.positions.from.images <- function(path = "test/FakeParticles/",
                                           format = "jpg",
                                           firstlast = TRUE, # process only first and last image
                                           sep.window = TRUE, # open separate window for particle localization
                                           output.fig = TRUE){ # TODO: implement output of the resulting figure
    message(paste("Reading path ", path, " ..."))
    if (!file.exists(path)) stop("Path does not exist...")
    images <- list.files(path, full.names = T,
                         include.dirs = F, all.files = F,
                         pattern = format)
    print(images)
    num.images = length(images)
    if (num.images < 2) stop("Number of images must be at least 2")
    
    if (firstlast) {
        images <- images[c(1, num.images)]
        num.images <- 2
    }
    
    
    rasters <- lapply(images, function(img) raster(img)) # Read image files and store as list of raster objects
    dimensions <- mapply(dim, rasters) # dimensions of all raster objects for comparison
    
    # store information of raster objects in data frame
    df <- data.frame("filename" = images,
                     "width" = dimensions[2,],
                     "height" = dimensions[1,])
    
    # Warn, if dimensions of the images are not uniform
    if (nrow(unique(df[, c("width", "height")])) > 1) {
        print(df)
        warning("Dimensions of images are not uniform")
    }
    
    # compose raster objects
    composed <- min(stack(rasters)) # darker colours have lower values, hence, the darkest pixels of al raster layers are kept in the composite layer
    
    # Particle Tracking:
    message(paste(num.images, "images loaded and compiled.\n Please klick at\n",
                  num.images, "particles (top to bottom)"))
    
    if (sep.window) x11(bg = "pink", height = 10, width = 10) # Option: separate window
    par(mar = c(0,2.5,0,0)) # get rid of useless margins
    plot(composed,
         legend = TRUE,
         #axes = FALSE,
         col = grey(seq(0, 1, length = 256))
    )
    
    locs <- as.data.frame(locator(n = num.images, # store coordinates of particles (one per image) in data.frame
                                  type = "o")) # and highlight marked coordinates
    
    # label marked points with y-coordinates
    text(x = mean(locs$x) * 1.25, 
         y = locs$y, # 
         labels = round(locs, digits = 2)[, 2])
    
    #dev.off()
    return(df = cbind(df, locs))
}

# combine both functions to return data frame (and later plot ??) for each directory in a given path
start.the.shit <- function(path = "~/Dropbox/IOW/R-functions/Particle_locator/test", ...){
    dirs <- list.dirs(path = path, full.names = TRUE)
    for (dir in dirs[-1]) { # to exclude the first directory which might always be 'path' itself ??
        message(dir)
        #readline(prompt = "continue [Enter] or skip [Esc]")
        times     <- timestamp.from.images(path = dir)$data
        locations <- particle.positions.from.images(path = dir, ...)
        
        df <- merge(times, locations, by = "filename", all.x = TRUE)
        write.csv(x = df, file = paste(dir, "ParticleTrack.csv", sep = "/"))
    }
    
}


start.the.shit(sep.window = F, firstlast = F)
