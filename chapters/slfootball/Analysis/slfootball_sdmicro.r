#https://sdcpractice.readthedocs.io/en/latest/sdcMicro.html

library(sdcMicro)
library(tidyverse)
library(haven)

data <- read_dta("D:/PhD/Papers/Football/pAPER/Replication/Cleaned Data/foot_cleaned.dta")

#the CSV file below characterizes variables present in foot_cleaned.dta
	# - ignore: variable is excluded from the anonymization procedure.
	# - key: variable is considered to useable in re-identifying participants.
	# - sensitive: variable that should remain confidential.
	# - drop: variable that makes identification trivial.
varselection <- read_csv("C:/Users/kld330/git/thesis/chapters/slfootball/Analysis/anonymization_varselection.csv")

#drop the vars that should be dropped
dropvars <- varselection[varselection$action=="drop",'varname'][[1]]
data <- select(data,-dropvars)

#coalesce the ethnicity dummies into one var
ind_ethn <- rep(0,nrow(data))
ind_ethn[data$ind_mende == 1] <- 1
ind_ethn[data$ind_fula == 1] <- 2
ind_ethn[data$ind_mandingo == 1] <- 3
ind_ethn[data$ind_temne == 1] <- 4

data$ind_ethn <- as.factor(ind_ethn)

#create five-year age bins.
age_bins_lower <- floor(data$ind_age/5) * 5
age_bins_upper <- age_bins_lower + 4

#the top and bottom age bin were small, so I combine them
#15 - 14 & 15 - 19 
age_bins_lower[age_bins_lower<=15] <- 10 
age_bins_upper[age_bins_upper<=19] <- 19

#25-29 & 30-34
age_bins_lower[age_bins_lower>=25] <- 25 
age_bins_upper[age_bins_upper>=25] <- 34

#replace the age in the data with the bins
age_bins <- paste(age_bins_lower,age_bins_upper,sep="-")
data$ind_age <- as.factor(age_bins)

#assign variables for sdcmicro using anonymization_varselection.csv
KeyVars <- varselection[varselection$action=="key",'varname'][[1]]
ExcludedVars <- varselection[varselection$action=="ignore",'varname'][[1]]
SensitiveVars <- varselection[varselection$action=="sensitive",'varname'][[1]]

#run sdcmicro
sdcInitial <- createSdcObj(dat = data,
	                       keyVars     = KeyVars,
	                       excludeVars = ExcludedVars)

#examine the frequencies
freq <- freq(sdcInitial, type = 'fk')
View(data[freq==1,KeyVars])
barplot(prop.table(table(data$ind_age)))


# #suppress values to guarantee anonymity
sdcInitial <- localSuppression(sdcInitial, k = 2)

# #data_localsuppress <- data
data[,KeyVars] <- sdcInitial@manipKeyVars 










#set.seed(20220923)
# # Apply PRAM to all selected variables
# sdcInitial_pram <- pram(obj = sdcInitial,
# 						variables=c("ind_ethn"))


#reconstruct the ethnicity dummies
data$ind_mende <- (data$ind_ethn == 1)*1
data$ind_fula <- (data$ind_ethn == 2)*1
data$ind_mandingo <- (data$ind_ethn == 3)*1
data$ind_temne <- (data$ind_ethn == 4)*1
data$ind_ethn <- NULL

data$ind_age2 <- data$ind_age^2

write_dta(
  data=data,
  path = "D:/PhD/Papers/Football/pAPER/Replication/Cleaned Data/foot_anon.dta",
  version = 14)

write_csv(
  data,
  file = "D:/PhD/Papers/Football/pAPER/Replication/Cleaned Data/foot_anon.csv")


library(DDIwR)
convert(from=data,to="D:/PhD/Papers/Football/pAPER/Replication/Cleaned Data/foot_anon.xml",)