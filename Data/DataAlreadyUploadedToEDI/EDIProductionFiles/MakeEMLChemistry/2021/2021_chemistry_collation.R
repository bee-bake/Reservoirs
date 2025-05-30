# 2021 nutrient chemistry collation
#includes TNTP, DOC, and np 20201
#Note: flags are aggregated without commas for final EDI upload
#figure out what to do when dups are super different
#NOTE: samples were rerun and need to integrate/average/select values appropriately
  #B21Sep 10m NH4, B15Jun 11m SRP, F08Feb 0.1 NO3, F26Jul 1.6m NO3,  C19Aug 21m NH4+NO3, 
                 # B08Mar 11m, TN+TP, (cant find reason for repeat, averaging both )
                 #B09Aug 10m DOC (cant find reason for repeat, averaging both )
#NOTE for 2022 field sample publication - we removed n=9 samples w/ suspect data (sampleIDs in the 2021 MakeEMLChemistry script) so reran them after 2021 data was published - need to bring that data in (average/replace 2021 runs)
#ALSO, need to replace B01 site with B40 pre-2022

library(tidyverse)
library(dplyr)
library(lubridate)

TNTP <- read.csv("./collation/2021/2021_TNTP_collation.csv")

#delete F 06dec21 wet because no reason to believe that we went to the wetland on this day...
TNTP <- TNTP[TNTP$SampleID_lachat !="F06dec21 wet T",]

#drop samplID col 
TNTP <- TNTP [,!(names(TNTP) %in% c("SampleID_lachat"))]

#drop rows with NA values
TNTP <- TNTP[!is.na(TNTP$TP_ugL) | !is.na(TNTP$TN_ugL) ,]

#add DateTime flag
TNTP$DateTime <- mdy_hm(TNTP$DateTime)
TNTP$Flag_DateTime <- ifelse(TNTP$Notes_lachat=="datetime_flag!", TNTP$Flag_DateTime<- 1, TNTP$Flag_DateTime <- 0)

#also add datetime flag for ISCO because time is from weir sampling
TNTP$Flag_DateTime <- ifelse(TNTP$Site=="100.1",1,TNTP$Flag_DateTime)

#back to character date
TNTP$DateTime <- as.character(TNTP$DateTime)

# set flags for TN & TP
###################################################
# add 7 for rows that will be averaged
###################################################
# create flag columns
# no flag value = 0
TNTP$Flag_TP <- 0
TNTP$Flag_TN <- 0

#order TNTP df
TNTP <- TNTP %>% arrange(Reservoir, DateTime, Site, Depth_m)

# look for duplicate values and average them, while adding flag = 7
TNTP_dups <- duplicated(TNTP[,1:4]) 
table(TNTP_dups)['TRUE']

# create col to put average of reps into
TNTP$TP_ugL_AVG <- 'NA'
TNTP$TN_ugL_AVG <- 'NA'

########## AVERAGING DUPS ####
#average all samples run twice data
for (i in 1:length(TNTP_dups)) {
  if(TNTP_dups[i]=='TRUE'){
    ifelse(TNTP$Rep[i]=="",TNTP$TP_ugL_AVG[i]<- mean(c(TNTP$TP_ugL[i], TNTP$TP_ugL[i-1])), TNTP$TP_ugL_AVG[i])
    ifelse(TNTP$Rep[i]=="",TNTP$TN_ugL_AVG[i]<- mean(c(TNTP$TN_ugL[i], TNTP$TN_ugL[i-1])), TNTP$TN_ugL_AVG[i])
    # assign this to the other duplicate as well
    ifelse(TNTP$Rep[i]=="",TNTP$TP_ugL_AVG[i-1]<- mean(c(TNTP$TP_ugL[i], TNTP$TP_ugL[i-1])), TNTP$TP_ugL_AVG[i-1])
    ifelse(TNTP$Rep[i]=="",TNTP$TN_ugL_AVG[i-1]<- mean(c(TNTP$TN_ugL[i], TNTP$TN_ugL[i-1])), TNTP$TN_ugL_AVG[i-1])
  
    # flag as 7, average of two reps
    ifelse(TNTP$Rep[i]=="", TNTP$Flag_TP[i] <- 7, TNTP$Flag_TP[i])
    ifelse(TNTP$Rep[i]=="",TNTP$Flag_TN[i] <- 7, TNTP$Flag_TN[i])
    ifelse(TNTP$Rep[i]=="",TNTP$Flag_TP[i-1] <- 7, TNTP$Flag_TP[i-1])
    ifelse(TNTP$Rep[i]=="",TNTP$Flag_TN[i-1] <- 7, TNTP$Flag_TN[i-1])
  }  
}

