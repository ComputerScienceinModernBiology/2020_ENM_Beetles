
#Before we start:
### (1) Download maxent and place maxent.jar into your R-dismo-java directory.  https://biodiversityinformatics.amnh.org/open_source/maxent/
### (2) Install Java and rJava and make sure the rJava libary loads properly.

########################################################################################################################

#################  Day 1: Intro to species distribution modelling in R  ################################################

########################################################################################################################


#Maxent is a stand-alone program with a decent user interface. Why do this in R?
### Control
### Repeatability
### Transparency
### Reusability (i.e. easier in the long run)

#How to get started in R: copy and paste!

#before starting a new project or work session in R, it is always a good idea to clear out your workspace.
rm(list = ls())
#As we go: save your code! (Up at the top)
#When you close, do not save the workspace unless you plan to use it again


#loading libraries (what's a library?)
#if these are not already installed on your computer, you can get them using the command install.packages("raster")
#then run the library command

library("raster")
library("maptools")
library("dismo")
library("rJava")
#library("ENMeval")
#library("RColorbrewer")


#explore the directory structure for this project (where are your files located?)
###show how to copy/paste directory info


getwd() #tells me where I am. Unless I change it, this is where R will look for or save files.
setwd("C:/Users/kamarske/Dropbox/Comp Sci Workshop/data")

#Above, session ->set working directory -> choose directory lets you navigate to where you want to go.
#Notice that the setwd() command appears below-paste it here so you have it!


###### Exploring climate data

#First, let's look at one of the data types we'll be using:
#importing and preparing climate layers
#these were downloaded from Worldclim.org at a 2.5 minute spatial resolution
#At the equator, each grid cell is approximately 5km on a side

#first let's look at some place familiar
setwd("C:/Users/kamarske/Dropbox/Comp Sci Workshop/data/globalclimate/current")
files <- list.files(pattern='asc', full.names=TRUE )
files #make sure you see the 19 ascii files and nothing else!


#Let's look at a couple of these individual files:

bio1 <- raster(x='bio01.asc') #mean annual temperature
plot(bio1)

#Zooming in on home territory
NorthAm <- extent(-170, -52, 10, 75) # define our area using longitude and latitude (left, right, bottom, top) 
#Note that I cannot abbreviate as NA because that means Not Applicable, or no data
NAbio1 <- crop(bio1, NorthAm)
plot(NAbio1) # make sure it worked


bio12 <- raster(x='bio12.asc') #annual precipitation
plot(bio12)
NAbio12 <- crop(bio12, NorthAm)
plot(NAbio12) # make sure it worked


#I will know show you how to upload all of the files and prepare your climate data
#These next few steps are memory intensive and will take a few minutes to run.
#It is OK TO WATCH THIS STEP--I have some already-prepared data we will use to generate our SDMs.

setwd("C:/Users/kamarske/Dropbox/Comp Sci Workshop/data/globalclimate/current")

files <- list.files(pattern='asc', full.names=TRUE )
files #make sure you see the 19 ascii files and nothing else!

#Let's import the files into a raster stack:
predictors<- stack(files)
predictors
names(predictors)

#And make sure it worked:
plot(predictors[[1]]) # Plotting the first raster in the stack: Bio01, mean annual temp

#alternatively, if you have a good internet connection, R can interface directly with Worldclim to grab the data for you
#bio <- raster::getData("worldclim", var = "bio", res = 2.5)
#predictors <- stack(bio)

#We are going to build a Species Distribution Model for a beetle that occurs only in New Zealand.
#Are we ready to start modelling, or do we have another data preparation step?

NZ <- extent(164, 180, -49, -33) # defines the space using longitude and latitude (left, right, bottom, top) 
NZpredictors <- crop(predictors, NZ) #THIS TAKES SEVERAL MINUTES TO RUN
plot(NZpredictors[[1]]) # make sure it worked


###### Importing New Zealand climate data and species occurrences

