Classifying deaths in Washington State by homelessness status
================
Maya Bhat-Gregerson
Fall 2018

-   [I. Overview](#i.-overview)
-   [II. Data pre-processing](#ii.-data-pre-processing)
    -   [A. Overview](#a.-overview)
    -   [B. Washington State mortality data - pre-processing](#b.-washington-state-mortality-data---pre-processing)
    -   [C. King County Medical Examiner\`s Homeless Death Registry data - November 2003 to September 2017](#c.-king-county-medical-examiners-homeless-death-registry-data---november-2003-to-september-2017)
-   [III. EXPLORATORY DATA ANALYSIS](#iii.-exploratory-data-analysis)
    -   [A. Assessing missing values](#a.-assessing-missing-values)

I. Overview
-----------

The purpose of this project is to create a machine learning model that will classify deaths in Washington State according to the residential status of decedents at the time of death i.e. with permanent housing vs. homeless.

The data sets used for this project include Washington State final annual death files 2003-2017(including records for all deaths occurring within Washington State in a given calendar year) and the King County Medical Examiner Office\`s registry of deaths among homeless individuals who died in King County, Washington. This registry contains identification information and place of death for homeless individuals who died between 2003 through late 2017.

II. Data pre-processing
-----------------------

### A. Overview

#### 1. Data cleaning and standardization

This step includes:

1.  Limiting Washington annual mortality data sets (WAMD) to attributes that are likely to be relevant to training the machine learning model.

2.  Standardizing attribute names and formats in both WAMD and King County Homeless Death Registry (HDR) data. Due to changes in data collection practices for WAMD over the years, attribute names and formats are inconsistent.

3.  Limiting records in WAMD to decedents who were Washington State residents who died in Washington State.

#### 2. Homeless decedents - linking homeless death data to their death certificates

This step will add the additional attributes from WAMD to each of the records in HDR so that they have the necessary attributes to train the model. In its raw form, HDR contains very limited information about the homeless individuals who died including their names, dates of birth, dates of death, and places (address) of death.

#### 3. Decedents with permanent homes - Creating a sample

This subset will be limited to approximately 1,200 randomly selected records from the 2016 WAMD data file for decedents who had permanent homes at the time of death (as indicated by the facility type and place of death variables). Only decedents who died in King County will be included to match the residence of the homeless decedents.

### B. Washington State mortality data - pre-processing

Washington State requires by law that all deaths occurring in the state must be registered with the Washington State Department of Health by the funeral director organizing the disposal of the body and the decedents\` regular health care provider. In the absence of a health care provider the medical examiner or coroner in the county where the body was found has jurisdiction over the death.

The size of each annual file has increased over the years, both in terms of number of records and in terms of attributes. Attribute names and data types have not been consistent over the years. By 2017 Washington State's death data set included over 58,000 unique observations (death certificate records) and over 250 attributes. Most of the attributes are not relevant to train the machine learning model for this project.

This section addresses cleaning and limiting the data sets (in terms of number of attributes).

#### 1. **Cleaning and standardizing WAMD annual data 2003-2017**

``` r
#CREATE VECTORS OF ATTRIBUTES TO KEEP.  THERE ARE 4 VECTORS - 'KEEPVARS1' THRU 'KEEPVARS4' - DUE TO THE CHANGES IN ATTRIBUTE NAMES OVER THE YEARS.

keepvars1 <- c("certno" , "last_name" , "first_name" ,"middle_name" , "date_of_death" , "dob" , "ssn" , "res_street" , "res_city" , "res_zip" , "sex" , "dth_yr" , "race" , "hisp" , "cnty_occ" , "facility" , "fac_type" , "married" , "city_res" , "cnty_res" , "underly" , "attclass" , "educ" , "zipcode", "st_res", "st_occ")

keepvars2 <- c("certno" , "lastname" , "firstname" ,"middlename" , "dateofdeath" , "dob" , "ssn" , "resstreet" , "rescity" , "reszip" , "sex" , "dth_yr" , "race" , "hisp" , "cnty_occ" , "facility" , "fac_type" , "married" , "city_res" , "cnty_res" , "underly" , "attclass" , "educ" , "zipcode", "st_res", "st_occ")

keepvars3 <- c("certno", "decedentlastname", "decedentfirstname", "decedentmiddlename", "dateofdeath", "dateofbirth", "socialsecuritynumber", "residencestreet", "residencecity", "residencezipcode", "sex", "dateofdeathyear", "bridgerace", "hispanicno", "deathcountywacode", "deathfacility", "placeofdeathtype", "maritalstatus", "residencecountycitywacode", "residencecountywacode", "underlyingcausecode", "certifierdesignation", "education", "deathzipcode", "residencestatefipscode","deathstate")

keepvars4 <- c("certno", "decedentlastname", "decedentfirstname", "decedentmiddlename", "dateofdeath", "dateofbirth", "socialsecuritynumber", "residencestreet", "residencecity", "residencezipcode", "sex", "dateofdeathyear", "bridgerace", "hispanicno", "deathcountywacode", "deathfacility", "placeofdeathtype", "maritalstatus", "residencecountycitywacode", "residencecountywacode", "underlyingcodcode", "certifierdesignation", "education", "deathzipcode", "residencestatefipscode","deathstate")


# CREATE VECTOR OF STANDARDIZED NAMES FOR THE ATTRIBUTES RETAINED.

newnames <- c("certno", "lname", "fname", "mname", "dod", "dob", "ssn", "resst", "rescity", "reszip", "sex", "dthyr", "race", "hisp", "cntyocc", "facility", "factype", "married", "cityres", "cntyres", "underly", "attclass", "educ", "zip", "stres", "stocc")


# CREATE VECTOR OF ATTRIBUTES THAT WILL BE CONVERTED FROM STRING TO FACTOR.

facvars <- c( "rescity", "reszip", "sex", "dthyr", "race", "hisp", "cntyocc", "facility", "factype", "married", "cityres", "cntyres", "underly", "attclass", "educ", "zip", "stres", "stocc")

# PROCESSING OF ANNUAL MORTALITY DATA FILES 2003-17. STEPS INCLUDE: READING, KEEPING SELECTED ATTRIBUTES, LIMITING TO DEATHS AMONG WASHINGTON STAT RESIDENTS WHO DIED WITHIN THE STATE, COERCING STRINGS TO DATES WHERE APPROPRIATE.


dth03 <- fread("H:/Mortality/Homeless/IntroDSCapstone/Data/statname2003.csv", 
               select = keepvars1)
dth03_wa <- subset(dth03, st_res==48 & st_occ==48)
names(dth03_wa)=newnames
dth03_wa$dob <- dmy(dth03_wa$dob)
dth03_wa$dod <- dmy(dth03_wa$dod)


dth04 <-fread("H:/Mortality/Homeless/IntroDSCapstone/Data/statname2004.csv", 
               select = keepvars1)
dth04_wa <- subset(dth04, st_res==48 & st_occ==48)
names(dth04_wa)=newnames
dth04_wa$dob <- dmy(dth04_wa$dob)
dth04_wa$dod <- dmy(dth04_wa$dod)


dth05 <-fread("H:/Mortality/Homeless/IntroDSCapstone/Data/statname2005.csv", 
               select = keepvars1)
dth05_wa <- subset(dth05, st_res==48 & st_occ==48)
names(dth05_wa)=newnames
dth05_wa$dob <- dmy(dth05_wa$dob)
dth05_wa$dod <- dmy(dth05_wa$dod)


dth06 <-fread("H:/Mortality/Homeless/IntroDSCapstone/Data/statname2006.csv", 
               select = keepvars1)
dth06_wa <- subset(dth06, st_res==48 & st_occ==48)
names(dth06_wa)=newnames
dth06_wa$dob <- dmy(dth06_wa$dob)
dth06_wa$dod <- dmy(dth06_wa$dod)


dth07 <-fread("H:/Mortality/Homeless/IntroDSCapstone/Data/statname2007.csv", 
               select = keepvars1)
dth07_wa <- subset(dth07, st_res==48 & st_occ==48)
names(dth07_wa)=newnames
dth07_wa$dob <- dmy(dth07_wa$dob)
dth07_wa$dod <- dmy(dth07_wa$dod)


dth08 <-fread("H:/Mortality/Homeless/IntroDSCapstone/Data/statname2008.csv", 
               select = keepvars1)
dth08_wa <- subset(dth08, st_res==48 & st_occ==48)
names(dth08_wa)=newnames
dth08_wa$dob <- dmy(dth08_wa$dob)
dth08_wa$dod <- dmy(dth08_wa$dod)


dth09 <- fread("H:/Mortality/Homeless/IntroDSCapstone/Data/statname2009.csv", 
               select = keepvars1)
dth09_wa <- subset(dth09, st_res==48 & st_occ==48)
names(dth09_wa)=newnames
dth09_wa$dob <- dmy(dth09_wa$dob)
dth09_wa$dod <- dmy(dth09_wa$dod)


dth10 <- fread("H:/Mortality/Homeless/IntroDSCapstone/Data/statname2010.csv", 
               select = keepvars2)
dth10_wa <- subset(dth10, st_res==48 & st_occ==48)
names(dth10_wa)=newnames
dth10_wa$dob <- ymd(dth10_wa$dob)
```

    ## Warning: 1 failed to parse.

``` r
dth10_wa$dod <- ymd(dth10_wa$dod)


dth11 <- fread("H:/Mortality/Homeless/IntroDSCapstone/Data/statname2011.csv", 
               select = keepvars2)
dth11_wa <- subset(dth11, st_res==48 & st_occ==48)
names(dth11_wa)=newnames
dth11_wa$dob <- ymd(dth11_wa$dob)
```

    ## Warning: 4 failed to parse.

``` r
dth11_wa$dod <- ymd(dth11_wa$dod)


dth12 <- fread("H:/Mortality/Homeless/IntroDSCapstone/Data/statname2012.csv", 
               select = keepvars2)
dth12_wa <- subset(dth12, st_res==48 & st_occ==48)
names(dth12_wa)=newnames
dth12_wa$dob <- ymd(dth12_wa$dob)
```

    ## Warning: 3 failed to parse.

``` r
dth12_wa$dod <- ymd(dth12_wa$dod)


dth13 <- fread("H:/Mortality/Homeless/IntroDSCapstone/Data/statname2013.csv", 
               select = keepvars2)
dth13_wa <- subset(dth13, st_res==48 & st_occ==48)
names(dth13_wa)=newnames
dth13_wa$dob <- ymd(dth13_wa$dob)
```

    ## Warning: 1 failed to parse.

``` r
dth13_wa$dod <- ymd(dth13_wa$dod)


dth14 <- fread("H:/Mortality/Homeless/IntroDSCapstone/Data/statname2014.csv", 
               select = keepvars2)
dth14_wa <- subset(dth14, st_res==48 & st_occ==48)
names(dth14_wa)=newnames
dth14_wa$dob <- ymd(dth14_wa$dob)
```

    ## Warning: 1 failed to parse.

``` r
dth14_wa$dod <- ymd(dth14_wa$dod)


dth15 <- fread("H:/Mortality/Homeless/IntroDSCapstone/Data/statname2015.csv", 
               select = keepvars2)
dth15_wa <- subset(dth15, st_res==48 & st_occ==48)
names(dth15_wa)=newnames
dth15_wa$dob <- ymd(dth15_wa$dob)
```

    ## Warning: 8 failed to parse.

``` r
dth15_wa$dod <- ymd(dth15_wa$dod)


dth16 <- fread("Data/statname2016.csv",
               select = keepvars3)
dth16_wa <- subset(dth16, residencestatefipscode=="WA" & deathstate=="WASHINGTON")
names(dth16_wa)=newnames
dth16_wa$dob <- mdy(dth16_wa$dob)
dth16_wa$dod <- mdy(dth16_wa$dod)


dth17 <- fread("Data/statname2017.csv",
               select = keepvars4)
dth17_wa <- subset(dth17, residencestatefipscode=="WA" & deathstate=="WASHINGTON")
names(dth17_wa)=newnames
dth17_wa$dob <- mdy(dth17_wa$dob)
```

    ## Warning: 2 failed to parse.

``` r
dth17_wa$dod <- mdy(dth17_wa$dod)


#CREATE SINGLE DATAFRAME THAT APPENDS ALL SINGLE YEAR DATA FRAMES INTO ONE

dth0317 <- rbind(dth03_wa, dth04_wa, dth05_wa, dth06_wa, dth07_wa, dth08_wa, dth09_wa, dth10_wa, dth11_wa, dth12_wa, dth13_wa, dth14_wa, dth15_wa, dth16_wa, dth17_wa, fill = TRUE)


#COERCE STRINGS TO FACTORS AS APPROPRIATE AND REMOVE LEADING/TRAILING WHITE SPACE FROM DECEDENT'S NAME FIELDS TO ASSURE ACCURATE LINKAGE IN FORTHCOMING STEPS.

dth0317 %<>% mutate_at(facvars, funs(factor(.)))
dth0317$lname <- str_squish(dth0317$lname)
dth0317$fname <- str_squish(dth0317$fname)
```

#### 2. **Creating a training data set of decedents who had permanent homes at time of death**

A sample of decedents with permanent homes at the time of death were identified using the attribute "Place of Death Type", a factor with the following levels: 0 = Home 1 = Other Place 2 = In Transport 3 = Emergency Room 4 = Hospital (Inpatient) 5 = Nursing Home/Long Term Care 6 = Hospital 7 = Hospice Facility 8 = Other Person's Residence 9 = Unknown

Decedents with `Place of Death Type` reported as `Hospice`, `Nursing Home/Longterm Care`, or `Home` were selected. Additional restrictions included a residential address geocoding match score of over 95 (out of 100). This criterion will exclude persons with incomplete or missing death addresses.

Another restriction on the sampling frame was that all decedents had to be King County residents so that they matched the homeless decedents in this aspect.

``` r
#READ 2016 DEATH FILE AND CREATE A SUBSET OF RECORDS WHERE DECEDENT DIED AT HOME, IN A HOSPICE FACILITY, OR A LONGTERM CARE/NURSING HOME FACILITY. RESTRICT TO KING COUNTY RESIDENTS.

wa16full <- fread("H:/Mortality/Homeless/IntroDSCapstone/Data/Death_FullF16Internal.csv", 
                  select = c('State file number', "Decedent last name", "Decedent first name", "Decedent middle name", "Date of Death", "Date of Birth", "Social Security Number", "Residence Street", "Residence City", "Residence Zip", "Sex", "Date of Death year", "Bridge race", "Hispanic No", "Death County WA code", "Death Facility", "Place of Death type", "Marital", "Residence City WA code", "Residence County WA code", "Underlying COD code", "Certifier Designation", "Education", "Death Zip Code", "Residence State FIPS code","Death State", "Res Geo Match Score"))

permhome <- subset(wa16full, (`Place of Death type`==0 | `Place of Death type`==5 | `Place of Death type`==7) & `Res Geo Match Score` >=95 & `Residence County WA code`==17)

permhome <- select(permhome, -`Res Geo Match Score`)
names(permhome)=newnames

##RANDOMLY SELECT 1,200 persons from "permhome"

set.seed(1)
sample <- sample(1:nrow(permhome), 1200)
withhome <- permhome[sample, ]

str(withhome)
```

    ## Classes 'data.table' and 'data.frame':   1200 obs. of  26 variables:
    ##  $ certno  : int  2016014362 2016020418 2016030892 2016049286 2016010931 2016048745 2016051352 2016035591 2016033864 2016003224 ...
    ##  $ lname   : chr  "BAKKE" "POWELL" "LAND" "BARKER" ...
    ##  $ fname   : chr  "LETA" "SYLVIA" "JAMES" "PUI" ...
    ##  $ mname   : chr  "SUE" "DOROTHY" "DALE" "CHUN" ...
    ##  $ dod     : chr  "4/3/2016" "5/13/2016" "7/30/2016" "12/3/2016" ...
    ##  $ dob     : chr  "8/4/1965" "10/20/1935" "2/24/1948" "11/11/1925" ...
    ##  $ ssn     : int  539783850 534723848 535508674 538565009 538304242 22289354 540382891 516269266 173226642 574186481 ...
    ##  $ resst   : chr  "37901 247TH AVE SE" "1655 180TH AVE NE" "905 E MACLYN ST" "12437 SE 198TH PL" ...
    ##  $ rescity : chr  "ENUMCLAW" "BELLEVUE" "KENT" "KENT" ...
    ##  $ reszip  : chr  "98022" "98008" "98030" "98031" ...
    ##  $ sex     : chr  "F" "F" "M" "F" ...
    ##  $ dthyr   : int  2016 2016 2016 2016 2016 2016 2016 2016 2016 2016 ...
    ##  $ race    : int  1 1 1 5 1 1 1 1 1 1 ...
    ##  $ hisp    : chr  "Y" "Y" "Y" "Y" ...
    ##  $ cntyocc : int  17 17 27 17 17 17 17 17 17 17 ...
    ##  $ facility: int  810 810 800 810 810 810 800 800 800 810 ...
    ##  $ factype : int  0 0 5 0 0 0 5 5 5 0 ...
    ##  $ married : chr  "M" "W" "D" "W" ...
    ##  $ cityres : int  1704 1707 1705 1705 1711 1729 1701 1704 1706 1703 ...
    ##  $ cntyres : int  17 17 17 17 17 17 17 17 17 17 ...
    ##  $ underly : chr  "C900" "C459" "I713" "N189" ...
    ##  $ attclass: int  1 3 1 1 1 1 7 7 1 1 ...
    ##  $ educ    : int  3 4 4 1 3 6 7 4 7 4 ...
    ##  $ zip     : int  98022 98008 98405 98031 98011 98038 98125 98022 98034 98092 ...
    ##  $ stres   : chr  "WA" "WA" "WA" "WA" ...
    ##  $ stocc   : chr  "WASHINGTON" "WASHINGTON" "WASHINGTON" "WASHINGTON" ...
    ##  - attr(*, ".internal.selfref")=<externalptr>

### C. King County Medical Examiner\`s Homeless Death Registry data - November 2003 to September 2017

This data set includes all deaths to homeless or transient individuals who died in King County, Washington State and for whom the death certifier (the person who submitted a death certificate to Washington State Department of Health) was the medical examiner for King County.

The King County Medical Examiner`s Office (KCMEO) established a given decedent`s homeless or transient status by gathering information from family members, acquaintances, social service agencies, and law enforcement (where available). In some situations, the medical examiner (ME) established homelessness based on his own assessment of the situation rather than what the family reported because the stigma associated with homelessness may have resulted in inaccurate reporting.

KCMEO defines `homelessness` based on the Chief Medical Examiner\`s criteria rather than standard federal Department of Housing and Urban Development (HUD) or Department of Social and Health Services (DSHS) criteria.

#### 1. **Cleaning KCMEO homeless registry**

``` r
homeless <- read_csv("H:/Mortality/Homeless/IntroDSCapstone/Data/HomelessRegistryKingCo.csv")


homeless <- rename(homeless, 
         lname = namelast,
         fname = namefirst,
         mname = namemiddle,
         dob = birthdate,
         age_h = age,
         dod = eventdate, 
         ssn = ssn,
         zip = deathzip,
         married = maritalstatus,
         casenumkcme = casenum,
         placeofdeath = deathplace)

homeless<- mutate_all(homeless, funs(toupper))
homeless$lname <- str_squish(homeless$lname)
homeless$fname <- str_squish(homeless$fname)
##THE FOLLOWING CHANGES TO THE TWO DATE FIELDS (DATE OF BIRTH AND DATE OF DEATH) HAVE BEEN IMPLEMENTED TO MAKE
## THEM CONSISTENT WITH THE FORMAT IN THE DEATH CERTIFICATE DATA SET.  

#REMOVE HYPHENS IN DATES OF BIRTH AND DEATH TO MAKE THEM CONSISTENT WITH DEATH DATA
#DATES ARE IN DDMMMYY FORMAT TO BEGIN WITH.
homeless$dob <- gsub("-", "", homeless$dob)
homeless$dod <- gsub("-", "", homeless$dod)

#PASTE LEADING 0 TO DAY WHEN DAY IS 1 TO 9 TO MAKE THEM ALL 2 DIGIT DAYS
homeless$dob <- ifelse((nchar(homeless$dob)) < 7, paste("0",homeless$dob, sep = ""), homeless$dob)
homeless$dod <- ifelse((nchar(homeless$dod)) < 7, paste("0",homeless$dod, sep = ""), homeless$dod)

homeless$dob <- as.Date(homeless$dob, "%d%b%y")
homeless$dob <-as.Date(ifelse(homeless$dob > "2019-01-01", format(homeless$dob, "19%y-%m-%d"), format(homeless$dob)))
homeless$dob <- ymd(homeless$dob)

homeless$dod <- dmy(homeless$dod)

head(homeless, 10)
```

    ## # A tibble: 10 x 17
    ##    casenumkcme lname fname mname age_h resaddr rescity married dob       
    ##    <chr>       <chr> <chr> <chr> <chr> <chr>   <chr>   <chr>   <date>    
    ##  1 02-01287    POMME FRAN~ XAVI~ 51    NO PER~ <NA>    NEVER ~ 1951-01-04
    ##  2 03-01549    PATT~ FRAN~ DELA~ 42    NO PER~ <NA>    NEVER ~ 1961-07-21
    ##  3 03-01823    MANS~ JOHN  PATR~ 41    NO PER~ SEATTLE NEVER ~ 1962-04-17
    ##  4 03-01864    SPAR~ MARL~ RADC~ 44    NO PER~ SEATTLE NEVER ~ 1959-05-19
    ##  5 03-01873    HATF~ JOSH~ MICH~ 30    NO PER~ <NA>    NEVER ~ 1973-12-26
    ##  6 04-00003    BRYA~ RYAN  MICH~ 23    POSSIB~ TACOMA  NEVER ~ 1980-09-17
    ##  7 04-00016    ROTH  DENN~ ROBE~ 35    3110 C~ AUBURN  NEVER ~ 1968-07-15
    ##  8 04-00024    BEAM~ DOLO~ <NA>  54    158 23~ SEATTLE NEVER ~ 1949-05-02
    ##  9 04-00043    THOM~ JEFF~ TRAV~ 57    NO PER~ COVING~ NEVER ~ 1946-06-15
    ## 10 04-00050    HUMA~ <NA>  <NA>  0     <NA>    <NA>    UNKNOWN NA        
    ## # ... with 8 more variables: placeofdeath <chr>, deathaddr <chr>,
    ## #   deathcity <chr>, zip <chr>, dod <date>, eventaddr <chr>,
    ## #   eventcity <chr>, ssn <chr>

#### 2. **Linking HDR with WAMD**

The HDR contains name, date of birth, date of death, place of death (address), and social security number. There is no additional information on cause of death, or other attributes that might be used in machine learning to classify persons as homeless or with a permanent home. For this reason, the HDR data must first be linked to full death certificate data to add the relevant attributes that can be found in the death certificate.

KCMEO is required by law to submit a death certificate for all deaths it investigates. For this reason, it is very likely that the decedents' last names, first names, and locations of death will be recorded in an identical manner in HDR as well as the death certificates (barring data entry error).

In this situation it is possible to use deterministic linkage to link HDR records with their complete death certificates. Using a derived attribute created by concatenating attributes in the HDR data set with low missing data ("namelast", "deathcity", "deathaddress", and "birthdate") and matching it with the same derived variable in the death data set should result in an accurate match and record linkage.

Pre-processing of the HDR and death data sets includes standardizing the values in the attributes to be used in the linkage, and creating the derived variable (concatenation of the above variables) in both data sets.

``` r
## left join homeless data by year (otherwise datasets are too large) with death certificate data

## rbind all individual years of data together

homelessfull <- left_join(homeless, dth0317, by = c("lname", "fname", "dob"))

homelessfinal <- distinct(homelessfull)
```

III. EXPLORATORY DATA ANALYSIS
------------------------------

### A. Assessing missing values

#### 1. **Missing valuesin Homeless data set**

Missing values in any of the attributes in either HDR or death certificate data may be useful in the upcoming machine learning phase as it is very likely that a key distinction between decedents who were homeless vs. those who had permanent homes is that their records cannot be completed due to lack of information from family members or other "informants".

``` r
miss_var_summary(homelessfinal)
```

    ## # A tibble: 40 x 3
    ##    variable  n_miss pct_miss
    ##    <chr>      <int>    <dbl>
    ##  1 rescity.x    613     54.2
    ##  2 educ         541     47.8
    ##  3 certno       436     38.5
    ##  4 mname.y      436     38.5
    ##  5 dod.y        436     38.5
    ##  6 ssn.y        436     38.5
    ##  7 resst        436     38.5
    ##  8 rescity.y    436     38.5
    ##  9 reszip       436     38.5
    ## 10 sex          436     38.5
    ## # ... with 30 more rows

#### 2. **Missing values in 'with home' data set**

``` r
miss_var_summary(withhome)
```

    ## # A tibble: 26 x 3
    ##    variable n_miss pct_miss
    ##    <chr>     <int>    <dbl>
    ##  1 race          4   0.333 
    ##  2 zip           1   0.0833
    ##  3 certno        0   0     
    ##  4 lname         0   0     
    ##  5 fname         0   0     
    ##  6 mname         0   0     
    ##  7 dod           0   0     
    ##  8 dob           0   0     
    ##  9 ssn           0   0     
    ## 10 resst         0   0     
    ## # ... with 16 more rows