# remove dups (7 in 2021)
TNTP <- TNTP[!TNTP_dups,]

# move the averaged data over to the original columns
for (i in 1:nrow(TNTP)) {
  if(!TNTP$TP_ugL_AVG[i]=='NA'){
    TNTP$TP_ugL[i] <- TNTP$TP_ugL_AVG[i]
    TNTP$TN_ugL[i] <- TNTP$TN_ugL_AVG[i]
  }
}

#remove avg columns at end and rep col
TNTP <- TNTP[,-c(13,14)]

#keep/format rep col
TNTP$Rep <- ifelse(TNTP$Rep=="R2",2,1)

############################################################
#            if below detection, flag as 3                 #
#          independent digestion for each run              # 
#   averaged across all runs for most recent field season   #
#                "rolling spiked blank 250"                #
#                      TP      TN                          #  
#                     10      76.4                         #
############################################################  
#    Historical MDL's:           #
#    2020: TP = 6.8; TN = 72.2   #
#    2021: TP = 10; TN = 76.4    #
##################################


for (i in 1:nrow(TNTP)) {
  ifelse(TNTP$TP_ugL[i] < 10 & TNTP$Flag_TP[i]==7,
    TNTP$Flag_TP[i] <- "73",
  ifelse(TNTP$TP_ugL[i] < 10,
    TNTP$Flag_TP[i] <- 3, TNTP$Flag_TP[i]))
  }


for (i in 1:nrow(TNTP)) {
  ifelse(TNTP$TN_ugL[i] < 76.4 & TNTP$Flag_TN[i]==7,
    TNTP$Flag_TN[i] <- "73",
  ifelse(TNTP$TN_ugL[i] < 76.4,
    TNTP$Flag_TN[i] <- 3, TNTP$Flag_TN[i]))
}

###################################################
# if negative, set to zero and set flag to 4
###################################################

for (i in 1:nrow(TNTP)) {
  if(TNTP$TP_ugL[i] < 0) {TNTP$TP_ugL[i]== 0}
  
  ifelse(TNTP$TP_ugL[i] == 0.000000 & TNTP$Flag_TP[i]=="7",
      TNTP$Flag_TP[i] <- "74",
  ifelse(TNTP$TP_ugL[i] == 0.000000 & TNTP$Flag_TP[i]=="3",
      TNTP$Flag_TP[i] <- "43", 
  ifelse(TNTP$TP_ugL[i] ==	0.000000 & TNTP$Flag_TP[i]=="73",
      TNTP$Flag_TP[i] <- "743",
  ifelse(TNTP$TP_ugL[i] == 0.000000, TNTP$Flag_TP[i] <- "4",
      TNTP$Flag_TP[i]))))
}


for (i in 1:nrow(TNTP)) {
  if(TNTP$TN_ugL[i] < 0) {TNTP$TN_ugL[i] <- 0}
  
  ifelse(TNTP$TN_ugL[i] == 0.000000 & TNTP$Flag_TN[i]=="7",
      TNTP$Flag_TN[i] <- "74",
  ifelse(TNTP$TN_ugL[i] == 0.000000 & TNTP$Flag_TN[i]=="3",
      TNTP$Flag_TN[i] <- "43", 
  ifelse(TNTP$TN_ugL[i] ==	0.000000 & TNTP$Flag_TN[i]=="73",
      TNTP$Flag_TN[i] <- "743",
  ifelse(TNTP$TN_ugL[i] == 0.000000, TNTP$Flag_TN[i] <- "4",
      TNTP$Flag_TN[i]))))
}


############################################
#### WMW code for soluble/DOC collation ####
############################################

#read in 2020_chemistry_collation for DOC 
doc <- read.csv("./collation/2021/2021_TOC_collation.csv")

# create flag columns
# no flag value = 0
doc$Flag_DC <- 0
doc$Flag_DIC <- 0
doc$Flag_DOC <- 0
doc$Flag_DN <- 0