#In the interest of saving time and taking it easy on your computers, I have
#prepared a set of six climate variables which are already cropped to fit New Zealand.
#Everyone PLEASE JOIN IN HERE.

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
locs<-read.csv('Agyrtodes_labralis.csv')
View(locs) #Notice this is one of very FEW functions to begin with an upper case letter!

#need to get rid of that first column so all we've got are the coordinates

locs$species<-NULL
View(locs)


###### Running Maxent


#We're ready!

setwd("C:/Users/kamarske/Dropbox/Comp Sci Workshop")
dir.create('~/MaxEnt_Agyrt') #maxent writes a lot of output files so you will want a new directory for each run
xm <- maxent(predictors, locs, removeDuplicates=TRUE, nbg=1000, path='MaxEnt_Agyrt') # Builds a Maxent model
#If you forgot to download maxent, or you put the .jar file in the wrong place, you will get a warning below.

#Let's take a quick look in that folder we just made....

#We can also see all of these results right here in R:
xm@results

result <- predict(xm, predictors, progress='text') # Makes a RasterLayer with a prediction based on the Maxent model
#(this is how we get the map!)
plot(result)
points(locs) #If you don't want the localities, just run plot(result) again
writeRaster(result, "MaxEnt_Agyrt/Agyrt_current", format="ascii", overwrite=TRUE) #Saving your result as an ascii file
#this just saved the raster layer, not that figure that has the localities or legend.
dev.print(pdf, 'Agyrt_current.pdf') #This file will not over-write, must delete if rerunning the command

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

occtest <- locs[fold == 2, ]
occtrain <- locs[fold != 2, ]

e2 <- evaluate(xm, p=occtest, a=bg, x=predictors)
plot(e2, 'ROC')

occtest <- locs[fold == 3, ]
occtrain <- locs[fold != 3, ]

e3 <- evaluate(xm, p=occtest, a=bg, x=predictors)
plot(e3, 'ROC')

occtest <- locs[fold == 4, ]
occtrain <- locs[fold != 4, ]

e4 <- evaluate(xm, p=occtest, a=bg, x=predictors)
plot(e4, 'ROC')

occtest <- locs[fold == 5, ]
occtrain <- locs[fold != 5, ]

e5 <- evaluate(xm, p=occtest, a=bg, x=predictors)
plot(e5, 'ROC')

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
writeRaster(result, "MaxEnt_Agyrt/Agyrt_LGMresult", format="ascii", overwrite=TRUE) #Saving your result as an ascii file
dev.print(pdf, 'Agyrt_LGM.pdf') #Saving the figure

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
writeRaster(Futresult, "MaxEnt_Agyrt/Agyrt_2050result", format="ascii", overwrite=TRUE) #Saving your result as an ascii file
dev.print(pdf, 'Agyrt_2050.pdf') #Saving the figure

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






########################################################################################################################

#################  Day 2: Climatic refugia and genetic diversity  ######################################################

########################################################################################################################




#Select a beetle species other than Agyrtodes labralis, which we worked with yesterday.
#For your species, either Brachynopus scutellaris, Epistranus lawsoni, or Geochus tibialis, 
#build an SDM, determine which climatic variables are the most important to the model,  and evaluate your model using the K-folds cross-validation method.


#Then project your SDMs to the LGM and 2050 to answer the following questions:


# 1) Based on the location(s) of glacial refugia for your species, where within its current range do you expect to find the highest genetic diversity?
# 2) Will these high-diversity areas continue to be within the species' range in 2050?
# 3) Will any of the species current range remain suitable in 2050, or will the species have to move to reach suitable habitat?


#You should be able to generate the code for this experiment by copying and pasting the code from above.
#But, you will need to make a few changes. What are they?


#########
# Steps: (you can copy and paste the code below--that way you can save the above as a 'clean' copy)


# Load your climate data and the occurrence data for your chosen species and map to make sure they loaded correctly.

# Create a directory for your maxent results.

# Run maxent and save your results (raster layer AND PDF)

# Assess the contributions of the different climate variables

# Evaluate your SDM using k-folds cross-validation to obtain the testing AUC

# Project your model to the Last Glacial Maximum and save the results (raster and PDF)

