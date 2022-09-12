#https://sdcpractice.readthedocs.io/en/latest/sdcMicro.html

library(sdcMicro)
library(tidyverse)
library(haven)



data <- read_dta("E:/PhD/Papers/Football/pAPER/Replication/Cleaned Data/foot_cleaned.dta")
varselection <- read_csv("C:/Users/kld330/git/thesis/chapters/slfootball/Analysis/anonymization_varselection.csv")

dropvars <- varselection[varselection$action=="drop",'varname'][[1]]
data <- select(data,-dropvars)

age_bins_lower <- floor(data$ind_age/5) * 5
age_bins_upper <- age_bins_lower + 4

#combine small age bins

#15 - 14 & 15 - 19 
age_bins_lower[age_bins_lower<=15] <- 10 
age_bins_upper[age_bins_upper<=19] <- 19

#25-29 & 30-34
age_bins_lower[age_bins_lower>=25] <- 25 
age_bins_upper[age_bins_upper>=25] <- 34


age_bins <- paste(age_bins_lower,age_bins_upper,sep="-")
data$ind_age <- as.factor(age_bins)

KeyVars <- varselection[varselection$action=="key",'varname'][[1]]
ExcludedVars <- varselection[varselection$action=="ignore",'varname'][[1]]
SensitiveVars <- varselection[varselection$action=="sensitive",'varname'][[1]]

sdcInitial <- createSdcObj(dat = data,
	                       keyVars     = KeyVars,
	                       excludeVars = ExcludedVars)

freq <- freq(sdcInitial, type = 'fk')

View(data[freq==1,selectedKeyVars])
barplot(prop.table(table(data$ind_age)))


 sdcInitial <- localSuppression(sdcInitial, k = 2)

 data[,KeyVars] <- sdcInitial@manipKeyVars 