## Flag rows where we used NPOC for CCR tunnel sites (400, 500, 501)
#using Flag #8 for NPOC denotation 
doc <- doc %>% 
  mutate(Flag_DOC = ifelse(Notes_DOC == "run_NPOC", 8, Flag_DOC ) )


#order doc df
doc <- doc %>% arrange(Reservoir, DateTime, Site, Depth_m)

#get rid of notes col
doc<- doc %>% select(-Notes_DOC, Date.NOTES)

#function to select rows based on characters from the end
substrRight <- function(x, n){
  substr(x, nchar(x)-n+1, nchar(x))
}

#make sure all analytes are numeric
doc$DOC_mgL <- as.numeric(doc$DOC_mgL)
doc$DIC_mgL <- as.numeric(doc$DIC_mgL)
doc$DC_mgL <- as.numeric(doc$DC_mgL)
doc$DN_mgL <- as.numeric(doc$DN_mgL)

##################################
### if negative, correct to zero #
###         flag = 4             #
##################################

for (i in 1:nrow(doc)) {
  if(doc$DOC_mgL[i] <0){
    doc$DOC_mgL[i] <- 0
    if(doc$Flag_DOC[i]>0){
      doc$Flag_DOC[i] <- paste0(doc$Flag_DOC[i], 4)
      
    }else{doc$Flag_DOC[i] <- 4}
  }
}


for (i in 1:nrow(doc)) {
  if(doc$DIC_mgL[i] < 0 & !is.na(doc$DIC_mgL[i])){  #added is.na part because on NAs introduced in NPOC data 
    doc$DIC_mgL[i] <- 0
    if(doc$Flag_DIC[i]>0){
      doc$Flag_DIC[i] <- paste0(doc$Flag_DIC[i], 4)
      
    }else{doc$Flag_DIC[i] <- 4}
    
  }
}


for (i in 1:nrow(doc)) {
  if(doc$DC_mgL[i] < 0 & !is.na(doc$DIC_mgL[i])){   #added is.na part because on NAs introduced in NPOC data 
    doc$DC_mgL[i] <- 0
    if(doc$Flag_DC[i]>0){
      doc$Flag_DC[i] <- paste0(doc$Flag_DC[i], 4)
      
    }else{doc$Flag_DC[i] <- 4}
    
  }
}

for (i in 1:nrow(doc)) {
  if(doc$DN_mgL[i] <0){
    doc$DN_mgL[i] <- 0
    if(doc$Flag_DN[i]>0){
      doc$Flag_DN[i] <- paste0(doc$Flag_DN[i], 4)
      
    }else{doc$Flag_DN[i] <- 4}
    
  }
}

##################################
###       average reps           #
###         flag = 7             #
##################################
#switching order here so that we don't average negative values

# clean up DOC data
# look for duplicate values and average them, while adding flag = 7
doc_dups <- duplicated(doc[,1:4],fromLast = TRUE) 
table(doc_dups)['TRUE']

# create col to put average of reps into
doc$DOC_mgLAVG <- 'NA'
doc$DIC_mgLAVG <- 'NA'
doc$DC_mgLAVG <- 'NA'
doc$DN_mgLAVG <- 'NA'