# Project your model to the future and save the results (raster and PDF)

# If you want, spend a few minutes to improve the color scheme for your maps, saving the PDFs

# Interpret your results!! You ran these models to answer specific questions about your species biology.
# You are now finished with the statistical analysis, so use the results you generated to answer the questions above!


#If you have extra time, build an SDM for one or two more species. How much do their ranges overlap?
#Did they share the same glacial refugia? Will they experience similar responses to climate change (range loss/gain?)
#Are the same climatic variables important in predicting each species' range?


#If you have LOTS of extra time, use the commands below (under Backup Plan) to build an additional series of SDMs for your species.
#Each SDM algorithm treats the data in a different way, resulting in a slightly different geographical projection.
#Compare the past, current and future maps for your species for Maxent and GLM. How are they different?


#############################################################################################################

###### Additional Resorces ##################################################################################

#############################################################################################################

#Maxent and R have a huge range of functionality, and we have only skimmed the surface. 
#To get further into Maxent and explore how different parameter settings can impact your model, 
#the ENMeval allows further exploration and model testing based on your maxent results.
#A helpful starter guide can be found here: https://oliveirabrunno.wordpress.com/2016/12/04/compare-the-performance-of-ecological-niche-models-enms/
#or here: https://cran.r-project.org/web/packages/ENMeval/vignettes/ENMeval-vignette.html

#A huge thanks to Brunno Oliveira, whose code was extremely helpful in preparing this lesson!


##############################################################################################################

############ Backup plan #####################################################################################

##############################################################################################################

# If for some reason you are absolutely unable to get Maxent running, ie because of problems with Rjava, 

# 1) I have generated outputs for each species in the directory called Backup_Plan so that you can see the results and 
#    answer the questions. All files generated with the R commands above begin with the phrase "Rmaxent_ ".
#    To load the rasters into R, use the line importedraster <- raster(x='filename.asc')
#    Change filename to the name of the raster you are trying to import, and importedraster to something informative, eg brachy_LGM


# 2) Below I have prepared the code to generate an SDM using a General Linear Model (glm). This is basically a linear regression, which 
#    many of you are familiar with, conducted on spatial data rather than individual measurements. You will not be able to 
#    run the cross-validation or look at variable importance, but at least you can define the elements of the model and
#    generate your own spatial projections (rasters). You can then use the code above to make nice images and answer the biological questions.



#### Preparing the occurrence and background localities
locs<-read.csv('Agyrtodes_labralis.csv')
locs$species<-NULL #getting rid of the extra column so we just have long and lat
View(locs)
colnames(locs) <-c("x","y") #to combine this with the background data, the names of the columns should be the same
View(locs)

bg <- as.data.frame(randomPoints(predictors, 1000)) #randomly selects background points
View(bg)
colnames(bg) <-c("x","y") #same column names
View(bg)


#we will now combine the localities and background points into a single data matrix
#We are adding an extra column to say whether our long-lats are species occurrance data (1) or background points (0)

locsnew <- cbind(1, locs) #adds a column of 1 to the locality data
bgnew <- cbind(0, bg) #adds a column of 0 to the background data
View(locsnew)
colnames(bgnew) <-c("1", "x", "y") #same column names as locality data
View(bgnew)

xy <- rbind(locsnew, bgnew) #combine the two datasets into one data frame by pasting the background data below the locality data
View(xy)

clim <- as.data.frame(cbind(pa=xy[,1], extract(predictors, xy[,2:3]))) #associate climate data in the rastor stack (predictors) with the presence and background points


####Build the GLM model            
               
model <- glm(formula=pa~., data=clim) #define the model

glmresult <- predict(predictors, model, progress='text') #build the spatial projection


plot(glmresult) #plot that projection!



#To project the GLM result into the past and future, use the instructions above to make your LGM and 2050 raster stacks
#Then use these commends to build the projection

glm_LGM <- predict(LGMpredictors, model, progress='text')
plot(glm_LGM)


glm_2050 <- predict(Futpredictors, model, progress='text')
plot(glm_2050)
