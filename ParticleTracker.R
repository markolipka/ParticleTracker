library(raster)
library(exif)

timestamp.from.images <- function(path = "test/FakeParticles/",
                                  format = "jpg",
                                  exif.attribute = "origin_timestamp"){
    images <- list.files(path, full.names = T,
                         include.dirs = F, all.files = F,
                         pattern = format)
    num.images = length(images)
    if (num.images < 2) stop("Number of images must be at least 2")
    
    df <- do.call(rbind,
                  lapply(images,  FUN = function(file){
                      data.frame("filename" = file, 
                                 "timestamp" = strptime(read_exif(file)[, exif.attribute],
                                                        format = "%Y:%m:%d %H:%M:%S", tz = "UTC"))
                  }))
    min <- min(df$timestamp)
    max <- max(df$timestamp)
    diff.s <- difftime(max, min, units = "sec")
    return(list(data = df, min = min, max = max, diff.s = diff.s))
}

particle.positions.from.images <- function(path = "test/FakeParticles/",
                                           format = "jpg",
                                           output.fig = TRUE){
    images <- list.files(path, full.names = T,
                         include.dirs = F, all.files = F,
                         pattern = format)
    num.images = length(images)
    if (num.images < 2) stop("Number of images must be at least 2")
    
    mats <- lapply(images, function(img) as.matrix(raster(img)))
    dimensions <- mapply(dim, mats)
    df <- data.frame("filename" = images,
                     "width" = dimensions[2,],
                     "height" = dimensions[1,])
    
    if (nrow(unique(df[, c("width", "height")])) > 1) {
        print(df)
        warning("Dimensions of images are not uniform")
    }
    
    composed <- Reduce('+', mats) # sum of all matrices
    
    #if (output.fig) png(filename = "ParticleTrack.png")
    
    plot(raster(composed),
         main = paste(num.images, "images loaded and compiled.\n Please klick at\n",
                      num.images, "particles (top to bottom)"),
         legend = FALSE,
         #axes = FALSE,
         col = grey(seq(0, 1, length = 8)))
    
    locs <- as.data.frame(locator(n = num.images, type = "o"))
    
    text(x = mean(locs$x) + 0.1,
         y = locs$y,
         labels = round(locs, digits = 2)[, 2])
    
    #dev.off()
    return(df = cbind(df, locs))
}

start.the.shit <- function(path = "~/Dropbox/IOW/R-functions/Particle_locator/test/"){
    setwd(path)
    dirs <- list.dirs(path = path, full.names = TRUE)
    for (dir in dirs[-1]) { # to exclude the first directory which might always be 'path' itself ??
        message(dir)
        #readline(prompt = "continue [Enter] or skip [Esc]")
    times     <- timestamp.from.images(path = dir)$data
    locations <- particle.positions.from.images(path = dir)
    
    df <- merge(times, locations, by = "filename")
    write.csv(x = df, file = paste(dir, "ParticleTrack.csv", sep = "/"))
    }
    
}