# calculate the average of the two dups
for (i in 1:length(doc_dups)){
  if(doc_dups[i]=='TRUE'){
    doc$DOC_mgLAVG[i]= mean(c(doc$DOC_mgL[i], doc$DOC_mgL[i+1]))
    doc$DIC_mgLAVG[i]= mean(c(doc$DIC_mgL[i], doc$DIC_mgL[i+1]))
    doc$DC_mgLAVG[i]= mean(c(doc$DC_mgL[i], doc$DC_mgL[i+1]))
    doc$DN_mgLAVG[i]= mean(c(doc$DN_mgL[i], doc$DN_mgL[i+1]))
    # assign this to the other duplicate as well
    doc$DOC_mgLAVG[i+1]= mean(c(doc$DOC_mgL[i], doc$DOC_mgL[i+1]))
    doc$DIC_mgLAVG[i+1]= mean(c(doc$DIC_mgL[i], doc$DIC_mgL[i+1]))
    doc$DC_mgLAVG[i+1]= mean(c(doc$DC_mgL[i], doc$DC_mgL[i+1]))
    doc$DN_mgLAVG[i+1]= mean(c(doc$DN_mgL[i], doc$DN_mgL[i+1]))

    ifelse(doc$Flag_DOC[i]==0,  doc$Flag_DOC[i] <- 7, doc$Flag_DOC[i] <- 74)
    ifelse(doc$Flag_DIC[i]==0, doc$Flag_DIC[i] <- 7,doc$Flag_DIC[i] <- 74)
    ifelse(doc$Flag_DC[i]==0, doc$Flag_DC[i] <- 7, doc$Flag_DC[i] <- 74)
    ifelse(doc$Flag_DN[i]==0, doc$Flag_DN[i] <- 7, doc$Flag_DN[i] <- 74)
    ifelse(doc$Flag_DOC[i]==0, doc$Flag_DOC[i+1] <- 7, doc$Flag_DOC[i+1] <- doc$Flag_DOC[i])
    ifelse(doc$Flag_DIC[i]==0, doc$Flag_DIC[i+1] <- 7, doc$Flag_DIC[i+1] <- doc$Flag_DIC[i])
    ifelse(doc$Flag_DC[i]==0, doc$Flag_DC[i+1] <- 7, doc$Flag_DC[i+1] <- doc$Flag_DC[i])
    ifelse(doc$Flag_DN[i]==0, doc$Flag_DN[i+1] <- 7, doc$Flag_DN[i+1] <- doc$Flag_DN[i])
    
  }
}

# get rid of dups
doc <- doc[!(doc_dups=="TRUE"),]

# move the averaged data over to the original columns
for (i in 1:nrow(doc)) {
  if(!doc$DOC_mgLAVG[i]=='NA'){
    doc$DOC_mgL[i] <- doc$DOC_mgLAVG[i]
    doc$DIC_mgL[i] <- doc$DIC_mgLAVG[i]
    doc$DC_mgL[i] <-  doc$DC_mgLAVG[i]
    doc$DN_mgL[i] <-  doc$DN_mgLAVG[i]
  }
}

# and get rid of the average column since that is now in the normal data column
doc <- doc %>% select(-c(DOC_mgLAVG, DIC_mgLAVG, DC_mgLAVG, DN_mgLAVG))

#keep/format rep col
doc$Rep <- ifelse(!is.na(doc$Rep) & doc$Rep=="R2",2,1)



#from last year 
#drop 20Jul20 5m because there are two samples with this label when one should be 8m
# doc <- doc[!(doc$DateTime=="7/20/20 0:00" & doc$Depth_m==5),] 

#delete F 06dec21 wet because no reason to believe that we went to the wetland on this day...
doc <- doc[doc$SampleID_DOC !="F 06dec21 wet",]


#################################################################
#      rolling spiked blank for most recent field season        #
#                 if below detection, flag = 3                  #
#            2021 MDLS (in mg/L) from 'MDL 2021 tab':           #  
#                    DIC     DOC     DC    DN                   #
#                    0.47   0.45   0.69   0.11                  #
#################################################################
#    Historical MDL's:                                     #
#    2020: DIC = 0.97; DOC = 0.76 ; DC = 0.63; DN = 0.05   #
#    2021: DIC = 0.47; DOC = 0.45; DC = 0.69; DN = 0.11    #
############################################################

# DIC
for (i in 1:nrow(doc)) {
  if(doc$DIC_mgL[i] <0.47 & !is.na(doc$DIC_mgL[i])){
    if(doc$Flag_DIC[i]>0){
      doc$Flag_DIC[i] <- paste0(doc$Flag_DIC[i], 3)
      
    }else{doc$Flag_DIC[i] <- 3}
  }
}

# DOC
for (i in 1:nrow(doc)) {
  if(doc$DOC_mgL[i] <0.45){
    if(doc$Flag_DOC[i]>0){
      doc$Flag_DOC[i] <- paste0(doc$Flag_DOC[i], 3)
      
    }
    else{doc$Flag_DOC[i] <- 3}
  }
}

# DC
for (i in 1:nrow(doc)) {
  if(doc$DC_mgL[i] < 0.69 & !is.na(doc$DIC_mgL[i])){
    if(doc$Flag_DC[i]>0){
      doc$Flag_DC[i] <- paste0(doc$Flag_DOC[i], 3)
      
    }else{doc$Flag_DC[i] <- 3}
  }
}

