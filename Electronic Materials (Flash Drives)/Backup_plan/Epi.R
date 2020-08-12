rm(list = ls()) #clear your workspace

setwd("C:/Users/kamarske/Dropbox/Comp Sci Workshop/data/NZclimate/current")
files <- list.files(pattern='asc', full.names=TRUE )
files

predictors<- stack(files)
predictors
names(predictors)


#Visualizing the predictors is the easiest way to make sure we've done everything correctly up to this point
plot(predictors[[1]]) # Bio01: mean annual temp  
plot(predictors[[2]]) # Bio05: max temp of warmest month
plot(predictors[[3]]) # Bio06: mean temp of coldest month
plot(predictors[[4]]) # Bio12: annual precipitation
plot(predictors[[5]]) # Bio13: precip of wettest month
plot(predictors[[6]]) # Bio14: precip of dryest month


#importing and mapping localities
#show how to save excel file in csv format
#dismo and ENMeval expect your locality data to be in the order of longitude, latitude


setwd("C:/Users/kamarske/Dropbox/Comp Sci Workshop/data") #Navigate to where our species data are
locs<-read.csv('Epistranus_lawsoni.csv')
View(locs)

#need to get rid of that first column so all we've got are the coordinates

locs$Species<-NULL
View(locs)


###### Running Maxent


#let's just run a super quick and dirty maxent model to make sure everything is working

setwd("C:/Users/kamarske/Dropbox/Comp Sci Workshop")
dir.create('~/MaxEnt_Epi') #maxent writes a lot of output files so you will want a new directory for each run
xm <- maxent(predictors, locs, removeDuplicates=TRUE, nbg=1000, path='MaxEnt_Epi') # Builds a Maxent model
#If you forgot to download maxent, or you put the .jar file in the wrong place, you will get a warning below.

#Let's take a quick look in that folder we just made....

#We can also see all of these results right here in R:
xm@results
write.csv (xm@results, 'MaxEnt_Epi/Rmaxent_Epi.csv')

result <- predict(xm, predictors, progress='text') # Makes a RasterLayer with a prediction based on the Maxent model
#(this is how we get the map!)
plot(result)
points(locs) #If you don't want the localities, just run plot(result) again
writeRaster(result, "MaxEnt_Epi/Rmaxent_Epi_current", format="ascii", overwrite=TRUE) #Saving your result as an ascii file
#this just saved the raster layer, not that figure that has the localities or legend.
dev.print(pdf, 'MaxEnt_Epi/Rmaxent_Epi_current.pdf') #This file will not over-write, must delete if rerunning the command

####
#Sweet! We're done, right?
#We've just built a super complex model, but Maxent made it look really simple!
#What did we learn about our species?
#Did our six climatic variables do a good job of predicting the distribution of our species?

#####
#Let's look at which of our environmental predictors made the strongest contributions to the model
#Remember:
# Bio01: mean annual temp
# Bio05: max temp of warmest month
# Bio06: mean temp of coldest month
# Bio12: annual precipitation
# Bio13: precip of wettest month
# Bio14: precip of dryest month


plot(xm) #plots variable importance

#######################

#Let's see how well our model worked
#We will use a k-folds cross-validation to generate a test-AUC

bg <- randomPoints(predictors, 1000) #randomly selects background points

plot(result)
points(bg)
points(locs)


fold <- kfold(locs, k=5)

occtest <- locs[fold == 1, ]
occtrain <- locs[fold != 1, ]

e1 <- evaluate(xm, p=occtest, a=bg, x=predictors)
plot(e1, 'ROC')
dev.print(pdf, 'MaxEnt_Epi/Rmaxent_Epi_AUC1.pdf')

occtest <- locs[fold == 2, ]
occtrain <- locs[fold != 2, ]

e2 <- evaluate(xm, p=occtest, a=bg, x=predictors)
plot(e2, 'ROC')
dev.print(pdf, 'MaxEnt_Epi/Rmaxent_Epi_AUC2.pdf')

occtest <- locs[fold == 3, ]
occtrain <- locs[fold != 3, ]

e3 <- evaluate(xm, p=occtest, a=bg, x=predictors)
plot(e3, 'ROC')
dev.print(pdf, 'MaxEnt_Epi/Rmaxent_Epi_AUC3.pdf')

occtest <- locs[fold == 4, ]
occtrain <- locs[fold != 4, ]

e4 <- evaluate(xm, p=occtest, a=bg, x=predictors)
plot(e4, 'ROC')
dev.print(pdf, 'MaxEnt_Epi/Rmaxent_Epi_AUC4.pdf')

occtest <- locs[fold == 5, ]
occtrain <- locs[fold != 5, ]

e5 <- evaluate(xm, p=occtest, a=bg, x=predictors)
plot(e5, 'ROC')
dev.print(pdf, 'MaxEnt_Epi/Rmaxent_Epi_AUC5.pdf')

AUC_list <-c(e1@auc, e2@auc, e3@auc, e4@auc, e5@auc)
AUC_list
avg_AUC <-mean(AUC_list)
avg_AUC
var_AUC <-var(AUC_list)
var_AUC


###### Predicting to the past or future


#Here's our result again:
plot(result)


