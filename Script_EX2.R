###################
### FIELDimageR ###
###################

library(FIELDimageR)
library(raster)
library(agricolae)
library(reshape2)
library(ggplot2)
library(lme4)
library(plyr)
library(DescTools)

## Images names (folder directory: "./images/"):
pics<- list.files("./EX2/")
pics

## Vegetation indices:
index<- c("BI", "GLI", "NGRDI")

## Choose one image to prepare the pipeline:
EX.L1<- stack(paste("./EX2/", pics[1], sep = ""))
plotRGB(EX.L1)

## Shapefile with extent=T (The whole image area will be the shapefile):
EX.L.Shape<- fieldPolygon(mosaic=EX.L1, extent=T) 

## Select one index to identify leaves and remove the background:
EX.L2<- fieldMask(mosaic=EX.L1, index="BGI", cropValue=0.8, cropAbove=T) 
plotRGB(EX.L2$newMosaic)

## Select one index to identify damaged area in the leaves:  
EX.L3<- fieldMask(mosaic=EX.L2$newMosaic, index="VARI",
                  cropValue=0.1, cropAbove=T) 
plotRGB(EX.L3$newMosaic)

## Indices:
EX.L4<- fieldIndex(mosaic=EX.L2$newMosaic, index=index)

# Making a new stack raster with new layers (damaged area and indices)
EX.L5<- stack(EX.L4[[index]], (1-EX.L2$mask), (1-EX.L3$mask)) 
names(EX.L5)<- c(index,"Area","Damage")
plot(EX.L5)

## projection=F (Ignore projection. Normally used only with remote sensing images):
EX.L.Info<- fieldInfo(mosaic=EX.L5, 
                      fieldShape=EX.L.Shape$fieldShape, 
                      projection=F)

## Combine information from all images in one table:
EX.L.Info$plotValue 

## Installing: 
# install.packages("foreach")
# install.packages("parallel")
# install.packages("doParallel")

## Necessary packages:
library(foreach)
library(parallel)
library(doParallel)

## Number of cores:
n.core<-3

## Starting parallel:
cl <- makeCluster(n.core, output = "")
registerDoParallel(cl)
system.time({
  EX.Table <- foreach(i = 1:length(pics), .packages = c("raster", "FIELDimageR"), 
                      .combine = rbind) %dopar% {
                        EX.L1<- stack(paste("./EX2/", pics[i], sep = ""))
                        EX.L.Shape<- fieldPolygon(mosaic=EX.L1, extent=T, plot=F)
                        EX.L2<- fieldMask(mosaic=EX.L1, index="BGI", cropValue=0.8, cropAbove=T, plot=F) 
                        EX.L3<- fieldMask(mosaic=EX.L2$newMosaic, index="VARI", cropValue=0.1, cropAbove=T, plot=F)   
                        EX.L4<- fieldIndex(mosaic=EX.L2$newMosaic, index=index, plot=F)
                        EX.L5<- stack(EX.L4[[index]], (1-EX.L2$mask), (1-EX.L3$mask)) 
                        names(EX.L5)<- c(index,"Area","Damage")
                        EX.L.Info<- fieldInfo(mosaic=EX.L5, fieldShape=EX.L.Shape$fieldShape, projection=F) 
                        EX.L.Info$plotValue 
                      }})

EX.Table.2<- data.frame(Genotype=do.call(rbind, strsplit(pics, split = ".jpeg")), EX.Table[,-1])
EX.Table.2

## Field data:
DataEX2<- read.table("EX2_Data.txt", header = T)
DataEX2$Score_HB<- as.numeric(as.character(DataEX2$Score_HB))
DataEX2$Person<- as.factor(DataEX2$Person)
DataEX2$Genotype<- as.factor(DataEX2$Genotype)
DataEX2

ggplot(DataEX2, aes(x=Genotype, y=Score_HB, fill=Person))+
  facet_wrap(~Genotype, scales = "free_x", nrow = 2)+
  geom_bar(stat="identity", position= position_dodge())+
  scale_fill_grey()+
  theme_bw()+
  theme(axis.text.x= element_blank(),
        axis.ticks.x= element_blank())

## Regression:
DataEX2.1<- ddply(DataEX2, ~Genotype, summarise, Score_HB=mean(Score_HB))
DataEX2.2<- merge(DataEX2.1, EX.Table.2, by="Genotype")
DataEX2.2

DataEX2.3<- melt(DataEX2.2,
                 value.name = "Index",
                 measure.vars = c("Damage","BI","GLI","NGRDI"))
DataEX2.3$Score_HB<- as.numeric(DataEX2.3$Score_HB)
DataEX2.3$Index<- as.numeric(DataEX2.3$Index)
DataEX2.3$variable<- as.factor(DataEX2.3$variable)
DataEX2.3

ggplot(DataEX2.3, aes(x=Index, y=Score_HB, col=variable))+
  facet_wrap(~variable, scales = "free_x")+
  geom_point() +
  geom_smooth(method= lm)+
  theme_bw()