# DN
for (i in 1:nrow(doc)) {
  if(doc$DN_mgL[i] <0.11){
    if(doc$Flag_DN[i]>0){
      doc$Flag_DN[i] <- paste0(doc$Flag_DN[i], 3)
      
    }else{doc$Flag_DN[i] <- 3}
  }
}


############################################################
############################################################
#read in soluble data
np <- read.csv("./collation/2021/2021_soluble_NP_collation.csv")

#convert to character string for subsetting below
np$SampleID_lachat <- as.character(np$SampleID_lachat)
doc$SampleID_DOC <- as.character(doc$SampleID_DOC)

#order np df
np <- np %>% arrange(Reservoir, DateTime, Site, Depth_m)

#drop rows with NA values
np <- np[!is.na(np$NH4_ugL) | !is.na(np$PO4_ugL) | !is.na(np$NO3NO2_ugL),]

#add DateTime flag (also need to count from end bc one sample has average and datetime flag!)
np$Flag_DateTime <- 0
np$Flag_DateTime[grep("datetime_flag!", np$Notes_lachat)] <- 1


##############################################
#           set flags for N & P              #
# if negative, set to zero and set flag to 4 #
##############################################

# initialize flag columns
# no flag value = 0
np$Flag_NH4 <- 0
np$Flag_PO4 <- 0
np$Flag_NO3NO2 <- 0

for (i in 1:nrow(np)) {
  if(!is.na(np$NH4_ugL[i]) & np$NH4_ugL[i] <0){
    np$NH4_ugL[i] <- 0
    if(np$Flag_NH4[i]>0){
      np$Flag_NH4[i] <- paste0(np$Flag_NH4[i], 4)
      }else{np$Flag_NH4[i] <- 4}
  }
}

for (i in 1:nrow(np)) {
  if(!is.na(np$PO4_ugL[i]) & np$PO4_ugL[i] <0){
    np$PO4_ugL[i] <- 0
    if(np$Flag_PO4[i]>0){
      np$Flag_PO4[i] <- paste0(np$Flag_PO4[i], 4)
      
    }else{np$Flag_PO4[i] <- 4}
    
    
  }
}

for (i in 1:nrow(np)) {
  if(!is.na(np$NO3NO2_ugL[i]) & np$NO3NO2_ugL[i] <0){
    np$NO3NO2_ugL[i] <- 0
    if(np$Flag_NO3NO2[i]>0){
      np$Flag_NO3NO2[i] <- paste0(np$Flag_NO3NO2[i], 4)
      
    }else{np$Flag_NO3NO2[i] <- 4}
  }
}

####################
#  averaging dups  #
#    flag = 7      #
####################

# average dups and those with two reps
np_dups <- duplicated(np[,1:4]) 
table(np_dups)['TRUE']


##addressing samples that were rerun for a specific analyte 

#B15Jun 11m SRP - rows 52 and 53
np$PO4_ugL[np$DateTime=="6/15/21 16:52" & np$RunDate=="7/20/21"] <- NA #set inital SRP to NA
np$NH4_ugL[np$DateTime=="6/15/21 16:52" & np$RunDate=="1/26/22"] <- NA #set rerun NH4 to NA
np$NO3NO2_ugL[np$DateTime=="6/15/21 16:52" & np$RunDate=="1/26/22"] <- NA #set rerun NO3 to NA

#B21Sep21 10m NH4 - rows 83 and 84
np$NH4_ugL[np$DateTime=="9/21/21 10:41" & np$RunDate=="10/5/21"] <- NA #set inital NH4 to NA
np$NO3NO2_ugL[np$DateTime=="9/21/21 10:41" & np$RunDate=="1/26/22"] <- NA #set rerun NO3 to NA
np$PO4_ugL[np$DateTime=="9/21/21 10:41" & np$RunDate=="1/26/22"] <- NA #set rerun SRP to NA

#C19Aug21 21m NH4+NO3 - rows 145 and 146 
np$NH4_ugL[np$DateTime=="8/19/21 12:00" & np$RunDate=="10/5/21" & np$Depth_m==21] <- NA #set inital NH4 to NA
np$NO3NO2_ugL[np$DateTime=="8/19/21 12:00" & np$RunDate=="10/5/21" & np$Depth_m==21] <- NA #set inital NO3 to NA
np$PO4_ugL[np$DateTime=="8/19/21 12:00" & np$RunDate=="1/26/22"] <- NA #set rerun SRP to NA