#To project this model (the statistical relationship between climate and specie occurrence) into the past or future,
#we need to prepare and load those climate layers.

#Let's start with the Last Glacial Maximum (21,000 years ago). Where were the climate refugia?

#Navigate to the LGM climate data
setwd("C:/Users/kamarske/Dropbox/Comp Sci Workshop/data/NZclimate/LGM/Miroc_LGM")
files <- list.files(pattern='asc', full.names=TRUE )
files

LGMpredictors<- stack(files)
LGMpredictors
names(LGMpredictors) #note that the predictor names are exactly the same as you used previously!


#Visualizing the predictors is the easiest way to make sure we've done everything correctly up to this point
plot(LGMpredictors[[1]]) # Bio01: mean annual temp  
plot(LGMpredictors[[2]]) # Bio05: max temp of warmest month
plot(LGMpredictors[[3]]) # Bio06: mean temp of coldest month
plot(LGMpredictors[[4]]) # Bio12: annual precipitation
plot(LGMpredictors[[5]]) # Bio13: precip of wettest month
plot(LGMpredictors[[6]]) # Bio14: precip of dryest month

LGMresult <- predict(xm, LGMpredictors, progress='text') # Makes a RasterLayer with a prediction based on the Maxent model
#(this is how we get the map!)
plot(LGMresult)
setwd("C:/Users/kamarske/Dropbox/Comp Sci Workshop")#we don't want to leave our result in the climate data folder!
writeRaster(result, "MaxEnt_Epi/Rmaxent_Epi_LGMresult", format="ascii", overwrite=TRUE) #Saving your result as an ascii file
dev.print(pdf, 'MaxEnt_Epi/Rmaxent_Epi_LGM.pdf') #Saving the figure

#Interpreting the model (this is the exciting part): where were the most likely climatic refugia?
#Will these climatic refugia be within the species' future distribution?

#Navigate to the near-future climate data: let's look at projections for 2050, under a 'business as usual' carbon scenario
setwd("C:/Users/kamarske/Dropbox/Comp Sci Workshop/data/NZclimate/2050/miroc_8_2050")
files <- list.files(pattern='asc', full.names=TRUE )
files


Futpredictors<- stack(files) #Note that I am not allowed to call these 2050predictors!
Futpredictors
names(Futpredictors) #note that the predictor names are exactly the same as you used previously!

plot(Futpredictors[[1]]) # Bio01: mean annual temp  
plot(Futpredictors[[2]]) # Bio05: max temp of warmest month
plot(Futpredictors[[3]]) # Bio06: mean temp of coldest month
plot(Futpredictors[[4]]) # Bio12: annual precipitation
plot(Futpredictors[[5]]) # Bio13: precip of wettest month
plot(Futpredictors[[6]]) # Bio14: precip of dryest month


Futresult <- predict(xm, Futpredictors, progress='text') # Makes a RasterLayer with a prediction based on the Maxent model
#(this is how we get the map!)
plot(Futresult)
setwd("C:/Users/kamarske/Dropbox/Comp Sci Workshop")
writeRaster(Futresult, "MaxEnt_Epi/Rmaxent_Epi_2050result", format="ascii", overwrite=TRUE) #Saving your result as an ascii file
dev.print(pdf, 'MaxEnt_Epi/Rmaxent_Epi_2050.pdf') #Saving the figure

#MORE model interpretation! Just for convenience, let's put all three sets of results (past,present, future)
#as the most recent plots in the plot window.


plot(LGMresult, main="LGM")
plot(result, main="current")
plot(Futresult, main="2050")

#Now we can use the arrow in the upper left corner of the plot window to move between time periods.

#How is the distribution of Agyrtodes labralis changing over time?
#Will A. labralis gain or loose climatically suitable area in the future?
#Are there any areas which remain highly suitable for all three time periods?




####### Optional Extra: Improving your maps!

#R's built-in color palletes are not super attractive. I usually export my rasters and make my maps in ArcGIS.
#However, there are several R packages which give you more control of your color scheme.
#One of these is RColorBrewer, which has a nice website with suggestions especially for map-making: https://colorbrewer2.org/

#At the website, in the upper left corner, set the number of data classes to 9 and the data type to sequential.
#Take a look at the different spectra and pick one you like, and click on it. 
#In the center-left of your screen, you should see a number with a # appear next to each color (be sure the box is set to HEX).
#You will use these HEX numbers to make your palette.

#For example:


#This palette uses nine colors, each indicated by its own HEX code, and makes a spectrum with 50 different gradations of those colors.
#The c() which encloses the HEX numbers basically stands for concatinate, and is how you feed R a list.
#I have chosen for the pale yellow to represent high suitability and dark blue to represent low suitability, but you could do the opposite
#by entering the numbers in the reverse order. Each HEX number needs to be enclosed in "".


cols <-colorRampPalette(c("#081d58", "#253494", "#225ea8", "#1d91c0", "#41b6c4", "#7fcdbb", "#c7e9b4", "#edf8b1", "#ffffd9"))(50)

plot(LGMresult, col=cols, main="LGM")
plot(result, col=cols, main="current")
plot(Futresult, col=cols, main="2050")

