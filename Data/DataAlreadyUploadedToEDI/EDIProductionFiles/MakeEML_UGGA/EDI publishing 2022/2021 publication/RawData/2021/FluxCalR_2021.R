## Script to *try* FluxCalR for calculating fluxes from UGGA data
## A Hounshell, 25 Jan 2021


# Script following: https://github.com/junbinzhao/FluxCalR

# Load in 'remotes' package
pacman::p_load(remotes,tidyverse,FluxCalR)

# Install FluxCalR (if not already installed! If installed, skip to library(FluxCalR))
remotes::install_github("junbinzhao/FluxCalR",build_vignettes = TRUE)
library(FluxCalR)

# Load in data: will need to load in individual files - I recommend doing this by year
#wd <- setwd("~/Desktop/Reservoirs/Data/DataNotYetUploadedToEDI/UGGA/UGGA_Raw/2021/TextFiles")
wd <- setwd("~/Desktop/github/Reservoirs/Data/DataNotYetUploadedToEDI/UGGA/UGGA_Raw/2021/TextFiles")
#wd <- setwd("C:/Users/ahoun/Desktop/Reservoirs/Data/DataNotYetUploadedToEDI/UGGA/UGGA_Raw/2020/TextFiles")
# You'll want to save this script in the same working directory to keep a record of what files
# you have corrected.

# Load in flux data - load in all text files from the 'TextFiles' folder here.
# This can be used as a record of what files you have already corrected.
flux_lgr_2 <- LoadLGR(file ="./gga_2021-04-26_f0000.txt",
                      time_format = "mdy_HMS")

# Select times when the UGGA was on/off the water
# Select the time point BEFORE the peak for both reps
# Instructions: Use the cursor to select the timepoint before the peak; click once for the first peak and again for
# the second peak. When finished, click on 'Stop' in the upper left-hand corner and then click 'Stop locator'
# This generates a list of 'end' times for each peak saved as time_cue_x
time_cue_2 <- SelCue(flux_lgr_2,flux="CH4",cue="End",save=F)

# Repeat this for all timepoints


# Then calculate fluxes
Flux_output2 <- FluxCal(data = flux_lgr_2, # Dataframe loaded in
                        win = 4, # Window length = 4 minutes
                        vol = 0.020876028*1000, # Volume of trap in liters
                        area = 0.1451465, # Area of trap in m^2
                        df_cue = time_cue_2, # End times selected using SelCue
                        cue_type = "End", # Designate that these times are for the end
                        ext = 1, # Multiplier for time window to look at data (5 min x 1 = use full 5 min interval)
                        output = FALSE)

# Combine all flux outputs
flux_output <- rbind(Flux_output2)

# Get together for publication to EDI
flux_co2 <- flux_output %>% 
  filter(Gas == "CO2") %>% 
  rename(co2_slope_ppmS = Slope, co2_R2 = R2, co2_flux_umolCm2s = Flux) %>% 
  select(-Gas)

flux_ch4 <- flux_output %>% 
  filter(Gas == "CH4") %>% 
  rename(ch4_slope_ppmS = Slope, ch4_R2 = R2, ch4_flux_umolCm2s = Flux) %>% 
  select(-Gas)

flux_all <- left_join(flux_co2,flux_ch4,by=c("Num","Date","Start","End","Ta"))

# NOTE: For 2020 - all data came from FCR at site 50
# THIS IS NOT THE CASE FOR ALL YEARS - you'll have to go back into the field sheets and
# look to see what reservoir the data came from (should all be at site 50 : )
flux_all <- flux_all %>% 
  rename(Rep = Num, Start_time = Start, End_time = End, Temp_C = Ta) %>% 
  mutate (Reservoir = "FCR", Site = 50, co2_flux_umolCm2s_flag = 0, ch4_flux_umolCm2s_flag = 0)

col_order <- c("Reservoir","Site","Date","Rep","Start_time","End_time","Temp_C","co2_slope_ppmS","co2_R2",
               "co2_flux_umolCm2s","ch4_slope_ppmS","ch4_R2","ch4_flux_umolCm2s","co2_flux_umolCm2s_flag",
               "ch4_flux_umolCm2s_flag")

flux_all_2 <- flux_all

# Plots to double check data!
flux_all_2$Date <- as.POSIXct(strptime(flux_all_2$Date,"%Y-%m-%d", tz="EST"))

ggplot()+
  geom_point(flux_all_2,mapping=aes(x=Date,y=co2_flux_umolCm2s,color="CO2"))+
  geom_point(flux_all_2,mapping=aes(x=Date,y=ch4_flux_umolCm2s,color="CH4"))+
  ylab("flux_umolCm2s")

# Export out fluxes
write_csv(flux_all_2,"./20220106_Flux_Output.csv") #change this!