#F08feb21 0.1m NO3 - rows 228 and 229
np$NO3NO2_ugL[np$DateTime=="2/8/21 11:22" & np$RunDate=="6/16/21"] <- NA #set inital NO3 to NA
np$NH4_ugL[np$DateTime=="2/8/21 11:22" & np$RunDate=="1/26/22"] <- NA #set rerun NH4 to NA
np$PO4_ugL[np$DateTime=="2/8/21 11:22" & np$RunDate=="1/26/22"] <- NA #set rerun SRP to NA

#F26jul21 1.6m for NO3 - rows 335 and 336
np$NO3NO2_ugL[np$DateTime=="7/26/21 12:50" & np$RunDate=="10/5/21"] <- NA #set inital NO3 to NA
np$NH4_ugL[np$DateTime=="7/26/21 12:50" & np$RunDate=="1/26/22"] <- NA #set rerun NH4 to NA
np$PO4_ugL[np$DateTime=="7/26/21 12:50" & np$RunDate=="1/26/22"] <- NA #set rerun SRP to NA


# create col to put average of reps into
np$NH4_ugLAVG <- 'NA'
np$PO4_ugLAVG <- 'NA'
np$NO3NO2_ugLAVG <- 'NA'

# calculate the average of the two dups
for (i in 1:length(np_dups)) {
  if(np_dups[i]=='TRUE'){
    np$NH4_ugLAVG[i]= mean(c(np$NH4_ugL[i], np$NH4_ugL[i-1]),na.rm=T)
    np$PO4_ugLAVG[i]= mean(c(np$PO4_ugL[i], np$PO4_ugL[i-1]),na.rm=T)
    np$NO3NO2_ugLAVG[i]= mean(c(np$NO3NO2_ugL[i], np$NO3NO2_ugL[i-1]),na.rm=T)
    # assign this to the other duplicate as well
    np$NH4_ugLAVG[i-1]= mean(c(np$NH4_ugL[i], np$NH4_ugL[i-1]),na.rm=T)
    np$PO4_ugLAVG[i-1]= mean(c(np$PO4_ugL[i], np$PO4_ugL[i-1]),na.rm=T)
    np$NO3NO2_ugLAVG[i-1]= mean(c(np$NO3NO2_ugL[i], np$NO3NO2_ugL[i-1]),na.rm=T)
    
    # flag as 7, average of two reps (conditional to prevent 7 flag if one set of dups include NA)
    ifelse(is.na(np$NH4_ugL[i]) | is.na(np$PO4_ugL[i]) | is.na(np$NO3NO2_ugL[i]), np$Flag_NH4[i] <- np$Flag_NH4[i], np$Flag_NH4[i] <- paste0(7,np$Flag_NH4[i]))
    ifelse(is.na(np$NH4_ugL[i]) | is.na(np$PO4_ugL[i]) | is.na(np$NO3NO2_ugL[i]), np$Flag_PO4[i] <-np$Flag_PO4[i], np$Flag_PO4[i] <- paste0(7,np$Flag_PO4[i]))
    ifelse(is.na(np$NH4_ugL[i]) | is.na(np$PO4_ugL[i]) | is.na(np$NO3NO2_ugL[i]), np$Flag_NO3NO2[i] <- np$Flag_NO3NO2[i], np$Flag_NO3NO2[i] <- paste0(7,np$Flag_NO3NO2[i]))
    ifelse(is.na(np$NH4_ugL[i-1]) | is.na(np$PO4_ugL[i-1]) | is.na(np$NO3NO2_ugL[i-1]) , np$Flag_NH4[i-1] <- np$Flag_NH4[i-1], np$Flag_NH4[i-1] <- paste0(7,np$Flag_NH4[i-1]))
    ifelse(is.na(np$NH4_ugL[i-1]) | is.na(np$PO4_ugL[i-1]) | is.na(np$NO3NO2_ugL[i-1]), np$Flag_PO4[i-1] <- np$Flag_PO4[i-1], np$Flag_PO4[i-1] <- paste0(7,np$Flag_PO4[i-1]))
    ifelse(is.na(np$NH4_ugL[i-1]) | is.na(np$PO4_ugL[i-1]) | is.na(np$NO3NO2_ugL[i-1]), np$Flag_NO3NO2[i-1] <- np$Flag_NO3NO2[i-1], np$Flag_NO3NO2[i-1] <- paste0(7,np$Flag_NO3NO2[i-1]))
  }  
}


# get rid of dups
np_nodups <- np[!np_dups,]

# move the averaged data over to the original columns
for (i in 1:nrow(np_nodups)) {
  if(!np_nodups$NH4_ugLAVG[i]=='NA'){
    np_nodups$NH4_ugL[i] <- np_nodups$NH4_ugLAVG[i]
    np_nodups$PO4_ugL[i] <- np_nodups$PO4_ugLAVG[i]
    np_nodups$NO3NO2_ugL[i] <-  np_nodups$NO3NO2_ugLAVG[i]
  }
}

# and get rid of the average column since that is now in the normal data column
np_nodups <- np_nodups %>% select(-c(NH4_ugLAVG, PO4_ugLAVG, NO3NO2_ugLAVG))
# call it np again for coding ease
np <- np_nodups

#Now manually add 7 flag for samples that were averaged in excel (just the jul21 run)
np$Flag_NH4 <- ifelse(np$Notes_lachat=="AVERAGED so needs 7 flag", paste0(7,np$Flag_NH4), np$Flag_NH4)
np$Flag_PO4 <- ifelse(np$Notes_lachat=="AVERAGED so needs 7 flag", paste0(7,np$Flag_PO4), np$Flag_PO4)
np$Flag_NO3NO2 <- ifelse(np$Notes_lachat=="AVERAGED so needs 7 flag", paste0(7,np$Flag_NO3NO2), np$Flag_NO3NO2)

#change 70 flags to 7
np$Flag_NH4[np$Flag_NH4=="70"] <- "7"
np$Flag_PO4[np$Flag_PO4=="70"] <- "7"
np$Flag_NO3NO2[np$Flag_NO3NO2=="70"] <- "7"

#add rep col
np$Rep <- ifelse(np$Rep=="R2" & !is.na(np$Rep),2,1)

##################################################################
#    2021 field season average: if below detection, flag as 3    #
#    using the following MDL's: ('rolling spiked blank' tab)     #
#                      NH4   PO4   NO3                           # 
#                      7.3   3.1   3.7                           #                        #
##################################################################
#    Historical MDL's:                        #
#    2020: NH4 = 9.6; PO4 = 3.0; NO3 =  4.5   #
#    2021: NH4 = 7.3; PO4 = 3.1; NO3 =  3.7   #
###############################################

for (i in 1:nrow(np)) {
  if(np$NH4_ugL[i] <7.3){
    if(np$Flag_NH4[i]>0){
      np$Flag_NH4[i] <- paste0(np$Flag_NH4[i], 3)
      
    }else{np$Flag_NH4[i] <- 3}
  }
}

for (i in 1:nrow(np)) {
  if(np$PO4_ugL[i] <3.1){
    if(np$Flag_PO4[i]>0){
      np$Flag_PO4[i] <- paste0(np$Flag_PO4[i], 3)
      
    }else{np$Flag_PO4[i] <- 3}
  }
}

for (i in 1:nrow(np)) {
  if(np$NO3NO2_ugL[i] < 3.7){
    if(np$Flag_NO3NO2[i]>0){
      np$Flag_NO3NO2[i] <- paste0(np$Flag_NO3NO2[i], 3)
      
    }else{np$Flag_NO3NO2[i] <- 3}
  }
}

#delete F 06dec21 wet because no reason to believe that we went to the wetland on this day...
np <- np[np$SampleID_lachat!="F 06dec21 wet",]

##########################################################
#add demonic intrusion flags for ?? 
#np$Flag_NO3NO2[which(np$DateTime=='2019-05-23 12:00:00' & np$Depth_m==3.0 & np$NO3NO2_ugL==30.5)] <- "5"



###########################
# join nutrients together #
###########################

#rename PO4_ugL to SRP_ugL and Flag_PO4 to Flag_SRP
colnames(np)[which(names(np) == "PO4_ugL")] <- "SRP_ugL"
colnames(np)[which(names(np) == "Flag_PO4")] <- "Flag_SRP"

#make sure all are in same datetime format 
TNTP <- TNTP %>% 
  mutate(DateTime = ymd_hms(DateTime))

doc <- doc %>% 
  mutate(DateTime = mdy_hm(DateTime))

np <- np %>% 
  mutate(DateTime = mdy_hm(DateTime))

#new df with solubles, totals, and DOC
solubles_and_DOC <- full_join(np, doc, by = c('Reservoir', 'Site', 'DateTime',  'Depth_m','Rep'))
chem <- full_join(TNTP, solubles_and_DOC, by = c('Reservoir', 'Site', 'DateTime',  'Depth_m', 'Rep'))

#get rid of notes and run date
chem <- chem %>% select(-c(RunDate_DOC,RunDate.x,RunDate.y, Notes_lachat.x, Notes_lachat.y,SampleID_DOC, SampleID_lachat,Flag_DateTime.y, Date.NOTES))

chem <- chem %>%
  rename(Flag_DateTime = Flag_DateTime.x) %>% 
  mutate(TP_ugL = as.numeric(TP_ugL),
                        TN_ugL = as.numeric(TN_ugL),
                        NH4_ugL = as.numeric(NH4_ugL),
                        SRP_ugL = as.numeric(SRP_ugL),
                        NO3NO2_ugL = as.numeric(NO3NO2_ugL),
                        DOC_mgL = as.numeric(DOC_mgL),
                        DIC_mgL = as.numeric(DIC_mgL),
                        DC_mgL = as.numeric(DC_mgL),
                        DN_mgL = as.numeric(DN_mgL))

# Round values to specified precision (based on 2018 data on EDI)
chem_final <-chem %>% mutate(SRP_ugL = round(SRP_ugL, 0), 
                NH4_ugL = round(NH4_ugL, 0),
                NO3NO2_ugL = round(NO3NO2_ugL, 0),
                TP_ugL = round(TP_ugL, 1),  
                TN_ugL = round(TN_ugL, 1),  
                DOC_mgL = round(DOC_mgL, 1),
                DIC_mgL = round(DIC_mgL, 1),
                DC_mgL = round(DC_mgL, 1),
                DN_mgL = round(DN_mgL, 3))

chem_final <- chem_final %>% mutate(Flag_TP= as.numeric(Flag_TP),
                        Flag_TN= as.numeric(Flag_TN),
                        Flag_NH4 = as.numeric(Flag_NH4),
                        Flag_SRP = as.numeric(Flag_SRP),
                        Flag_NO3NO2 = as.numeric(Flag_NO3NO2),
                        Flag_DOC = as.numeric(Flag_DOC),
                        Flag_DIC = as.numeric(Flag_DIC),
                        Flag_DC = as.numeric(Flag_DC),
                        Flag_DN = as.numeric(Flag_DN))


#change all NAs to 0 in flag columns
chem_final$Flag_DateTime <- ifelse(is.na(chem_final$Flag_DateTime), 0, chem_final$Flag_DateTime)
chem_final$Flag_DC <- ifelse(is.na(chem_final$Flag_DC), 0, chem_final$Flag_DC)
chem_final$Flag_DN <- ifelse(is.na(chem_final$Flag_DN), 0, chem_final$Flag_DN)
chem_final$Flag_DIC <- ifelse(is.na(chem_final$Flag_DIC), 0, chem_final$Flag_DIC)
chem_final$Flag_DOC <- ifelse(is.na(chem_final$Flag_DOC), 0, chem_final$Flag_DOC)
chem_final$Flag_TP <- ifelse(is.na(chem_final$Flag_TP), 0, chem_final$Flag_TP)
chem_final$Flag_TN <- ifelse(is.na(chem_final$Flag_TN), 0, chem_final$Flag_TN)
chem_final$Flag_NH4 <- ifelse(is.na(chem_final$Flag_NH4), 0, chem_final$Flag_NH4)
chem_final$Flag_NO3NO2 <- ifelse(is.na(chem_final$Flag_NO3NO2), 0, chem_final$Flag_NO3NO2)
chem_final$Flag_SRP <- ifelse(is.na(chem_final$Flag_SRP), 0, chem_final$Flag_SRP)


#order chem
chem_final<- chem_final %>% arrange(Reservoir, DateTime, Site, Depth_m)

#drop sun samples
chem_final <- chem_final[chem_final$Reservoir!="SUN",]

write.csv(chem_final, "./FinalData/2021_chemistry_collation_final_nocommas.csv")

