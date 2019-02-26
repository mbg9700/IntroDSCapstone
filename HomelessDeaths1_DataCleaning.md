I. Classification of Homeless Deaths: data cleaning and preparation
================
Maya Bhat-Gregerson
February 26, 2019

-   [I. Overview](#i.-overview)
-   [II. Data pre-processing](#ii.-data-pre-processing)
    -   [A. Overview](#a.-overview)
        -   [1. Data cleaning and standardization](#data-cleaning-and-standardization)
        -   [2. Homeless decedents - linking homeless death data to their death certificates](#homeless-decedents---linking-homeless-death-data-to-their-death-certificates)
        -   [3. Decedents with homes - creating a subset with King County deaths to decedents with permanent homes](#decedents-with-homes---creating-a-subset-with-king-county-deaths-to-decedents-with-permanent-homes)
        -   [4. Appending homeless and with home data sets](#appending-homeless-and-with-home-data-sets)
    -   [B. Washington State mortality data - pre-processing](#b.-washington-state-mortality-data---pre-processing)
        -   [1. Cleaning and standardizing WAMD annual data 2003-2017](#cleaning-and-standardizing-wamd-annual-data-2003-2017)
        -   [2. Deriving new features in preparation for exploratory data analysis](#deriving-new-features-in-preparation-for-exploratory-data-analysis)
        -   [3. Creating a data set of decedents who had permanent homes at time of death](#creating-a-data-set-of-decedents-who-had-permanent-homes-at-time-of-death)
    -   [C. King County Medical Examiner\`s Homeless Death Registry data - November 2003 to September 2017](#c.-king-county-medical-examiners-homeless-death-registry-data---november-2003-to-september-2017)
        -   [1. Cleaning KCMEO homeless registry](#cleaning-kcmeo-homeless-registry)
        -   [3. Creating combined dataset for exploratory data analysis](#creating-combined-dataset-for-exploratory-data-analysis)

``` r
library(magrittr)
library(tidyverse)
library(stringr)
library(knitr)
library(naniar)
library(data.table)
library(lubridate)
library(stringr)
library(scales)
library(cowplot)
library(quanteda)
library(tm)
library(tinytex)

knitr::opts_chunk$set(message = FALSE, error=FALSE, warning = FALSE, echo = TRUE, tidy = TRUE, fig.width = 9, fig.align = "center")
```

I. Overview
===========

The purpose of this project is twofold: (1) to conduct exploratory analysis comparing death data for known homeless decedents with data for those with permanent homes at the time of death, and (2) to use the findings to train a machine learning model to classify unlabeled deaths in Washington State by homeless status.

Currently, there is no consistent and definitive way to identify homelessness among decedents (such as a checkbox on the death certificate). Understanding the differences in demographics (gender, race/ethnicity, age group etc.) and causes of death between decedents who were homeless and those with permanent homes will validate our current understanding of the differences between these populations and provide direction for addressing the health needs of homeless individuals.

The data sets used for this project include Washington State final annual death certificate data for 2003-2017 and the King County Medical Examiner Office\`s registry of deaths among homeless individuals who died in King County, Washington. This registry contains name, birth date, death date, and place of death for homeless individuals who died between 2003 through late 2017. However, the registry does not contain important attributes that will be necessary for exploratory data analysis and for machine learning. These additional attributes are available in the death certificate information for each of the decedents listed in the homeless death registry requiring a linkage of the registry and the death certificate data to have a complete data set.

II. Data pre-processing
=======================

A. Overview
-----------

The following diagram provides an overview of the data pre-processing steps in preparation for exploratory data analysis and machine learning.

<img src="Data preprocessing schematic2.png" width="1700" style="display: block; margin: auto;" />

### 1. Data cleaning and standardization

This step includes:

1.  Limiting Washington annual mortality data sets (WAMD) for 2003 through 2017 to attributes that are likely to be relevant to training the machine learning model e.g. removing administrative variables (such as date of death certificate filing, amendments to death certificate), name and relationship to decedent of person who reported the death etc.

2.  Standardizing attribute names and formats by renaming attributes and coercing data types in both WAMD and King County Homeless Death Registry (HDR) data. Due to changes in data collection practices for WAMD over the years, attribute names and formats are inconsistent.

3.  Limiting records in WAMD to decedents who were Washington State residents who died in Washington State.

4.  Deriving new features that group the records by age group, leading causes of death etc. to allow exploratory data analysis and comparison with the homeless death data.

### 2. Homeless decedents - linking homeless death data to their death certificates

This step will add the additional attributes from WAMD to each of the records in HDR so that they have the necessary attributes to train the model. In its raw form, HDR contains very limited information about the homeless individuals who died including their names, dates of birth, dates of death, and places (address) of death.

Due to the incomplete nature of HDR data the linkage will be performed in multiple iterations using different combinations of key variables to arrive at linked homeless-death certificate data sets that will then be merged. The key variables used are as follows: -iteration 1: last name, first name, date of birth -iteration 2 (starting with only unmatched records from iteration 1): social security number -iteration 3 (starting with only unmatched records from iteration 2): date of death, last name, first name -iteration 4 (starting with only unmatched records from iteration 3): date of death, date of birth, last name

### 3. Decedents with homes - creating a subset with King County deaths to decedents with permanent homes

In this step the Washington annual mortality data set (2003-17 combined) is restricted to deaths occurring in King County with a residential geocode match score of at least 95% i.e. with a 95% or greater degree of certainty that the residential address provided on the death certificate matches a street address validated by the Census Bureau.

### 4. Appending homeless and with home data sets

The final data preparation step involves appending the homeless and "with home" data sets with standardized features and feature names to allow exploratory data analysis and training a machine learning model.

B. Washington State mortality data - pre-processing
---------------------------------------------------

Washington State requires by law that all deaths occurring in the state must be registered with the Washington State Department of Health. This means we have almost 100% reporting of deaths occurring in the state (with the exception of occasional missing persons).

The size of each annual file has increased over the years, both in terms of number of records and in terms of attributes. Attribute names and data types have not been consistent over the years. By 2017 Washington State's death data set included over 58,000 unique observations (death certificate records) and over 250 attributes. Most of the attributes are not relevant to train the machine learning model for this project.

This section addresses cleaning and limiting the data sets (in terms of number of attributes).

### 1. Cleaning and standardizing WAMD annual data 2003-2017

I created the dataset by connecting my R session to WA Department of Health's vital statistics SQL data base, selecting relevant features (variables), and renaming them for ease of use. The resulting data set consists of the following features:

last name, first name, middle name, social security number, death certificate number, date of death, date of birth, sex,type of death certifier (physician, Medical examiner, coroner etc), manner of death, cause of death (ICD 10 codes), residence street address, residence city, residence zipcode, residence state, residence county, death county, death zipcode, death state, type of place where death occurred (hospital, home, hospice etc), educational attainment, marital status, race, ethnicity, occupation code, and military service.

A description of these features and their values is provided in the data dictionary found in Appendix A.

``` r
library(RODBC)

wls <- odbcDriverConnect(connection = "Driver={ODBC Driver 13 for SQL Server};server=DOH01DBTUMP10,9799;
                            database=WA_DB_DQSS;trusted_connection=yes;")

WA0317 <- sqlQuery(wls, "SELECT SFN_NUM as 'certno', 
\tDOB as 'dob',
\tDOD as 'dod',
\tLNAME as 'lname',
\tGNAME as 'fname',
\tMNAME as 'mname',
\tSEX as 'sex',
\tSSN as 'ssn', 
\tCERT_DESIG as 'attclass',
\tRACE_NCHS_CD as 'brgrace',
\tDETHNIC_NO as 'hispanic',
\tMANNER as 'manner',
\tRES_COUNTY as 'rcounty',
\tRES_CITY as 'rcity', 
\tRES_ADDR1 as 'rstreet',  
\tRES_MATCH_CODE as 'resmatchcode', 
\tRES_STATE_FIPS_CD as 'rstateFIPS', 
\tRES_ZIP as 'rzip',
\tDADDR1 as 'dstreet', 
\t--DNAME_FIPS_CD as 'dcityFIPS',
\tDNAME_CITY as 'dcity',
\tDZIP9 as 'dzip',
\tDCOUNTY as 'dcounty', 
\tDSTATEL_FIPS_CD as 'dstateFIPS',
\tDPLACEL as 'dplacelit',
\tDPLACE as 'dplacecode', 
\tDATE_DEATH_YEAR as'dthyr',
\t--ME_CASE_NUM as 'MEcasenum', 
\tTRX_CAUSE_ACME as 'UCOD', 
\tTRX_REC_AXIS_CD as 'MCOD', 
\tDEDUC as 'educ', 
\tMARITAL as 'marital', 
\tOCCUP_MILHAM as 'occup',
\tARMED as 'military',
CODIA_QUERY+ ' ' + ISNULL(CODIB_QUERY, '') + ' ' + ISNULL(CODIC_QUERY, '') + ' ' + ISNULL(CODID_QUERY, '') + ' ' + ISNULL(CONDII_QUERY, '') + ' ' + ISNULL(INJRY_L_QUERY, '') as 'codlit'

                   FROM [wa_vrvweb_events].[VRV_DEATH_TBL]
                   WHERE SFN_NUM BETWEEN '2003000001' AND '2017089999'
                   AND FL_VOIDED = '0'
                   AND FL_CURRENT = '1'
                   AND VRV_REGISTERED_FLAG = '1'")

odbcClose(wls)


WA0317 <- subset(WA0317, dstateFIPS == "WA")
str(WA0317)
```

    ## 'data.frame':    745941 obs. of  33 variables:
    ##  $ certno      : int  2017012363 2017019356 2017019357 2017019358 2017019359 2017026057 2017019361 2017019363 2017019367 2017019368 ...
    ##  $ dob         : Factor w/ 39167 levels "01/01/1900","01/01/1902",..: 11211 13118 38661 28345 29099 23295 3684 21388 490 3463 ...
    ##  $ dod         : Factor w/ 5480 levels "00/00/2016","01/01/2003",..: 935 1715 1715 1700 1700 2360 1640 1700 1745 1745 ...
    ##  $ lname       : Factor w/ 123176 levels "A'ALONA-MOUNTS",..: 113287 15001 6225 51473 107797 45435 15457 36512 37315 69673 ...
    ##  $ fname       : Factor w/ 38248 levels "'NONE'","'O",..: 33095 9031 31798 36829 34006 16346 29848 29741 8393 9306 ...
    ##  $ mname       : Factor w/ 46681 levels "-","--","---",..: 7844 NA 12394 24147 NA 14621 28104 17257 12869 21797 ...
    ##  $ sex         : Factor w/ 3 levels "F","M","U": 1 2 1 2 1 1 1 2 1 2 ...
    ##  $ ssn         : Factor w/ 744515 levels "000-00-0005",..: 516050 53912 580348 686099 18834 77731 149648 111489 564044 92640 ...
    ##  $ attclass    : int  7 1 1 2 1 1 1 2 1 1 ...
    ##  $ brgrace     : int  1 1 1 1 1 1 1 1 1 1 ...
    ##  $ hispanic    : Factor w/ 2 levels "N","Y": 2 2 2 2 2 2 2 2 2 2 ...
    ##  $ manner      : Factor w/ 6 levels "A","C","H","N",..: 4 4 4 1 4 4 4 4 4 4 ...
    ##  $ rcounty     : Factor w/ 1110 levels "-","ACADIA","ADA",..: 497 547 547 908 762 198 497 454 179 199 ...
    ##  $ rcity       : Factor w/ 3849 levels "4600 WELS","69006 LYON",..: 418 565 539 2060 1222 3082 1674 1825 2026 3551 ...
    ##  $ rstreet     : Factor w/ 565794 levels "- BLDG 3764 C STRYKER AVENUE",..: 58753 10789 273748 96690 17620 444876 224106 417484 171058 495875 ...
    ##  $ resmatchcode: int  100 100 100 100 100 NA 100 100 100 100 ...
    ##  $ rstateFIPS  : Factor w/ 66 levels "AB","AK","AL",..: 61 61 61 61 61 61 61 61 61 61 ...
    ##  $ rzip        : Factor w/ 15555 levels "00000","00077",..: 7661 11656 11579 8784 9437 10089 5680 8652 13121 12785 ...
    ##  $ dstreet     : Factor w/ 266442 levels "-- ENTER OTHER RESIDENCE ADDRESS AT",..: 257571 4823 NA 254061 245790 NA 263976 179609 73342 264019 ...
    ##  $ dcity       : Factor w/ 2614 levels "171 M.3 T.MAE NA RUE A.MUANG",..: 2068 390 376 1374 848 2081 1602 1217 1354 2414 ...
    ##  $ dzip        : Factor w/ 4998 levels "00000","01027",..: 2236 3614 3595 2589 2808 3017 2305 2560 4167 3993 ...
    ##  $ dcounty     : Factor w/ 885 levels "A MUANG","ACADIA",..: 395 434 434 727 595 161 395 361 147 162 ...
    ##  $ dstateFIPS  : Factor w/ 105 levels "53","AF","AK",..: 98 98 98 98 98 98 98 98 98 98 ...
    ##  $ dplacelit   : Factor w/ 21 levels "DEAD ON ARRIVAL TO HOSPITAL IN TRANSPORT",..: 16 16 13 16 16 16 17 3 3 7 ...
    ##  $ dplacecode  : int  5 5 4 5 5 5 1 0 0 7 ...
    ##  $ dthyr       : int  2017 2017 2017 2017 2017 2017 2017 2017 2017 2017 ...
    ##  $ UCOD        : Factor w/ 3133 levels ".","000","0000",..: 1188 1306 1057 1510 1299 1297 1211 1211 417 1290 ...
    ##  $ MCOD        : Factor w/ 351269 levels ".","A020 A090 E86 I251 N170 N179",..: NA NA NA NA NA NA NA NA NA NA ...
    ##  $ educ        : int  4 3 6 6 3 3 4 4 4 1 ...
    ##  $ marital     : Factor w/ 7 levels "A","D","M","P",..: 2 7 7 3 7 7 7 5 3 7 ...
    ##  $ occup       : Factor w/ 430 levels "`","000","007",..: 407 237 137 97 407 165 169 144 186 348 ...
    ##  $ military    : Factor w/ 3 levels "N","U","Y": 1 1 1 3 1 1 1 1 1 3 ...
    ##  $ codlit      : Factor w/ 551455 levels "-- GASTROINTESTINAL BLEEDING-- METASTATIC CHOLANGIOCARCINOMA, PRIMARY SITE IS THE LIVER DUCTS METASTATIC TO THE"| __truncated__,..: 173261 165191 519901 450427 528731 407830 224189 165130 276515 208465 ...

I coerced specific features into factors and dates as they were read in as character strings by R. To prepare for record linkage later I standardized the last and first name fields by removing leading, trailing, and mid-name white spaces, removed all hyphenations. I also removed hyphens from the social security number charcter string. I left social security number as a string to avoid losing leading zeroes.

``` r
# Cleaning WA death data - standardizing values

## COERCE VARIABLES TO DATES

WA0317$dob <- as.Date(WA0317$dob, "%m/%d/%Y")
WA0317$dod <- as.Date(WA0317$dod, "%m/%d/%Y")

## REMOVE WHITESPACE, PUNCTUATION, AND SUFFIXES FROM NAMES AND HYPHENS FROM
## SSN

WA0317$lname <- str_replace_all(WA0317$lname, pattern = " ", replacement = "")
WA0317$lname <- str_replace_all(WA0317$lname, pattern = "-", replacement = "")

WA0317$fname <- str_replace_all(WA0317$fname, pattern = " ", replacement = "")
WA0317$fname <- str_replace_all(WA0317$fname, pattern = "-", replacement = "")

WA0317$ssn <- str_replace_all(WA0317$ssn, pattern = "-", replacement = "")

WA0317$UCOD <- as.character(WA0317$UCOD)

WA0317$UCOD <- ifelse((nchar(WA0317$UCOD)) < 4, paste(WA0317$UCOD, "0", sep = ""), 
    WA0317$UCOD)

WA0317$UCOD <- str_replace_all(string = WA0317$UCOD, pattern = " ", replacement = "")

## COERCE VARIABLES TO FACTOR
facvars_wa <- c("dcounty", "dzip", "dcity", "attclass", "brgrace", "hispanic", 
    "sex", "manner", "rcounty", "rcity", "rstreet", "rstateFIPS", "rzip", "dstateFIPS", 
    "dplacelit", "dplacecode", "sex", "dthyr", "marital", "UCOD", "educ", "MCOD", 
    "occup", "military")

WA0317 %<>% mutate_at(facvars_wa, funs(factor(.)))

# convert character to numeric

WA0317$resmatchcode <- as.numeric(WA0317$resmatchcode)

summary(WA0317)
```

    ##      certno               dob                  dod            
    ##  Min.   :2.003e+09   Min.   :1893-05-27   Min.   :2003-01-01  
    ##  1st Qu.:2.007e+09   1st Qu.:1923-01-23   1st Qu.:2007-01-23  
    ##  Median :2.010e+09   Median :1932-05-26   Median :2010-12-07  
    ##  Mean   :2.010e+09   Mean   :1936-08-15   Mean   :2010-10-14  
    ##  3rd Qu.:2.014e+09   3rd Qu.:1947-01-16   3rd Qu.:2014-08-13  
    ##  Max.   :2.017e+09   Max.   :2017-12-31   Max.   :2017-12-31  
    ##                      NA's   :74                               
    ##     lname              fname               mname        sex       
    ##  Length:745941      Length:745941      LEE    : 17386   F:369858  
    ##  Class :character   Class :character   ANN    : 16544   M:376074  
    ##  Mode  :character   Mode  :character   MARIE  : 16416   U:     9  
    ##                                        JEAN   : 10791             
    ##                                        M      : 10107             
    ##                                        (Other):610339             
    ##                                        NA's   : 64358             
    ##      ssn               attclass         brgrace       hispanic  
    ##  Length:745941      1      :555602   1      :628492   N: 65318  
    ##  Class :character   2      :107584   2      : 18751   Y:680623  
    ##  Mode  :character   7      : 42333   15     : 10363             
    ##                     3      : 30181   3      :  9900             
    ##                     6      :  8862   6      :  4928             
    ##                     (Other):    43   (Other): 27283             
    ##                     NA's   :  1336   NA's   : 46224             
    ##   manner            rcounty             rcity       
    ##  A   : 42454   KING     :178725   SEATTLE  : 64245  
    ##  C   :  2826   PIERCE   : 87204   SPOKANE  : 36951  
    ##  H   :  3605   SNOHOMISH: 69007   TACOMA   : 35351  
    ##  N   :682229   SPOKANE  : 59687   VANCOUVER: 30909  
    ##  P   :    56   CLARK    : 40876   EVERETT  : 16875  
    ##  S   : 14674   (Other)  :309646   (Other)  :561413  
    ##  NA's:    97   NA's     :   796   NA's     :   197  
    ##                    rstreet        resmatchcode      rstateFIPS    
    ##  UNKNOWN               :  1759   Min.   :  0.00   WA     :727569  
    ##  7500 SEWARD PARK AVE S:   608   1st Qu.:100.00   OR     :  6428  
    ##  4831 35TH AVE SW      :   596   Median :100.00   ID     :  3251  
    ##  534 BOYER AVE         :   568   Mean   : 94.57   CA     :  1520  
    ##  13023 GREENWOOD AVE N :   545   3rd Qu.:100.00   AK     :  1213  
    ##  (Other)               :741825   Max.   :100.00   (Other):  5959  
    ##  NA's                  :    40   NA's   :47628    NA's   :     1  
    ##       rzip                                       dstreet      
    ##  98632  :  8356   FRANCISCAN HOSPICE HOUSE           :  5246  
    ##  98133  :  7166   COTTAGE IN THE MEADOW              :  1760  
    ##  98902  :  6808   TRI-CITIES CHAPLAINCY HOSPICE HOUSE:  1212  
    ##  99208  :  6420   12822 124TH LANE NE                :  1072  
    ##  98382  :  6354   HOSPICE OF SPOKANE HOSPICE HOUSE   :   961  
    ##  (Other):710600   (Other)                            :339321  
    ##  NA's   :   237   NA's                               :396369  
    ##        dcity             dzip             dcounty       dstateFIPS 
    ##  SEATTLE  : 91224   98201  : 16625   KING     :200694   WA:745941  
    ##  SPOKANE  : 53197   98405  : 15479   PIERCE   : 90133              
    ##  TACOMA   : 38773   98122  : 13600   SPOKANE  : 67646              
    ##  VANCOUVER: 37582   98506  : 12579   SNOHOMISH: 64035              
    ##  EVERETT  : 25553   99204  : 12567   CLARK    : 43746              
    ##  (Other)  :499518   (Other):629042   (Other)  :279683              
    ##  NA's     :    94   NA's   : 46049   NA's     :     4              
    ##                        dplacelit        dplacecode         dthyr       
    ##  Home                       :220536   0      :237123   2017   : 56986  
    ##  Hospital (inpatient)       :204310   4      :218105   2016   : 54784  
    ##  Nursing home/long term care:165922   5      :187867   2015   : 54651  
    ##  Hospice                    : 36101   7      : 39535   2014   : 52074  
    ##  Other place                : 34454   1      : 37527   2013   : 51261  
    ##  Emergency room             : 22323   3      : 23853   2012   : 50161  
    ##  (Other)                    : 62295   (Other):  1931   (Other):426024  
    ##       UCOD               MCOD             educ        marital   
    ##  C349   : 46385   C349 F179: 12914   3      :275429   A:  2408  
    ##  I251   : 44322   G309     : 10676   4      :120355   D:125504  
    ##  G309   : 43577   C349     :  6624   6      : 83031   M:279435  
    ##  I219   : 32710   C259     :  5855   2      : 65278   P:   877  
    ##  J449   : 30481   C509     :  5679   1      : 60747   S: 75572  
    ##  (Other):548195   (Other)  :653617   9      : 51414   U:  4138  
    ##  NA's   :   271   NA's     : 50576   (Other): 89687   W:258007  
    ##      occup        military                             codlit      
    ##  908    :126897   N:529290   LUNG CANCER                  :  5731  
    ##  183    : 19104   U:  4263   PANCREATIC CANCER            :  3184  
    ##  290    : 15837   Y:212388   ALZHEIMERS DEMENTIA          :  2833  
    ##  150    : 13582              METASTATIC BREAST CANCER     :  2743  
    ##  396    : 13464              METASTATIC LUNG CANCER       :  2380  
    ##  (Other):542052              (Other)                      :728925  
    ##  NA's   : 15005              NA's                         :   145

``` r
str(WA0317)
```

    ## 'data.frame':    745941 obs. of  33 variables:
    ##  $ certno      : int  2017012363 2017019356 2017019357 2017019358 2017019359 2017026057 2017019361 2017019363 2017019367 2017019368 ...
    ##  $ dob         : Date, format: "1945-04-15" "1918-05-03" ...
    ##  $ dod         : Date, format: "2017-03-03" "2017-04-24" ...
    ##  $ lname       : chr  "VANRY" "BYERS" "BASKIN" "JOHNSON" ...
    ##  $ fname       : chr  "SYLVIA" "DOUGLAS" "SHIRLEY" "WILLARD" ...
    ##  $ mname       : Factor w/ 46681 levels "-","--","---",..: 7844 NA 12394 24147 NA 14621 28104 17257 12869 21797 ...
    ##  $ sex         : Factor w/ 3 levels "F","M","U": 1 2 1 2 1 1 1 2 1 2 ...
    ##  $ ssn         : chr  "537446055" "258429171" "539181252" "559307744" ...
    ##  $ attclass    : Factor w/ 10 levels "0","1","2","3",..: 8 2 2 3 2 2 2 3 2 2 ...
    ##  $ brgrace     : Factor w/ 20 levels "1","2","3","4",..: 1 1 1 1 1 1 1 1 1 1 ...
    ##  $ hispanic    : Factor w/ 2 levels "N","Y": 2 2 2 2 2 2 2 2 2 2 ...
    ##  $ manner      : Factor w/ 6 levels "A","C","H","N",..: 4 4 4 1 4 4 4 4 4 4 ...
    ##  $ rcounty     : Factor w/ 1097 levels "ACADIA","ADA",..: 491 541 541 898 754 195 491 449 176 196 ...
    ##  $ rcity       : Factor w/ 3819 levels "4600 WELS","69006 LYON",..: 415 560 534 2045 1211 3059 1663 1812 2011 3522 ...
    ##  $ rstreet     : Factor w/ 555080 levels "#1 5TH AND MAIN ST.",..: 57600 10570 268421 94779 17238 436378 219748 409454 167666 486465 ...
    ##  $ resmatchcode: num  100 100 100 100 100 NA 100 100 100 100 ...
    ##  $ rstateFIPS  : Factor w/ 66 levels "AB","AK","AL",..: 61 61 61 61 61 61 61 61 61 61 ...
    ##  $ rzip        : Factor w/ 15491 levels "00000","00077",..: 7625 11606 11529 8744 9396 10046 5651 8612 13065 12733 ...
    ##  $ dstreet     : Factor w/ 266442 levels "-- ENTER OTHER RESIDENCE ADDRESS AT",..: 257571 4823 NA 254061 245790 NA 263976 179609 73342 264019 ...
    ##  $ dcity       : Factor w/ 747 levels "ABERDEEN","ACME",..: 595 102 100 404 244 600 467 356 395 695 ...
    ##  $ dzip        : Factor w/ 3809 levels "00000","03282",..: 1086 2463 2444 1438 1657 1866 1155 1409 3016 2842 ...
    ##  $ dcounty     : Factor w/ 40 levels "ADAMS","ASOTIN",..: 17 21 21 32 27 5 17 15 4 6 ...
    ##  $ dstateFIPS  : Factor w/ 1 level "WA": 1 1 1 1 1 1 1 1 1 1 ...
    ##  $ dplacelit   : Factor w/ 21 levels "DEAD ON ARRIVAL TO HOSPITAL IN TRANSPORT",..: 16 16 13 16 16 16 17 3 3 7 ...
    ##  $ dplacecode  : Factor w/ 10 levels "0","1","2","3",..: 6 6 5 6 6 6 2 1 1 8 ...
    ##  $ dthyr       : Factor w/ 15 levels "2003","2004",..: 15 15 15 15 15 15 15 15 15 15 ...
    ##  $ UCOD        : Factor w/ 3086 levels "A020","A021",..: 1178 1296 1049 1500 1289 1287 1201 1201 412 1280 ...
    ##  $ MCOD        : Factor w/ 345266 levels "A020 A090 E86 I251 N170 N179",..: NA NA NA NA NA NA NA NA NA NA ...
    ##  $ educ        : Factor w/ 9 levels "1","2","3","4",..: 4 3 6 6 3 3 4 4 4 1 ...
    ##  $ marital     : Factor w/ 7 levels "A","D","M","P",..: 2 7 7 3 7 7 7 5 3 7 ...
    ##  $ occup       : Factor w/ 430 levels "`","000","007",..: 407 237 137 97 407 165 169 144 186 348 ...
    ##  $ military    : Factor w/ 3 levels "N","U","Y": 1 1 1 3 1 1 1 1 1 3 ...
    ##  $ codlit      : Factor w/ 551455 levels "-- GASTROINTESTINAL BLEEDING-- METASTATIC CHOLANGIOCARCINOMA, PRIMARY SITE IS THE LIVER DUCTS METASTATIC TO THE"| __truncated__,..: 173261 165191 519901 450427 528731 407830 224189 165130 276515 208465 ...

The summary of the features shown above indicates that some have missing values e.g. "brgrace" (calculated race variable), "rstreet" (residential street address), "MCOD" (multiple cause of death). Some of these variables routinely have missing values for acceptable reasons, for example not all deaths have multiple causes of death as these are optional fields and the health care provider completing the death certificate may only report a single underlying cause of death. Race is also a feature that routinely has substantial proportion of records with missing values as funeral homes (which typically report demographic information for decedents) may not be able to obtain this information. Further in the data processing when the data set is limited to deaths occurring in King County, WA, fewer variables have large numbers of missing variables and, where they exist, they are not necessary for linkage with the list of homeless decedents.

### 2. Deriving new features in preparation for exploratory data analysis

I created a few derived variables including calculated age (at time of death), 5-category age group, leading causes of death categories (by grouping codes in the "UCOD" feature which contains International Classification of Disease, 10th edition, codes indicating the underlying cause of death), race/ethnicity (applying U.S. Office of Management and Budget and Washington State Department of Health guidelines), resident status (Washington state vs. out of state resident), unintentional injury cause of death groups, and substance abuse related cause of death groups.

These added features will useful in conducting exploratory data analysis including comparing the characteristics of homeless decedents with those of decedents who had a permanent home at death.

``` r
# Creating derived variables in WA death dataset

## CALCULATED AGE AT DEATH

WA0317$age <- year(WA0317$dod) - year(WA0317$dob)

attach(WA0317)

# AGE CATEGORIES

WA0317$age5cat[age < 18] <- "<18yrs"
WA0317$age5cat[age >= 18 & age <= 29] <- "18-29yrs"
WA0317$age5cat[age >= 30 & age <= 44] <- "30-44yrs"
WA0317$age5cat[age >= 45 & age <= 64] <- "45-64yrs"
WA0317$age5cat[age >= 65] <- "65+ yrs"

# LEADING CAUSES OF DEATH (per National Center for Health Statistics)

WA0317$LCOD <- "Other"

## MALIGNANT NEOPLASMS - C00-C97
MalignantNeoplasms <- "C[0-9][0-7][0-9]?"
WA0317$LCOD[grepl(MalignantNeoplasms, WA0317$UCOD)] <- "Cancer"

## DISEASES OF THE HEART - I00-I09,I11,I13,I20-I51
HeartDisease <- "I0[0-9][0-9]?|I11[0-9]?|I13[0-9]?|I[2-4][0-9][0-9]?|I50[0-9]?|I51[0-9]?"
WA0317$LCOD[grepl(HeartDisease, WA0317$UCOD)] <- "Heart Dis."

## ALZHEIMER'S DISEASE - G30
Alzheimers <- "G30[0-9]?"
WA0317$LCOD[grepl("G30", WA0317$UCOD)] <- "Alzheimers"

## ACCIDENTS - V01-X59,Y85-Y86
unintentionalinjury <- "V[0-9][0-9][0-9]?|W[0-9][0-9][0-9]?|X[0-5][0-9][0-9]?|Y8[5-6][0-9]?"
WA0317$LCOD[grepl(unintentionalinjury, WA0317$UCOD)] <- "Injury-unintentional"

## CHRONIC LOWER RESPIRATORY DISEASE - J40-J47
CLRD <- "J4[0-7][0-9]?"
WA0317$LCOD[grepl(CLRD, WA0317$UCOD)] <- "Chronic Lwr Resp Dis."

## CEREBROVASCULAR DISEASE - I60-69
CVD <- "I6[0-9][0-9]?"
WA0317$LCOD[grepl(CVD, WA0317$UCOD)] <- "Stroke"

## DIABETES MELLITUS - E10-E14
diabetes <- "E1[0-4][0-9]?"
WA0317$LCOD[grepl(diabetes, WA0317$UCOD)] <- "Diabetes"

# SUICIDE
allsuicides <- "U03[0-9]?|X[6-7][0-9][0-9]?|X8[0-4][0-9?]|Y870"
WA0317$LCOD[grepl(allsuicides, WA0317$UCOD)] <- "Suicide-all"

## CHRONIC LIVER DISEASE AND CIRRHOSIS - K70,K73-K74
liver <- "K70[0-9]?|K7[3-4][0-9]?"
WA0317$LCOD[grepl(liver, WA0317$UCOD)] <- "Chronic Liver dis./cirrh."

## INFLUENZA AND PNEUMONIA - J09-J18
flu <- "J09[0-9]?|J1[0-8][0-9]?"
WA0317$LCOD[grepl(flu, WA0317$UCOD)] <- "Flu"


### UNINTENTIONAL INJURIES - SELECT SUBCATEGORIES OF: V01-X59,Y85-Y86

WA0317$injury <- "No injury"

# Unintentional Poisoning - X40-49
poisoninjury <- "^X4[0-9][0-9]?"
WA0317$injury[grepl(poisoninjury, WA0317$UCOD)] <- "Unintentional poisoning"

# Unintentional Firearm - W32-34 guninjury <- 'W3[2-4][0-9]?'
# WA0317$injury[grepl(guninjury, WA0317$UCOD)] <- 'Unintentional firearm'

# Motor vehicle - pedestrian - (V01-V99, X82, Y03, Y32, Y36.1, *U01.1 )
mvall <- "V[0-9][1-9][0-9]?|X82[0-9]?|Y03[0-9]?|Y32[0-9]?|Y361|U011"
WA0317$injury[grepl(mvall, WA0317$UCOD)] <- "MV - all"

# Motor vehicle - pedestrian - (V02–V04[.1,.9],V09.2) mvped <-
# 'V021|V029|V031|V039|V041|V049|V092' WA0317$injury[grepl(mvped,
# WA0317$UCOD)] <- 'MV crash-pedestrian'

# Motor Vehicle - bicycle - V12-V14 (.3-.9) , V19 (.4-.6) mvbike <-
# 'V1[2-4][3-9]?|V19[4-6]?' WA0317$injury[grepl(mvbike, WA0317$UCOD)] <- 'MV
# crash-bicyclist'

# Unintentional Fall (W00–W19)
fall <- "W0[0-9][0-9]|W1[0-9][0-9]"
WA0317$injury[grepl(fall, WA0317$UCOD)] <- "Unintentional fall"

# Other injury
WA0317$injury[grepl(unintentionalinjury, WA0317$UCOD) & !grepl(poisoninjury, 
    WA0317$UCOD) & !grepl(mvall, WA0317$UCOD) & !grepl(fall, WA0317$UCOD)] <- "Other injury"



# SUBSTANCE ABUSE
WA0317$substance <- "No Substance abuse"

# Alcohol-induced per NCHS -
# https://www.cdc.gov/nchs/data/nvsr/nvsr66/nvsr66_06.pdf excludes
# unintentional injuries, homicides, other causes indirectly related to
# alcohol use, newborn deaths due to maternal alcohol use.

alcohol <- "E244|F10[0-9]?|G312|G621|G721|I426|K292|K70[0-9]?|K852|K860|R780|X45[0-9]?|
            X65[0-9]?|Y15[0-9]?"
WA0317$substance[grepl(alcohol, WA0317$UCOD)] <- "Alcohol-induced"


# Drug-induced per NCHS -
# https://www.cdc.gov/nchs/data/nvsr/nvsr66/nvsr66_06.pdf Excludes
# unintentional injuries, homicides, other causes indirectly related to drug
# use, newborn deaths due to maternal drug use

drug <- "D521|D590|D592|D611|D642|E064|E160|E231|E242|E273|E661|F11[1–5]|F11[7–9]|F12[1-5]|
F12[7–9]|F13[1–5]|F13[7-9]|F14[1–5]|F14[7–9]|F15[1–5]|F15[7–9]|F16[1–5]|F16[7–9]|F17[3–5]|
F17[7–9]|F18[1–5]|F18[7–9]|F19[1–5]|F19[7–9]|G211|G240|G251|G254|G256|G444|G620|G720|I952|
J702|J703|J704|K853|L105|L270|L271|M102|M320|M804|M814|M835|M871|R502|R781|R782|R783|R784|
R785|X4[0-4][0-9]|X6[0–4][0-9]|X85|Y1[0–4][0-9]"

WA0317$substance[grepl(drug, WA0317$UCOD)] <- "Drug-induced"

## RESIDENCE

WA0317$residence[rstateFIPS != "WA" & rstateFIPS != "ZZ"] <- "Out of state"
WA0317$residence[rstateFIPS == "WA"] <- "WA resident"

## RACE AND ETHNICITY remember that the original ethnicity variable was named
## 'HISPANICNO' (renamed 'hispanic' in this data set) i.e. a 'yes' means they
## are NOT hispanic

## 5 groups with Hispanic as race
WA0317$raceethnic5 <- "Other"
WA0317$raceethnic5[brgrace %in% c("01", "1") & hispanic == "Y"] <- "White NH"
WA0317$raceethnic5[brgrace %in% c("02", "2") & hispanic == "Y"] <- "Black NH"
WA0317$raceethnic5[brgrace %in% c("03", "3") & hispanic == "Y"] <- "AIAN NH"
WA0317$raceethnic5[brgrace %in% c("04", "4", "05", "5", "06", "6", "07", "7", 
    "08", "8", "09", "9", "10", "11", "12", "13", "14", "15") & hispanic == 
    "Y"] <- "Asian/PI NH"
WA0317$raceethnic5[hispanic == "N"] <- "Hispanic"
WA0317$raceethnic5[is.na(brgrace)] <- "Unknown"


## 6 groups with Hispanic as race and separating Asians and NHOPI
WA0317$raceethnic6 <- "Other"
WA0317$raceethnic6[brgrace %in% c("01", "1") & hispanic == "Y"] <- "White NH"
WA0317$raceethnic6[brgrace %in% c("02", "2") & hispanic == "Y"] <- "Black NH"
WA0317$raceethnic6[brgrace %in% c("03", "3") & hispanic == "Y"] <- "AIAN NH"
WA0317$raceethnic6[brgrace %in% c("04", "4", "05", "5", "06", "6", "07", "7", 
    "08", "8", "09", "9", "10") & hispanic == "Y"] <- "Asian"
WA0317$raceethnic6[brgrace %in% c("11", "12", "13", "14", "15") & hispanic == 
    "Y"] <- "NHOPI"
WA0317$raceethnic6[hispanic == "N"] <- "Hispanic"
WA0317$raceethnic6[is.na(brgrace)] <- "Unknown"


WA0317 %<>% mutate_at(c("age5cat", "residence", "LCOD", "injury", "substance", 
    "raceethnic5", "raceethnic6"), funs(factor(.)))

## Labeling manner of death

WA0317$manner <- factor(WA0317$manner, levels = c("A", "C", "H", "N", "NULL", 
    "P", "S"), labels = c("Accident", "Undetermined", "Homicide", "Natural", 
    "Unk.", "Pending", "Suicide"))

## Labeling educational attainment

WA0317$educ <- factor(WA0317$educ, levels = c("1", "2", "3", "4", "5", "6", 
    "7", "8", "9"), labels = c("<=8th grade", "9-12th gr., no diploma", "H.S. grad/GED", 
    "Some college", "Associate's", "Bachelors", "Masters", "Doctorate/Professional", 
    "Unknown"))

detach(WA0317)
str(WA0317)
```

    ## 'data.frame':    745941 obs. of  41 variables:
    ##  $ certno      : int  2017012363 2017019356 2017019357 2017019358 2017019359 2017026057 2017019361 2017019363 2017019367 2017019368 ...
    ##  $ dob         : Date, format: "1945-04-15" "1918-05-03" ...
    ##  $ dod         : Date, format: "2017-03-03" "2017-04-24" ...
    ##  $ lname       : chr  "VANRY" "BYERS" "BASKIN" "JOHNSON" ...
    ##  $ fname       : chr  "SYLVIA" "DOUGLAS" "SHIRLEY" "WILLARD" ...
    ##  $ mname       : Factor w/ 46681 levels "-","--","---",..: 7844 NA 12394 24147 NA 14621 28104 17257 12869 21797 ...
    ##  $ sex         : Factor w/ 3 levels "F","M","U": 1 2 1 2 1 1 1 2 1 2 ...
    ##  $ ssn         : chr  "537446055" "258429171" "539181252" "559307744" ...
    ##  $ attclass    : Factor w/ 10 levels "0","1","2","3",..: 8 2 2 3 2 2 2 3 2 2 ...
    ##  $ brgrace     : Factor w/ 20 levels "1","2","3","4",..: 1 1 1 1 1 1 1 1 1 1 ...
    ##  $ hispanic    : Factor w/ 2 levels "N","Y": 2 2 2 2 2 2 2 2 2 2 ...
    ##  $ manner      : Factor w/ 7 levels "Accident","Undetermined",..: 4 4 4 1 4 4 4 4 4 4 ...
    ##  $ rcounty     : Factor w/ 1097 levels "ACADIA","ADA",..: 491 541 541 898 754 195 491 449 176 196 ...
    ##  $ rcity       : Factor w/ 3819 levels "4600 WELS","69006 LYON",..: 415 560 534 2045 1211 3059 1663 1812 2011 3522 ...
    ##  $ rstreet     : Factor w/ 555080 levels "#1 5TH AND MAIN ST.",..: 57600 10570 268421 94779 17238 436378 219748 409454 167666 486465 ...
    ##  $ resmatchcode: num  100 100 100 100 100 NA 100 100 100 100 ...
    ##  $ rstateFIPS  : Factor w/ 66 levels "AB","AK","AL",..: 61 61 61 61 61 61 61 61 61 61 ...
    ##  $ rzip        : Factor w/ 15491 levels "00000","00077",..: 7625 11606 11529 8744 9396 10046 5651 8612 13065 12733 ...
    ##  $ dstreet     : Factor w/ 266442 levels "-- ENTER OTHER RESIDENCE ADDRESS AT",..: 257571 4823 NA 254061 245790 NA 263976 179609 73342 264019 ...
    ##  $ dcity       : Factor w/ 747 levels "ABERDEEN","ACME",..: 595 102 100 404 244 600 467 356 395 695 ...
    ##  $ dzip        : Factor w/ 3809 levels "00000","03282",..: 1086 2463 2444 1438 1657 1866 1155 1409 3016 2842 ...
    ##  $ dcounty     : Factor w/ 40 levels "ADAMS","ASOTIN",..: 17 21 21 32 27 5 17 15 4 6 ...
    ##  $ dstateFIPS  : Factor w/ 1 level "WA": 1 1 1 1 1 1 1 1 1 1 ...
    ##  $ dplacelit   : Factor w/ 21 levels "DEAD ON ARRIVAL TO HOSPITAL IN TRANSPORT",..: 16 16 13 16 16 16 17 3 3 7 ...
    ##  $ dplacecode  : Factor w/ 10 levels "0","1","2","3",..: 6 6 5 6 6 6 2 1 1 8 ...
    ##  $ dthyr       : Factor w/ 15 levels "2003","2004",..: 15 15 15 15 15 15 15 15 15 15 ...
    ##  $ UCOD        : Factor w/ 3086 levels "A020","A021",..: 1178 1296 1049 1500 1289 1287 1201 1201 412 1280 ...
    ##  $ MCOD        : Factor w/ 345266 levels "A020 A090 E86 I251 N170 N179",..: NA NA NA NA NA NA NA NA NA NA ...
    ##  $ educ        : Factor w/ 9 levels "<=8th grade",..: 4 3 6 6 3 3 4 4 4 1 ...
    ##  $ marital     : Factor w/ 7 levels "A","D","M","P",..: 2 7 7 3 7 7 7 5 3 7 ...
    ##  $ occup       : Factor w/ 430 levels "`","000","007",..: 407 237 137 97 407 165 169 144 186 348 ...
    ##  $ military    : Factor w/ 3 levels "N","U","Y": 1 1 1 3 1 1 1 1 1 3 ...
    ##  $ codlit      : Factor w/ 551455 levels "-- GASTROINTESTINAL BLEEDING-- METASTATIC CHOLANGIOCARCINOMA, PRIMARY SITE IS THE LIVER DUCTS METASTATIC TO THE"| __truncated__,..: 173261 165191 519901 450427 528731 407830 224189 165130 276515 208465 ...
    ##  $ age         : num  72 99 91 90 91 89 89 47 64 96 ...
    ##  $ age5cat     : Factor w/ 5 levels "<18yrs","18-29yrs",..: 5 5 5 5 5 5 5 4 4 5 ...
    ##  $ LCOD        : Factor w/ 11 levels "Alzheimers","Cancer",..: 7 7 9 4 7 7 7 7 2 7 ...
    ##  $ injury      : Factor w/ 5 levels "MV - all","No injury",..: 2 2 2 2 2 2 2 2 2 2 ...
    ##  $ substance   : Factor w/ 3 levels "Alcohol-induced",..: 3 3 3 3 3 3 3 3 3 3 ...
    ##  $ residence   : Factor w/ 2 levels "Out of state",..: 2 2 2 2 2 2 2 2 2 2 ...
    ##  $ raceethnic5 : Factor w/ 7 levels "AIAN NH","Asian/PI NH",..: 7 7 7 7 7 7 7 7 7 7 ...
    ##  $ raceethnic6 : Factor w/ 8 levels "AIAN NH","Asian",..: 8 8 8 8 8 8 8 8 8 8 ...

``` r
summary(WA0317)
```

    ##      certno               dob                  dod            
    ##  Min.   :2.003e+09   Min.   :1893-05-27   Min.   :2003-01-01  
    ##  1st Qu.:2.007e+09   1st Qu.:1923-01-23   1st Qu.:2007-01-23  
    ##  Median :2.010e+09   Median :1932-05-26   Median :2010-12-07  
    ##  Mean   :2.010e+09   Mean   :1936-08-15   Mean   :2010-10-14  
    ##  3rd Qu.:2.014e+09   3rd Qu.:1947-01-16   3rd Qu.:2014-08-13  
    ##  Max.   :2.017e+09   Max.   :2017-12-31   Max.   :2017-12-31  
    ##                      NA's   :74                               
    ##     lname              fname               mname        sex       
    ##  Length:745941      Length:745941      LEE    : 17386   F:369858  
    ##  Class :character   Class :character   ANN    : 16544   M:376074  
    ##  Mode  :character   Mode  :character   MARIE  : 16416   U:     9  
    ##                                        JEAN   : 10791             
    ##                                        M      : 10107             
    ##                                        (Other):610339             
    ##                                        NA's   : 64358             
    ##      ssn               attclass         brgrace       hispanic  
    ##  Length:745941      1      :555602   1      :628492   N: 65318  
    ##  Class :character   2      :107584   2      : 18751   Y:680623  
    ##  Mode  :character   7      : 42333   15     : 10363             
    ##                     3      : 30181   3      :  9900             
    ##                     6      :  8862   6      :  4928             
    ##                     (Other):    43   (Other): 27283             
    ##                     NA's   :  1336   NA's   : 46224             
    ##           manner            rcounty             rcity       
    ##  Natural     :682229   KING     :178725   SEATTLE  : 64245  
    ##  Accident    : 42454   PIERCE   : 87204   SPOKANE  : 36951  
    ##  Suicide     : 14674   SNOHOMISH: 69007   TACOMA   : 35351  
    ##  Homicide    :  3605   SPOKANE  : 59687   VANCOUVER: 30909  
    ##  Undetermined:  2826   CLARK    : 40876   EVERETT  : 16875  
    ##  (Other)     :    56   (Other)  :309646   (Other)  :561413  
    ##  NA's        :    97   NA's     :   796   NA's     :   197  
    ##                    rstreet        resmatchcode      rstateFIPS    
    ##  UNKNOWN               :  1759   Min.   :  0.00   WA     :727569  
    ##  7500 SEWARD PARK AVE S:   608   1st Qu.:100.00   OR     :  6428  
    ##  4831 35TH AVE SW      :   596   Median :100.00   ID     :  3251  
    ##  534 BOYER AVE         :   568   Mean   : 94.57   CA     :  1520  
    ##  13023 GREENWOOD AVE N :   545   3rd Qu.:100.00   AK     :  1213  
    ##  (Other)               :741825   Max.   :100.00   (Other):  5959  
    ##  NA's                  :    40   NA's   :47628    NA's   :     1  
    ##       rzip                                       dstreet      
    ##  98632  :  8356   FRANCISCAN HOSPICE HOUSE           :  5246  
    ##  98133  :  7166   COTTAGE IN THE MEADOW              :  1760  
    ##  98902  :  6808   TRI-CITIES CHAPLAINCY HOSPICE HOUSE:  1212  
    ##  99208  :  6420   12822 124TH LANE NE                :  1072  
    ##  98382  :  6354   HOSPICE OF SPOKANE HOSPICE HOUSE   :   961  
    ##  (Other):710600   (Other)                            :339321  
    ##  NA's   :   237   NA's                               :396369  
    ##        dcity             dzip             dcounty       dstateFIPS 
    ##  SEATTLE  : 91224   98201  : 16625   KING     :200694   WA:745941  
    ##  SPOKANE  : 53197   98405  : 15479   PIERCE   : 90133              
    ##  TACOMA   : 38773   98122  : 13600   SPOKANE  : 67646              
    ##  VANCOUVER: 37582   98506  : 12579   SNOHOMISH: 64035              
    ##  EVERETT  : 25553   99204  : 12567   CLARK    : 43746              
    ##  (Other)  :499518   (Other):629042   (Other)  :279683              
    ##  NA's     :    94   NA's   : 46049   NA's     :     4              
    ##                        dplacelit        dplacecode         dthyr       
    ##  Home                       :220536   0      :237123   2017   : 56986  
    ##  Hospital (inpatient)       :204310   4      :218105   2016   : 54784  
    ##  Nursing home/long term care:165922   5      :187867   2015   : 54651  
    ##  Hospice                    : 36101   7      : 39535   2014   : 52074  
    ##  Other place                : 34454   1      : 37527   2013   : 51261  
    ##  Emergency room             : 22323   3      : 23853   2012   : 50161  
    ##  (Other)                    : 62295   (Other):  1931   (Other):426024  
    ##       UCOD               MCOD                            educ       
    ##  C349   : 46385   C349 F179: 12914   H.S. grad/GED         :275429  
    ##  I251   : 44322   G309     : 10676   Some college          :120355  
    ##  G309   : 43577   C349     :  6624   Bachelors             : 83031  
    ##  I219   : 32710   C259     :  5855   9-12th gr., no diploma: 65278  
    ##  J449   : 30481   C509     :  5679   <=8th grade           : 60747  
    ##  (Other):548195   (Other)  :653617   Unknown               : 51414  
    ##  NA's   :   271   NA's     : 50576   (Other)               : 89687  
    ##  marital        occup        military  
    ##  A:  2408   908    :126897   N:529290  
    ##  D:125504   183    : 19104   U:  4263  
    ##  M:279435   290    : 15837   Y:212388  
    ##  P:   877   150    : 13582             
    ##  S: 75572   396    : 13464             
    ##  U:  4138   (Other):542052             
    ##  W:258007   NA's   : 15005             
    ##                            codlit            age             age5cat      
    ##  LUNG CANCER                  :  5731   Min.   :  0.00   <18yrs  :  9978  
    ##  PANCREATIC CANCER            :  3184   1st Qu.: 64.00   18-29yrs: 12483  
    ##  ALZHEIMERS DEMENTIA          :  2833   Median : 79.00   30-44yrs: 25794  
    ##  METASTATIC BREAST CANCER     :  2743   Mean   : 74.17   45-64yrs:138528  
    ##  METASTATIC LUNG CANCER       :  2380   3rd Qu.: 87.00   65+ yrs :559084  
    ##  (Other)                      :728925   Max.   :114.00   NA's    :    74  
    ##  NA's                         :   145   NA's   :74                        
    ##                     LCOD                            injury      
    ##  Other                :187549   MV - all               :  9533  
    ##  Cancer               :162623   No injury              :704740  
    ##  Heart Dis.           :161864   Other injury           :  7293  
    ##  Alzheimers           : 44973   Unintentional fall     : 11884  
    ##  Chronic Lwr Resp Dis.: 43189   Unintentional poisoning: 12491  
    ##  Stroke               : 42143                                   
    ##  (Other)              :103600                                   
    ##               substance             residence           raceethnic5    
    ##  Alcohol-induced   : 12988   Out of state: 17806   AIAN NH    :  9549  
    ##  Drug-induced      : 14198   WA resident :727569   Asian/PI NH: 26014  
    ##  No Substance abuse:718755   NA's        :   566   Black NH   : 18492  
    ##                                                    Hispanic   : 19352  
    ##                                                    Other      :  5513  
    ##                                                    Unknown    : 46224  
    ##                                                    White NH   :620797  
    ##    raceethnic6    
    ##  White NH:620797  
    ##  Unknown : 46224  
    ##  Asian   : 23119  
    ##  Hispanic: 19352  
    ##  Black NH: 18492  
    ##  AIAN NH :  9549  
    ##  (Other) :  8408

### 3. Creating a data set of decedents who had permanent homes at time of death

I started by creating a subset of the Washington State data set that included only King County resident deaths where the decedent had a permanent home. The death data set contains a feature called "Place of Death Type", a factor with the following levels:

    - 0 = Home
    - 1 = Other Place
    - 2 = In Transport
    - 3 = Emergency Room
    - 4 = Hospital (Inpatient) 
    - 5 = Nursing Home/Long Term Care
    - 6 = Hospital
    - 7 = Hospice Facility
    - 8 = Other Person's Residence
    - 9 = Unknown

I defined "permanent home" as decedents whose residence address at time of death could be verified through a geocoding process with 95% or greater accuracy. This criterion will exclude persons with incomplete or missing death addresses e.g. those who died on a street corner where the death certificate might list the death address as "Main street and King Blvd".

Another restriction was to limit the deaths to those occurring in King County regardless of county of residence of the decedent to reduce the chance that county of death affects the characteristics of the death or information reported on the death certificate.

I added the suffix ".k" to the column names to identify easily the source data set for these features. This will be helpful in the next step when I merge homeless registry data with their corresponding death records.

From this set of King County deaths among persons with permanent homes I selected a random sample of 1,200 records to match the size of the homeless death record data set.

``` r
# Creating a subset comprised of deaths in King County among decedents with
# permanent homes

KC0317 <- subset(WA0317, dcounty == "KING")

KC <- KC0317

colnames(KC) <- c("certno.k", "dob.k", "dod.k", "lname.k", "fname.k", "mname.k", 
    "sex.k", "ssn.k", "attclass.k", "brgrace.k", "hispanic.k", "manner.k", "rcounty.k", 
    "rcity.k", "rstreet.k", "resmatchcode.k", "rstateFIPS.k", "rzip.k", "dstreet.k", 
    "dcity.k", "dzip.k", "dcounty.k", "dstateFIPS.k", "dplacelit.k", "dplacecode.k", 
    "dthyr.k", "UCOD.k", "MCOD.k", "educ.k", "marital.k", "occup.k", "military.k", 
    "codlit.k", "age.k", "age5cat.k", "LCOD.k", "injury.k", "substance.k", "residence.k", 
    "raceethnic5.k", "raceethnic6.k")

KC0317_wh <- subset(KC, KC$resmatchcode.k >= 95)
str(KC)
```

    ## 'data.frame':    200694 obs. of  41 variables:
    ##  $ certno.k      : int  2017012363 2017019361 2017025187 2017025188 2017025189 2017025190 2017025192 2017025196 2017025197 2017007506 ...
    ##  $ dob.k         : Date, format: "1945-04-15" "1928-02-04" ...
    ##  $ dod.k         : Date, format: "2017-03-03" "2017-04-19" ...
    ##  $ lname.k       : chr  "VANRY" "CALLERY" "BURNETT" "LEE" ...
    ##  $ fname.k       : chr  "SYLVIA" "ROSALIE" "CHARLES" "DOUGLAS" ...
    ##  $ mname.k       : Factor w/ 46681 levels "-","--","---",..: 7844 28104 43459 21330 NA 37632 1079 34669 44195 35250 ...
    ##  $ sex.k         : Factor w/ 3 levels "F","M","U": 1 1 2 2 1 1 2 1 2 1 ...
    ##  $ ssn.k         : chr  "537446055" "476289831" "527366846" "019488823" ...
    ##  $ attclass.k    : Factor w/ 10 levels "0","1","2","3",..: 8 2 2 8 2 2 2 2 2 3 ...
    ##  $ brgrace.k     : Factor w/ 20 levels "1","2","3","4",..: 1 1 1 1 10 1 1 1 5 1 ...
    ##  $ hispanic.k    : Factor w/ 2 levels "N","Y": 2 2 2 2 2 2 2 2 2 2 ...
    ##  $ manner.k      : Factor w/ 7 levels "Accident","Undetermined",..: 4 4 4 4 4 4 4 4 4 4 ...
    ##  $ rcounty.k     : Factor w/ 1097 levels "ACADIA","ADA",..: 491 491 491 491 898 491 491 491 491 491 ...
    ##  $ rcity.k       : Factor w/ 3819 levels "4600 WELS","69006 LYON",..: 415 1663 3752 2801 1964 244 848 3038 1663 2097 ...
    ##  $ rstreet.k     : Factor w/ 555080 levels "#1 5TH AND MAIN ST.",..: 57600 219748 165576 259794 187796 248195 58903 259487 81121 285252 ...
    ##  $ resmatchcode.k: num  100 100 100 100 100 100 100 100 100 100 ...
    ##  $ rstateFIPS.k  : Factor w/ 66 levels "AB","AK","AL",..: 61 61 61 61 61 61 61 61 61 61 ...
    ##  $ rzip.k        : Factor w/ 15491 levels "00000","00077",..: 7625 5651 6328 6095 5800 4995 7831 7884 5613 5928 ...
    ##  $ dstreet.k     : Factor w/ 266442 levels "-- ENTER OTHER RESIDENCE ADDRESS AT",..: 257571 263976 NA 33444 NA 254624 NA NA 35286 125531 ...
    ##  $ dcity.k       : Factor w/ 747 levels "ABERDEEN","ACME",..: 595 467 326 326 595 42 78 595 319 421 ...
    ##  $ dzip.k        : Factor w/ 3809 levels "00000","03282",..: 1086 1155 509 509 987 309 1079 938 474 558 ...
    ##  $ dcounty.k     : Factor w/ 40 levels "ADAMS","ASOTIN",..: 17 17 17 17 17 17 17 17 17 17 ...
    ##  $ dstateFIPS.k  : Factor w/ 1 level "WA": 1 1 1 1 1 1 1 1 1 1 ...
    ##  $ dplacelit.k   : Factor w/ 21 levels "DEAD ON ARRIVAL TO HOSPITAL IN TRANSPORT",..: 16 17 13 7 13 16 13 13 3 5 ...
    ##  $ dplacecode.k  : Factor w/ 10 levels "0","1","2","3",..: 6 2 5 8 5 6 5 5 1 1 ...
    ##  $ dthyr.k       : Factor w/ 15 levels "2003","2004",..: 15 15 15 15 15 15 15 15 15 15 ...
    ##  $ UCOD.k        : Factor w/ 3086 levels "A020","A021",..: 1178 1201 1529 1325 466 858 301 1321 241 1619 ...
    ##  $ MCOD.k        : Factor w/ 345266 levels "A020 A090 E86 I251 N170 N179",..: NA NA NA NA NA NA NA NA NA NA ...
    ##  $ educ.k        : Factor w/ 9 levels "<=8th grade",..: 4 4 8 1 5 7 6 7 3 6 ...
    ##  $ marital.k     : Factor w/ 7 levels "A","D","M","P",..: 2 7 3 2 3 2 3 3 3 5 ...
    ##  $ occup.k       : Factor w/ 430 levels "`","000","007",..: 407 169 79 134 407 96 292 66 381 134 ...
    ##  $ military.k    : Factor w/ 3 levels "N","U","Y": 1 1 3 3 1 1 3 1 1 1 ...
    ##  $ codlit.k      : Factor w/ 551455 levels "-- GASTROINTESTINAL BLEEDING-- METASTATIC CHOLANGIOCARCINOMA, PRIMARY SITE IS THE LIVER DUCTS METASTATIC TO THE"| __truncated__,..: 173261 224189 49088 19497 478883 36213 326065 50850 345111 390226 ...
    ##  $ age.k         : num  72 89 85 59 70 86 71 63 65 55 ...
    ##  $ age5cat.k     : Factor w/ 5 levels "<18yrs","18-29yrs",..: 5 5 5 4 5 5 5 4 5 4 ...
    ##  $ LCOD.k        : Factor w/ 11 levels "Alzheimers","Cancer",..: 7 7 9 10 2 9 2 10 2 9 ...
    ##  $ injury.k      : Factor w/ 5 levels "MV - all","No injury",..: 2 2 2 2 2 2 2 2 2 2 ...
    ##  $ substance.k   : Factor w/ 3 levels "Alcohol-induced",..: 3 3 3 3 3 3 3 3 3 3 ...
    ##  $ residence.k   : Factor w/ 2 levels "Out of state",..: 2 2 2 2 2 2 2 2 2 2 ...
    ##  $ raceethnic5.k : Factor w/ 7 levels "AIAN NH","Asian/PI NH",..: 7 7 7 7 2 7 7 7 2 7 ...
    ##  $ raceethnic6.k : Factor w/ 8 levels "AIAN NH","Asian",..: 8 8 8 8 2 8 8 8 2 8 ...

``` r
str(KC0317_wh)
```

    ## 'data.frame':    174300 obs. of  41 variables:
    ##  $ certno.k      : int  2017012363 2017019361 2017025187 2017025188 2017025189 2017025190 2017025192 2017025196 2017025197 2017007506 ...
    ##  $ dob.k         : Date, format: "1945-04-15" "1928-02-04" ...
    ##  $ dod.k         : Date, format: "2017-03-03" "2017-04-19" ...
    ##  $ lname.k       : chr  "VANRY" "CALLERY" "BURNETT" "LEE" ...
    ##  $ fname.k       : chr  "SYLVIA" "ROSALIE" "CHARLES" "DOUGLAS" ...
    ##  $ mname.k       : Factor w/ 46681 levels "-","--","---",..: 7844 28104 43459 21330 NA 37632 1079 34669 44195 35250 ...
    ##  $ sex.k         : Factor w/ 3 levels "F","M","U": 1 1 2 2 1 1 2 1 2 1 ...
    ##  $ ssn.k         : chr  "537446055" "476289831" "527366846" "019488823" ...
    ##  $ attclass.k    : Factor w/ 10 levels "0","1","2","3",..: 8 2 2 8 2 2 2 2 2 3 ...
    ##  $ brgrace.k     : Factor w/ 20 levels "1","2","3","4",..: 1 1 1 1 10 1 1 1 5 1 ...
    ##  $ hispanic.k    : Factor w/ 2 levels "N","Y": 2 2 2 2 2 2 2 2 2 2 ...
    ##  $ manner.k      : Factor w/ 7 levels "Accident","Undetermined",..: 4 4 4 4 4 4 4 4 4 4 ...
    ##  $ rcounty.k     : Factor w/ 1097 levels "ACADIA","ADA",..: 491 491 491 491 898 491 491 491 491 491 ...
    ##  $ rcity.k       : Factor w/ 3819 levels "4600 WELS","69006 LYON",..: 415 1663 3752 2801 1964 244 848 3038 1663 2097 ...
    ##  $ rstreet.k     : Factor w/ 555080 levels "#1 5TH AND MAIN ST.",..: 57600 219748 165576 259794 187796 248195 58903 259487 81121 285252 ...
    ##  $ resmatchcode.k: num  100 100 100 100 100 100 100 100 100 100 ...
    ##  $ rstateFIPS.k  : Factor w/ 66 levels "AB","AK","AL",..: 61 61 61 61 61 61 61 61 61 61 ...
    ##  $ rzip.k        : Factor w/ 15491 levels "00000","00077",..: 7625 5651 6328 6095 5800 4995 7831 7884 5613 5928 ...
    ##  $ dstreet.k     : Factor w/ 266442 levels "-- ENTER OTHER RESIDENCE ADDRESS AT",..: 257571 263976 NA 33444 NA 254624 NA NA 35286 125531 ...
    ##  $ dcity.k       : Factor w/ 747 levels "ABERDEEN","ACME",..: 595 467 326 326 595 42 78 595 319 421 ...
    ##  $ dzip.k        : Factor w/ 3809 levels "00000","03282",..: 1086 1155 509 509 987 309 1079 938 474 558 ...
    ##  $ dcounty.k     : Factor w/ 40 levels "ADAMS","ASOTIN",..: 17 17 17 17 17 17 17 17 17 17 ...
    ##  $ dstateFIPS.k  : Factor w/ 1 level "WA": 1 1 1 1 1 1 1 1 1 1 ...
    ##  $ dplacelit.k   : Factor w/ 21 levels "DEAD ON ARRIVAL TO HOSPITAL IN TRANSPORT",..: 16 17 13 7 13 16 13 13 3 5 ...
    ##  $ dplacecode.k  : Factor w/ 10 levels "0","1","2","3",..: 6 2 5 8 5 6 5 5 1 1 ...
    ##  $ dthyr.k       : Factor w/ 15 levels "2003","2004",..: 15 15 15 15 15 15 15 15 15 15 ...
    ##  $ UCOD.k        : Factor w/ 3086 levels "A020","A021",..: 1178 1201 1529 1325 466 858 301 1321 241 1619 ...
    ##  $ MCOD.k        : Factor w/ 345266 levels "A020 A090 E86 I251 N170 N179",..: NA NA NA NA NA NA NA NA NA NA ...
    ##  $ educ.k        : Factor w/ 9 levels "<=8th grade",..: 4 4 8 1 5 7 6 7 3 6 ...
    ##  $ marital.k     : Factor w/ 7 levels "A","D","M","P",..: 2 7 3 2 3 2 3 3 3 5 ...
    ##  $ occup.k       : Factor w/ 430 levels "`","000","007",..: 407 169 79 134 407 96 292 66 381 134 ...
    ##  $ military.k    : Factor w/ 3 levels "N","U","Y": 1 1 3 3 1 1 3 1 1 1 ...
    ##  $ codlit.k      : Factor w/ 551455 levels "-- GASTROINTESTINAL BLEEDING-- METASTATIC CHOLANGIOCARCINOMA, PRIMARY SITE IS THE LIVER DUCTS METASTATIC TO THE"| __truncated__,..: 173261 224189 49088 19497 478883 36213 326065 50850 345111 390226 ...
    ##  $ age.k         : num  72 89 85 59 70 86 71 63 65 55 ...
    ##  $ age5cat.k     : Factor w/ 5 levels "<18yrs","18-29yrs",..: 5 5 5 4 5 5 5 4 5 4 ...
    ##  $ LCOD.k        : Factor w/ 11 levels "Alzheimers","Cancer",..: 7 7 9 10 2 9 2 10 2 9 ...
    ##  $ injury.k      : Factor w/ 5 levels "MV - all","No injury",..: 2 2 2 2 2 2 2 2 2 2 ...
    ##  $ substance.k   : Factor w/ 3 levels "Alcohol-induced",..: 3 3 3 3 3 3 3 3 3 3 ...
    ##  $ residence.k   : Factor w/ 2 levels "Out of state",..: 2 2 2 2 2 2 2 2 2 2 ...
    ##  $ raceethnic5.k : Factor w/ 7 levels "AIAN NH","Asian/PI NH",..: 7 7 7 7 2 7 7 7 2 7 ...
    ##  $ raceethnic6.k : Factor w/ 8 levels "AIAN NH","Asian",..: 8 8 8 8 2 8 8 8 2 8 ...

``` r
KC0317_wh$injury.k <- factor(KC0317_wh$injury.k)
summary(KC0317_wh)
```

    ##     certno.k             dob.k                dod.k           
    ##  Min.   :2.003e+09   Min.   :1893-12-12   Min.   :2003-01-01  
    ##  1st Qu.:2.006e+09   1st Qu.:1922-01-20   1st Qu.:2006-08-24  
    ##  Median :2.010e+09   Median :1931-03-14   Median :2010-03-21  
    ##  Mean   :2.010e+09   Mean   :1936-03-13   Mean   :2010-02-23  
    ##  3rd Qu.:2.013e+09   3rd Qu.:1947-02-02   3rd Qu.:2013-09-18  
    ##  Max.   :2.017e+09   Max.   :2017-08-08   Max.   :2017-08-20  
    ##                      NA's   :18                               
    ##    lname.k            fname.k             mname.k       sex.k    
    ##  Length:174300      Length:174300      ANN    :  3438   F:87564  
    ##  Class :character   Class :character   MARIE  :  3396   M:86732  
    ##  Mode  :character   Mode  :character   LEE    :  3134   U:    4  
    ##                                        M      :  3005            
    ##                                        A      :  2494            
    ##                                        (Other):139253            
    ##                                        NA's   : 19580            
    ##     ssn.k             attclass.k       brgrace.k      hispanic.k
    ##  Length:174300      1      :138172   1      :135185   N: 16157  
    ##  Class :character   2      : 23017   2      :  8936   Y:158143  
    ##  Mode  :character   7      :  9972   5      :  2820             
    ##                     3      :  2062   6      :  2328             
    ##                     6      :  1072   7      :  2312             
    ##                     4      :     2   (Other): 10549             
    ##                     (Other):     3   NA's   : 12170             
    ##          manner.k          rcounty.k             rcity.k     
    ##  Natural     :159573   KING     :152532   SEATTLE    :56966  
    ##  Accident    :  9943   SNOHOMISH:  8323   BELLEVUE   :10343  
    ##  Suicide     :  3178   PIERCE   :  4225   RENTON     : 9395  
    ##  Homicide    :   921   KITSAP   :  1379   KENT       : 8735  
    ##  Undetermined:   662   CLALLAM  :   809   FEDERAL WAY: 7309  
    ##  (Other)     :     1   SKAGIT   :   737   AUBURN     : 7110  
    ##  NA's        :    22   (Other)  :  6295   (Other)    :74442  
    ##                   rstreet.k      resmatchcode.k  rstateFIPS.k   
    ##  7500 SEWARD PARK AVE S:   584   Min.   : 95    WA     :174282  
    ##  4831 35TH AVE SW      :   573   1st Qu.:100    CA     :     4  
    ##  13023 GREENWOOD AVE N :   532   Median :100    AK     :     2  
    ##  19303 FREMONT AVE N   :   406   Mean   :100    FL     :     2  
    ##  1122 S 216TH ST       :   367   3rd Qu.:100    NY     :     2  
    ##  4700 PHINNEY AVE N    :   307   Max.   :100    AZ     :     1  
    ##  (Other)               :171531                  (Other):     7  
    ##      rzip.k                                     dstreet.k     
    ##  98133  :  6302   12822 124TH LANE NE                :  1015  
    ##  98003  :  4533   12822 124TH LN NE                  :   407  
    ##  98118  :  4487   EVERGREEN HOSPICE                  :   280  
    ##  98198  :  4398   EVERGREEN HOSPICE, 12822 124TH LANE:    95  
    ##  98125  :  3880   2424 156TH AVE NE                  :    85  
    ##  98155  :  3796   (Other)                            : 63125  
    ##  (Other):146904   NA's                               :109293  
    ##         dcity.k          dzip.k         dcounty.k      dstateFIPS.k
    ##  SEATTLE    :78721   98122  : 11743   KING   :174300   WA:174300   
    ##  KIRKLAND   :12878   98034  : 10951   ADAMS  :     0               
    ##  BELLEVUE   :12261   98133  :  9533   ASOTIN :     0               
    ##  RENTON     :10635   98104  :  9416   BENTON :     0               
    ##  FEDERAL WAY: 9098   98003  :  7283   CHELAN :     0               
    ##  (Other)    :50691   (Other):113194   CLALLAM:     0               
    ##  NA's       :   16   NA's   : 12180   (Other):     0               
    ##                       dplacelit.k     dplacecode.k      dthyr.k     
    ##  Hospital (inpatient)       :61570   4      :61712   2016   :13338  
    ##  Home                       :49301   0      :49395   2015   :13128  
    ##  Nursing home/long term care:44847   5      :47537   2014   :13025  
    ##  Other place                : 6312   1      : 6340   2013   :12757  
    ##  Hospice                    : 5979   7      : 5997   2012   :12641  
    ##  Emergency room             : 3175   3      : 3179   2011   :12427  
    ##  (Other)                    : 3116   (Other):  140   (Other):96984  
    ##      UCOD.k             MCOD.k                          educ.k     
    ##  G309   : 10173   C349 F179:  2588   H.S. grad/GED         :57248  
    ##  C349   :  9873   G309     :  2135   Some college          :28397  
    ##  I251   :  9493   I250     :  1961   Bachelors             :26685  
    ##  I250   :  6112   C349     :  1635   Unknown               :14555  
    ##  I219   :  6072   C259     :  1528   <=8th grade           :12388  
    ##  (Other):132535   (Other)  :164046   9-12th gr., no diploma:11174  
    ##  NA's   :    42   NA's     :   407   (Other)               :23853  
    ##  marital.k    occup.k       military.k
    ##  A:  496   908    : 27768   N:127430  
    ##  D:28435   183    :  5111   U:  1271  
    ##  M:62440   557    :  5096   Y: 45599  
    ##  P:  228   290    :  4310             
    ##  S:22059   150    :  3470             
    ##  U: 1278   (Other):124754             
    ##  W:59364   NA's   :  3791             
    ##                             codlit.k          age.k       
    ##  LUNG CANCER                    :  1053   Min.   :  0.00  
    ##  PANCREATIC CANCER              :   739   1st Qu.: 64.00  
    ##  ALZHEIMERS DEMENTIA            :   704   Median : 79.00  
    ##  METASTATIC BREAST CANCER       :   650   Mean   : 73.95  
    ##  NON SMALL CELL LUNG CANCER     :   518   3rd Qu.: 88.00  
    ##  (Other)                        :170578   Max.   :113.00  
    ##  NA's                           :    58   NA's   :18      
    ##     age5cat.k                       LCOD.k     
    ##  <18yrs  :  3076   Other               :47414  
    ##  18-29yrs:  2999   Cancer              :38590  
    ##  30-44yrs:  6478   Heart Dis.          :36221  
    ##  45-64yrs: 33062   Alzheimers          :10659  
    ##  65+ yrs :128667   Stroke              :10358  
    ##  NA's    :    18   Injury-unintentional: 9408  
    ##                    (Other)             :21650  
    ##                     injury.k                  substance.k    
    ##  MV - all               :  2022   Alcohol-induced   :  2740  
    ##  No injury              :164882   Drug-induced      :  3335  
    ##  Other injury           :  1513   No Substance abuse:168225  
    ##  Unintentional fall     :  2979                              
    ##  Unintentional poisoning:  2904                              
    ##                                                              
    ##                                                              
    ##        residence.k         raceethnic5.k     raceethnic6.k   
    ##  Out of state:    18   AIAN NH    :  1491   White NH:133605  
    ##  WA resident :174282   Asian/PI NH: 12714   Unknown : 12170  
    ##                        Black NH   :  8831   Asian   : 11818  
    ##                        Hispanic   :  4022   Black NH:  8831  
    ##                        Other      :  1467   Hispanic:  4022  
    ##                        Unknown    : 12170   AIAN NH :  1491  
    ##                        White NH   :133605   (Other) :  2363

C. King County Medical Examiner\`s Homeless Death Registry data - November 2003 to September 2017
-------------------------------------------------------------------------------------------------

This data set includes all deaths to homeless or transient individuals who died in King County, Washington State and for whom the death certifier (the person who submitted a death certificate to Washington State Department of Health) was the medical examiner for King County.

The King County Medical Examiner`s Office (KCMEO) established a given decedent`s homeless or transient status by gathering information from family members, acquaintances, social service agencies, and law enforcement (where available). In some situations, the medical examiner (ME) established homelessness based on his own assessment of the situation rather than what the family reported because the stigma associated with homelessness may have resulted in inaccurate reporting.

KCMEO defines `homelessness` based on the Chief Medical Examiner\`s criteria rather than standard federal Department of Housing and Urban Development (HUD) or Department of Social and Health Services (DSHS) criteria.

### 1. Cleaning KCMEO homeless registry

I followed similar cleaning steps as with the Washington State annual death data sets including: - renaming variables, - coercing variables to specific data types (factors, dates, numeric), - cleaning the values in the first and last name fields by removing white spaces, punctuation marks, suffixes like "Jr.", "Sr.", "II" etc., - and making all values uppercase to match death certificate data.

Finally, I added the suffix ".h" to the variables in the homeless data set to identify easily the source of the features.

``` r
# Reading in and pre-processing homeless death registry data including
# cleaning and standardizing attribute names and data types

homeless <- read_csv("Data/HomelessRegistryKingCo.csv")

homeless <- rename(homeless, lname = namelast, fname = namefirst, mname = namemiddle, 
    dob = birthdate, dod = eventdate, ssn = ssn, dzip = deathzip, married = maritalstatus, 
    placeofdeath = deathplace)


# CHANGE VALUES TO UPPER CASE
homeless <- mutate_all(homeless, funs(toupper))

# THE FOLLOWING CHANGES TO THE TWO DATE FIELDS (DATE OF BIRTH AND DATE OF
# DEATH) HAVE BEEN IMPLEMENTED TO MAKE THEM CONSISTENT WITH THE FORMAT IN
# THE DEATH CERTIFICATE DATA SET.

# REMOVE HYPHENS IN DATES OF BIRTH AND DEATH TO MAKE THEM CONSISTENT WITH
# DEATH DATA DATES ARE IN DDMMMYY FORMAT TO BEGIN WITH.
homeless$dob <- gsub("-", "", homeless$dob)
homeless$dod <- gsub("-", "", homeless$dod)

# PASTE LEADING 0 TO DAY WHEN DAY IS 1 TO 9 TO MAKE THEM ALL 2 DIGIT DAYS
homeless$dob <- ifelse((nchar(homeless$dob)) < 7, paste("0", homeless$dob, sep = ""), 
    homeless$dob)
homeless$dod <- ifelse((nchar(homeless$dod)) < 7, paste("0", homeless$dod, sep = ""), 
    homeless$dod)

homeless$dob <- as.Date(homeless$dob, "%d%b%y")

# The following command assures that 2 digit years in the date of birth
# field don't have
#'20' added as the prefix when it should be '19'

homeless$dob <- as.Date(ifelse((homeless$dob > "2019-01-01" | homeless$age > 
    16), format(homeless$dob, "19%y-%m-%d"), format(homeless$dob)))

# standardize date format
homeless$dob <- ymd(homeless$dob)
homeless$dod <- dmy(homeless$dod)

# change attributes to factor

homeless %<>% mutate_at(c("rescity", "married", "placeofdeath", "deathcity", 
    "dzip", "eventcity"), funs(factor(.)))

# change 'age' to numeric
homeless$age <- as.integer(homeless$age)

# limit and reorder attributes and add '.h' as suffix to clarify dataset to
# which these attributes belong.
homeless <- select(homeless, -casenum)
homeless <- select(homeless, ssn, lname, fname, mname, dob, dod, age, everything())
h.varnames <- c(colnames(homeless))
h.varnames <- paste(h.varnames, "h", sep = ".")
colnames(homeless) = h.varnames

# remove white spaces, hyphens, and various suffixes like 'Jr', 'Sr' etc.
# from name fields
homeless$lname.h <- str_replace_all(string = homeless$lname.h, pattern = " ", 
    replacement = "")
homeless$lname.h <- str_replace_all(string = homeless$lname.h, pattern = "-", 
    replacement = "")
homeless$lname.h <- str_replace_all(string = homeless$lname.h, pattern = ",JR.", 
    replacement = "")
homeless$lname.h <- str_replace_all(string = homeless$lname.h, pattern = "JR.", 
    replacement = "")
homeless$lname.h <- str_replace_all(string = homeless$lname.h, pattern = ",SR.", 
    replacement = "")
homeless$lname.h <- str_replace_all(string = homeless$lname.h, pattern = "SR.", 
    replacement = "")
homeless$lname.h <- str_replace_all(string = homeless$lname.h, pattern = ",II", 
    replacement = "")
homeless$lname.h <- str_replace_all(string = homeless$lname.h, pattern = "II", 
    replacement = "")
homeless$fname.h <- str_replace_all(string = homeless$fname.h, pattern = " ", 
    replacement = "")


homeless$fname.h <- str_replace_all(string = homeless$fname.h, pattern = " ", 
    replacement = "")
homeless$fname.h <- str_replace_all(string = homeless$fname.h, pattern = "-", 
    replacement = "")

summary(homeless)
```

    ##     ssn.h             lname.h            fname.h         
    ##  Length:1131        Length:1131        Length:1131       
    ##  Class :character   Class :character   Class :character  
    ##  Mode  :character   Mode  :character   Mode  :character  
    ##                                                          
    ##                                                          
    ##                                                          
    ##                                                          
    ##    mname.h              dob.h                dod.h           
    ##  Length:1131        Min.   :1913-02-27   Min.   :1991-09-01  
    ##  Class :character   1st Qu.:1953-06-20   1st Qu.:2006-12-17  
    ##  Mode  :character   Median :1960-08-27   Median :2010-07-01  
    ##                     Mean   :1961-11-10   Mean   :2010-11-27  
    ##                     3rd Qu.:1969-09-18   3rd Qu.:2014-12-13  
    ##                     Max.   :2017-08-14   Max.   :2063-01-01  
    ##                     NA's   :3            NA's   :63          
    ##      age.h        resaddr.h               rescity.h           married.h  
    ##  Min.   : 0.00   Length:1131        SEATTLE    :310   NEVER MARRIED:403  
    ##  1st Qu.:41.00   Class :character   KENT       : 23   DIVORCED     :300  
    ##  Median :50.00   Mode  :character   AUBURN     : 14   UNKNOWN      :189  
    ##  Mean   :48.39                      FEDERAL WAY: 11   MARRIED      : 56  
    ##  3rd Qu.:57.00                      RENTON     :  9   WIDOWED      : 20  
    ##  Max.   :93.00                      (Other)    :151   (Other)      :  8  
    ##                                     NA's       :613   NA's         :155  
    ##                    placeofdeath.h deathaddr.h             deathcity.h 
    ##  HARBORVIEW MEDICAL CENTER:172    Length:1131        SEATTLE    :851  
    ##  OUTDOORS                 :117    Class :character   RENTON     : 40  
    ##  RESIDENCE                : 52    Mode  :character   KENT       : 36  
    ##  VEHICLE                  : 40                       AUBURN     : 31  
    ##  SIDEWALK                 : 20                       FEDERAL WAY: 31  
    ##  (Other)                  :636                       (Other)    :140  
    ##  NA's                     : 94                       NA's       :  2  
    ##      dzip.h    eventaddr.h             eventcity.h 
    ##  98104  :308   Length:1131        SEATTLE    :771  
    ##  98133  : 65   Class :character   KENT       : 43  
    ##  98101  : 57   Mode  :character   RENTON     : 37  
    ##  98122  : 51                      FEDERAL WAY: 32  
    ##  98134  : 34                      AUBURN     : 31  
    ##  (Other):610                      (Other)    :182  
    ##  NA's   :  6                      NA's       : 35

``` r
str(homeless)
```

    ## Classes 'tbl_df', 'tbl' and 'data.frame':    1131 obs. of  16 variables:
    ##  $ ssn.h         : chr  "518575716" "360649148" "543824107" "537669254" ...
    ##  $ lname.h       : chr  "POMME" "PATTON" "MANSFIELD" "SPARKS" ...
    ##  $ fname.h       : chr  "FRANCIS" "FRANKLIN" "JOHN" "MARLOWE" ...
    ##  $ mname.h       : chr  "XAVIER" "DELANO" "PATRICK" "RADCLIFFE" ...
    ##  $ dob.h         : Date, format: "1951-01-04" "1961-07-21" ...
    ##  $ dod.h         : Date, format: NA "2003-11-01" ...
    ##  $ age.h         : int  51 42 41 44 30 23 35 54 57 0 ...
    ##  $ resaddr.h     : chr  "NO PERMANENT ADDRESS" "NO PERMANENT ADDRESS" "NO PERMANENT ADDRESS" "NO PERMANENT ADDRESS" ...
    ##  $ rescity.h     : Factor w/ 94 levels "ABERDEEN","ANCHORAGE",..: NA NA 73 73 NA 84 4 73 15 NA ...
    ##  $ married.h     : Factor w/ 7 levels "DIVORCED","MARRIED",..: 4 4 4 4 4 4 4 4 4 5 ...
    ##  $ placeofdeath.h: Factor w/ 349 levels "\"TENT CITY\"",..: 59 NA NA NA NA 123 NA NA NA NA ...
    ##  $ deathaddr.h   : chr  "MASSACHUSETTS STREET / INTERSTATE-5" "INTERSTATE 5 NEAR S. 320TH STREET" "ALLEY BEHIND UPTOWN CINEMA" "2400TH BLK NW MARKET ST." ...
    ##  $ deathcity.h   : Factor w/ 32 levels "AUBURN","BELLEVUE",..: 25 10 25 25 25 25 29 25 16 NA ...
    ##  $ dzip.h        : Factor w/ 74 levels "98001","98002",..: 58 3 50 48 36 38 66 38 22 NA ...
    ##  $ eventaddr.h   : chr  "MASSACHUSETTS STREET / INTERSTATE-5" "INTERSTATE 5 NEAR S. 320TH ST." "511 QUEEN ANN AVE N" "2400TH BLK NW MARKET ST." ...
    ##  $ eventcity.h   : Factor w/ 60 levels "ABERDEEN","ACME",..: 45 17 45 45 45 53 54 45 29 45 ...

``` r
# miss_var_summary(homeless)
```

#### 2. Linking King County Homeless Death Registry with Washington State Mortality Data

The HDR contains name, date of birth, date of death, place of death (address), and social security number. There is no additional information on cause of death, or other attributes that might be used in machine learning to classify persons as homeless or with a permanent home. For this reason, the HDR data must first be linked to full death certificate data to add the relevant attributes that can be found in the death certificate.

KCMEO is required by law to submit a death certificate for all deaths it investigates. For this reason, it is very likely that the decedents' last names, first names, and locations of death will be recorded in an identical manner in HDR as well as the death certificates (barring data entry error).

In this situation it is possible to use iterative deterministic linkage to link HDR records with their complete death certificates. Using a derived attribute created by concatenating attributes in the HDR data set with low missing data ("namelast", "deathcity", "deathaddress", and "birthdate") and matching it with the same derived variable in the death data set should result in an accurate match and record linkage.

Pre-processing of the HDR and death data sets includes standardizing the values in the attributes to be used in the linkage, and creating the derived variable (concatenation of the above variables) in both data sets. The following steps use multiple combinations of key variables to link the homeless death registry records with their corresponding death certificates. The linking variables were selected based on the proportion that were missing values. Variables with low proportions of missing values were selected to complete the linkage. The four stage linkage process and the results of each round include:

-iteration 1: last name, first name, date of birth - 89% (n=1,008) identification -iteration 2 (starting with only unmatched records from iteration 1): social security number - 5.5% (n=62) identification -iteration 3 (starting with only unmatched records from iteration 2): date of death, last name, first name - 1.5% (n=17) identification -iteration 4 (starting with only unmatched records from iteration 3): date of death, date of birth, last name - 0.5% (n=6) identification

Conducting the linkage steps listed above in reverse order yields the same number (1,093 out of 1,131) of linked records.

``` r
# 'homeless' data set contains all homeless decedents who died in King
# County between late 2003 and late 2017 - n = 1,131 'KC' data set contains
# all persons who died in King County between 2003 and 2017 (inclusive) at
# the time of death and includes all place of death types. n = 200,692

## left join homeless data with King County death certificate data

## Round 1 joining variables: last name, first name and date of birth of
## homeless decedents

# miss_var_summary(homeless)
homelessa <- merge(homeless, KC, by.x = c("lname.h", "fname.h", "dob.h"), by.y = c("lname.k", 
    "fname.k", "dob.k"), all.x = TRUE)

# Remove duplicates
homelessa <- distinct(homelessa, lname.h, dob.h, .keep_all = TRUE)
# miss_var_summary(homelessa)

# Linkage round 1 resulted in 1,008 homeless records being linked to their
# respective death certificate information.

# To match the remaining 121 records, split the homeless data sets into the
# linked set (n=1,008) and the set of decedent names (n=121) that did not
# have any associated death certificate numbers (which would have come from
# the King County death certificate data set).  Try linking the records with
# no death certificate numbers by social security number for this second
# pass.

homeless2 <- filter(homelessa, is.na(certno.k))
homelessa1 <- filter(homelessa, !is.na(certno.k))


# Round 2 - Linking by social security number
homeless2 <- select(homeless2, ends_with(".h"))
homelessb <- merge(homeless2, KC, by.x = "ssn.h", by.y = "ssn.k", all.x = TRUE)

# remove duplicates
homelessb <- distinct(homelessb, lname.h, dob.h, .keep_all = TRUE)
# miss_var_summary(homelessb)

# Round 2 linkage (with ssn) yielded an additional 62 matched records
# leaving 60 unmatched

homeless3 <- filter(homelessb, is.na(certno.k))
homelessb1 <- filter(homelessb, !is.na(certno.k))


# Round 3 linkage - linking by dod, first name, last name
homeless3 <- select(homeless3, ends_with(".h"))
homelessc <- merge(homeless3, KC, by.x = c("dod.h", "fname.h", "lname.h"), by.y = c("dod.k", 
    "fname.k", "lname.k"), all.x = TRUE)
homelessc <- distinct(homelessc, lname.h, dob.h, .keep_all = TRUE)
# miss_var_summary(homelessc)

homeless4 <- filter(homelessc, is.na(certno.k))
homelessc1 <- filter(homelessc, !is.na(certno.k))

# Round 3 linkage yielded an additional 17 matched records

# Round 4 linkage: linking by last name, dod, dob
homeless4 <- select(homeless4, ends_with(".h"))
homelessd <- merge(homeless4, KC, by.x = c("dob.h", "dod.h", "lname.h"), by.y = c("dob.k", 
    "dod.k", "lname.k"), all.x = TRUE)
homelessd <- distinct(homelessd, lname.h, dob.h, .keep_all = TRUE)
# miss_var_summary(homelessd)

homeless5 <- filter(homelessd, is.na(certno.k))
homelessd1 <- filter(homelessd, !is.na(certno.k))

# Round 4 linkage yielded an additional 6 matched records

# Total matched records after 4 rounds of linkage = 1,093 out of a possible
# 1,131 homeless decedents



################################# Implementing linking steps in reverse also yields 1,093 linked
################################# records###############

homelessw <- merge(homeless, KC, by.x = c("dob.h", "dod.h", "lname.h"), by.y = c("dob.k", 
    "dod.k", "lname.k"), all.x = TRUE)
homelessw <- distinct(homelessw, lname.h, dob.h, .keep_all = TRUE)
homelessw1 <- filter(homelessw, !is.na(certno.k))

homeless10 <- filter(homelessw, is.na(certno.k))

## 790 linked in first round

homeless10 <- select(homeless10, ends_with(".h"))
homelessx <- merge(homeless10, KC, by.x = c("dod.h", "fname.h", "lname.h"), 
    by.y = c("dod.k", "fname.k", "lname.k"), all.x = TRUE)
homelessx <- distinct(homelessx, lname.h, dob.h, .keep_all = TRUE)
homeless11 <- filter(homelessx, is.na(certno.k))
homelessx1 <- filter(homelessx, !is.na(certno.k))

## 37 linked in second round

homeless11 <- select(homeless11, ends_with(".h"))
homelessy <- merge(homeless11, KC, by.x = "ssn.h", by.y = "ssn.k", all.x = TRUE)
homelessy <- distinct(homelessy, lname.h, dob.h, .keep_all = TRUE)
homeless12 <- filter(homelessy, is.na(certno.k))
homelessy1 <- filter(homelessy, !is.na(certno.k))

# 165 linked in third round

homeless12 <- select(homeless12, ends_with(".h"))
homelessz <- merge(homeless12, KC, by.x = c("lname.h", "fname.h", "dob.h"), 
    by.y = c("lname.k", "fname.k", "dob.k"), all.x = TRUE)
homelessz <- distinct(homelessz, lname.h, dob.h, .keep_all = TRUE)
homeless13 <- filter(homelessz, is.na(certno.k))
homelessz1 <- filter(homelessz, !is.na(certno.k))

# 101 linked in fourth round

############################ 

keepvar_h <- c("certno.k", "lname.h", "fname.h", "dob.h", "age.h", "mname.h", 
    "dod.h", "placeofdeath.h", "deathaddr.h", "deathcity.h", "dzip.h", "eventaddr.h", 
    "eventcity.h", "dcounty.k", "attclass.k", "sex.k", "brgrace.k", "hispanic.k", 
    "manner.k", "rcounty.k", "rcity.k", "rstreet.k", "rstateFIPS.k", "rzip.k", 
    "dcity.k", "dplacelit.k", "dplacecode.k", "dthyr.k", "UCOD.k", "MCOD.k", 
    "educ.k", "marital.k", "occup.k", "age5cat.k", "LCOD.k", "injury.k", "substance.k", 
    "residence.k", "raceethnic5.k", "raceethnic6.k", "codlit.k", "military.k")

homelessa1 <- select(homelessa1, keepvar_h)
homelessb1 <- select(homelessb1, keepvar_h)
homelessc1 <- select(homelessc1, keepvar_h)
homelessd1 <- select(homelessd1, keepvar_h)

homelessfinal <- rbind(homelessa1, homelessb1, homelessc1, homelessd1)
homelessfinal <- distinct(homelessfinal, certno.k, .keep_all = TRUE)

homelessfinal$injury.k <- factor(homelessfinal$injury.k)

# total linked = 1,093

summary(homelessfinal)
```

    ##     certno.k           lname.h            fname.h         
    ##  Min.   :2.003e+09   Length:1093        Length:1093       
    ##  1st Qu.:2.006e+09   Class :character   Class :character  
    ##  Median :2.010e+09   Mode  :character   Mode  :character  
    ##  Mean   :2.010e+09                                        
    ##  3rd Qu.:2.014e+09                                        
    ##  Max.   :2.017e+09                                        
    ##                                                           
    ##      dob.h                age.h         mname.h         
    ##  Min.   :1913-02-27   Min.   :17.00   Length:1093       
    ##  1st Qu.:1953-05-27   1st Qu.:41.00   Class :character  
    ##  Median :1960-07-18   Median :50.00   Mode  :character  
    ##  Mean   :1961-07-24   Mean   :48.77                     
    ##  3rd Qu.:1969-06-26   3rd Qu.:57.00                     
    ##  Max.   :1995-12-31   Max.   :93.00                     
    ##                                                         
    ##      dod.h                              placeofdeath.h deathaddr.h       
    ##  Min.   :1991-09-01   HARBORVIEW MEDICAL CENTER:166    Length:1093       
    ##  1st Qu.:2006-12-01   OUTDOORS                 :110    Class :character  
    ##  Median :2010-05-26   RESIDENCE                : 50    Mode  :character  
    ##  Mean   :2010-11-07   VEHICLE                  : 39                      
    ##  3rd Qu.:2014-11-20   SIDEWALK                 : 20                      
    ##  Max.   :2063-01-01   (Other)                  :616                      
    ##  NA's   :55           NA's                     : 92                      
    ##       deathcity.h      dzip.h    eventaddr.h             eventcity.h 
    ##  SEATTLE    :823   98104  :299   Length:1093        SEATTLE    :748  
    ##  RENTON     : 39   98133  : 65   Class :character   KENT       : 43  
    ##  KENT       : 36   98101  : 56   Mode  :character   RENTON     : 36  
    ##  AUBURN     : 31   98122  : 49                      AUBURN     : 31  
    ##  FEDERAL WAY: 30   98107  : 32                      FEDERAL WAY: 30  
    ##  (Other)    :133   (Other):588                      (Other)    :174  
    ##  NA's       :  1   NA's   :  4                      NA's       : 31  
    ##    dcounty.k      attclass.k  sex.k     brgrace.k   hispanic.k
    ##  KING   :1093   2      :974   F:178   1      :736   N:100     
    ##  ADAMS  :   0   1      :107   M:915   2      :164   Y:993     
    ##  ASOTIN :   0   7      :  7   U:  0   3      : 78             
    ##  BENTON :   0   3      :  2           15     : 49             
    ##  CHELAN :   0   6      :  1           99     : 16             
    ##  CLALLAM:   0   (Other):  0           (Other): 43             
    ##  (Other):   0   NA's   :  2           NA's   :  7             
    ##          manner.k       rcounty.k      rcity.k   
    ##  Accident    :496   KING     :735   SEATTLE:459  
    ##  Natural     :394   UNKNOWN  :142   UNKNOWN:198  
    ##  Suicide     : 81   SNOHOMISH: 29   KENT   : 33  
    ##  Homicide    : 61   PIERCE   : 28   RENTON : 23  
    ##  Undetermined: 60   UNK      : 20   UNK    : 22  
    ##  (Other)     :  0   (Other)  :104   (Other):326  
    ##  NA's        :  1   NA's     : 35   NA's   : 32  
    ##                 rstreet.k    rstateFIPS.k        rzip.k   
    ##  UNKNOWN             :225   WA     :886   99999     :299  
    ##  HOMELESS            : 50   ZZ     :151   98104     : 95  
    ##  NO PERMANENT ADDRESS: 42   CA     : 13   98101     : 28  
    ##  77 S WASHINGTON ST  : 21   OR     :  8   99999-9999: 28  
    ##  TRANSIENT           : 19   AK     :  4   98133     : 22  
    ##  (Other)             :734   ID     :  3   (Other)   :616  
    ##  NA's                :  2   (Other): 28   NA's      :  5  
    ##         dcity.k                         dplacelit.k   dplacecode.k
    ##  SEATTLE    :832   Other place                :572   1      :624  
    ##  RENTON     : 39   Hospital (inpatient)       :247   4      :272  
    ##  KENT       : 36   Home                       : 99   0      :100  
    ##  AUBURN     : 32   OTHER                      : 52   3      : 49  
    ##  FEDERAL WAY: 30   Emergency room             : 45   5      : 37  
    ##  BELLEVUE   : 21   Nursing home/long term care: 34   7      :  8  
    ##  (Other)    :103   (Other)                    : 44   (Other):  3  
    ##     dthyr.k        UCOD.k              MCOD.k   
    ##  2006   :108   X420   :153   R99          : 26  
    ##  2017   : 94   X440   :140   I250         : 23  
    ##  2005   : 93   I250   : 80   I250 I119    : 19  
    ##  2015   : 90   I119   : 38   I119         : 15  
    ##  2007   : 89   K703   : 38   X95 T019 T141: 13  
    ##  2016   : 86   (Other):642   (Other)      :906  
    ##  (Other):533   NA's   :  2   NA's         : 91  
    ##                     educ.k    marital.k    occup.k       age5cat.k  
    ##  H.S. grad/GED         :398   A:  8     999    :269   <18yrs  :  0  
    ##  Unknown               :306   D:320     980    : 81   18-29yrs: 84  
    ##  9-12th gr., no diploma:179   M: 69     982    : 58   30-44yrs:264  
    ##  Some college          :109   P:  0     997    : 45   45-64yrs:643  
    ##  <=8th grade           : 36   S:486     998    : 34   65+ yrs :101  
    ##  Bachelors             : 28   U:188     (Other):576   NA's    :  1  
    ##  (Other)               : 37   W: 22     NA's   : 30                 
    ##                        LCOD.k                       injury.k  
    ##  Injury-unintentional     :487   MV - all               : 57  
    ##  Other                    :228   No injury              :604  
    ##  Heart Dis.               :155   Other injury           : 58  
    ##  Suicide-all              : 81   Unintentional fall     : 18  
    ##  Chronic Liver dis./cirrh.: 58   Unintentional poisoning:356  
    ##  Cancer                   : 28                                
    ##  (Other)                  : 56                                
    ##              substance.k        residence.k      raceethnic5.k
    ##  Alcohol-induced   : 91   Out of state: 56   AIAN NH    : 75  
    ##  Drug-induced      :357   WA resident :886   Asian/PI NH: 24  
    ##  No Substance abuse:645   NA's        :151   Black NH   :157  
    ##                                              Hispanic   : 95  
    ##                                              Other      : 21  
    ##                                              Unknown    :  7  
    ##                                              White NH   :714  
    ##   raceethnic6.k
    ##  White NH:714  
    ##  Black NH:157  
    ##  Hispanic: 95  
    ##  AIAN NH : 75  
    ##  Other   : 21  
    ##  Asian   : 19  
    ##  (Other) : 12  
    ##                                                          codlit.k   
    ##  HYPERTENSIVE AND ATHEROSCLEROTIC CARDIOVASCULAR DISEASE     :  18  
    ##  HYPERTENSIVE CARDIOVASCULAR DISEASE                         :   9  
    ##  ASCVD                                                       :   8  
    ##  MULTIPLE GUNSHOT WOUNDS     SHOT BY OTHER                   :   8  
    ##  HYPERTENSIVE AND ASCVD                                      :   7  
    ##  (Other)                                                     :1042  
    ##  NA's                                                        :   1  
    ##  military.k
    ##  N:778     
    ##  U:121     
    ##  Y:194     
    ##            
    ##            
    ##            
    ## 

``` r
str(homelessfinal)
```

    ## 'data.frame':    1093 obs. of  42 variables:
    ##  $ certno.k      : int  2017019289 2014057047 2017016040 2010070278 2016052688 2015064867 2011073979 2004023773 2013045577 2013065733 ...
    ##  $ lname.h       : chr  "ADAMS" "ADLER" "ALANIS" "ALBERTE" ...
    ##  $ fname.h       : chr  "DANIEL" "CHRISTOPHER" "RUPERTO" "LINDA" ...
    ##  $ dob.h         : Date, format: "1987-10-09" "1972-01-10" ...
    ##  $ age.h         : int  29 42 48 52 41 32 40 63 25 46 ...
    ##  $ mname.h       : chr  "T." "D." "FELIX" "SUE" ...
    ##  $ dod.h         : Date, format: "2017-04-18" "2014-09-10" ...
    ##  $ placeofdeath.h: Factor w/ 349 levels "\"TENT CITY\"",..: 192 163 257 154 20 37 225 NA 122 232 ...
    ##  $ deathaddr.h   : chr  "107TH AND NORTHGATE WY" "1230 CENTRAL AVE. S." "308 4TH AVE S, APT #502" "23605 SE EVANS ST." ...
    ##  $ deathcity.h   : Factor w/ 32 levels "AUBURN","BELLEVUE",..: 25 13 25 11 25 25 13 25 12 25 ...
    ##  $ dzip.h        : Factor w/ 74 levels "98001","98002",..: 56 18 38 14 46 57 18 38 15 43 ...
    ##  $ eventaddr.h   : chr  "107TH AND NORTHGATE WY" "1230 CENTRAL AVE. S." "308 4TH AVE S, APT #502" "23605 SE EVANS ST." ...
    ##  $ eventcity.h   : Factor w/ 60 levels "ABERDEEN","ACME",..: 45 24 45 20 45 45 24 45 23 45 ...
    ##  $ dcounty.k     : Factor w/ 40 levels "ADAMS","ASOTIN",..: 17 17 17 17 17 17 17 17 17 17 ...
    ##  $ attclass.k    : Factor w/ 10 levels "0","1","2","3",..: 3 3 3 3 3 3 3 2 3 3 ...
    ##  $ sex.k         : Factor w/ 3 levels "F","M","U": 2 2 2 1 2 1 2 2 2 2 ...
    ##  $ brgrace.k     : Factor w/ 20 levels "1","2","3","4",..: 2 1 1 1 2 8 1 1 15 15 ...
    ##  $ hispanic.k    : Factor w/ 2 levels "N","Y": 2 2 1 2 2 2 2 2 1 1 ...
    ##  $ manner.k      : Factor w/ 7 levels "Accident","Undetermined",..: 1 2 1 1 1 1 1 4 1 2 ...
    ##  $ rcounty.k     : Factor w/ 1097 levels "ACADIA","ADA",..: 1084 491 491 1000 898 491 60 491 491 NA ...
    ##  $ rcity.k       : Factor w/ 3819 levels "4600 WELS","69006 LYON",..: 3779 1663 3038 3497 2224 3038 263 3038 158 NA ...
    ##  $ rstreet.k     : Factor w/ 555080 levels "#1 5TH AND MAIN ST.",..: 532490 553626 306598 554897 384046 554897 142053 553969 369808 554897 ...
    ##  $ rstateFIPS.k  : Factor w/ 66 levels "AB","AK","AL",..: 61 61 61 66 61 61 18 61 61 61 ...
    ##  $ rzip.k        : Factor w/ 15491 levels "00000","00077",..: 13178 5651 6586 15155 6019 15155 2646 7268 4793 15155 ...
    ##  $ dcity.k       : Factor w/ 747 levels "ABERDEEN","ACME",..: 595 319 595 304 595 595 319 595 317 595 ...
    ##  $ dplacelit.k   : Factor w/ 21 levels "DEAD ON ARRIVAL TO HOSPITAL IN TRANSPORT",..: 17 20 19 20 20 5 20 9 20 20 ...
    ##  $ dplacecode.k  : Factor w/ 10 levels "0","1","2","3",..: 2 2 9 2 2 1 2 5 2 2 ...
    ##  $ dthyr.k       : Factor w/ 15 levels "2003","2004",..: 15 12 15 8 14 13 9 2 11 11 ...
    ##  $ UCOD.k        : Factor w/ 3086 levels "A020","A021",..: 2934 2598 2931 2934 2699 2934 2926 1738 2890 2598 ...
    ##  $ MCOD.k        : Factor w/ 345266 levels "A020 A090 E86 I251 N170 N179",..: NA 315360 NA 336970 321046 337786 333129 277005 331562 315360 ...
    ##  $ educ.k        : Factor w/ 9 levels "<=8th grade",..: 3 9 5 9 3 4 2 9 3 3 ...
    ##  $ marital.k     : Factor w/ 7 levels "A","D","M","P",..: 5 6 5 2 1 5 2 5 5 5 ...
    ##  $ occup.k       : Factor w/ 430 levels "`","000","007",..: 10 430 188 430 106 428 430 430 410 409 ...
    ##  $ age5cat.k     : Factor w/ 5 levels "<18yrs","18-29yrs",..: 3 3 4 4 3 3 3 4 2 4 ...
    ##  $ LCOD.k        : Factor w/ 11 levels "Alzheimers","Cancer",..: 8 9 8 8 8 8 8 3 8 9 ...
    ##  $ injury.k      : Factor w/ 5 levels "MV - all","No injury",..: 5 2 5 5 1 5 3 2 3 2 ...
    ##  $ substance.k   : Factor w/ 3 levels "Alcohol-induced",..: 2 3 2 2 3 2 3 1 3 3 ...
    ##  $ residence.k   : Factor w/ 2 levels "Out of state",..: 2 2 2 NA 2 2 1 2 2 2 ...
    ##  $ raceethnic5.k : Factor w/ 7 levels "AIAN NH","Asian/PI NH",..: 3 7 4 7 3 2 7 7 4 4 ...
    ##  $ raceethnic6.k : Factor w/ 8 levels "AIAN NH","Asian",..: 3 8 4 8 3 2 8 8 4 4 ...
    ##  $ codlit.k      : Factor w/ 551455 levels "-- GASTROINTESTINAL BLEEDING-- METASTATIC CHOLANGIOCARCINOMA, PRIMARY SITE IS THE LIVER DUCTS METASTATIC TO THE"| __truncated__,..: 199480 536387 21736 8845 512631 9115 296595 93916 243600 379112 ...
    ##  $ military.k    : Factor w/ 3 levels "N","U","Y": 1 2 1 1 1 1 1 2 1 1 ...

``` r
a <- table(homelessfinal$injury.k)
a
```

    ## 
    ##                MV - all               No injury            Other injury 
    ##                      57                     604                      58 
    ##      Unintentional fall Unintentional poisoning 
    ##                      18                     356

``` r
# miss_var_summary(homelessfinal)
```

### 3. Creating combined dataset for exploratory data analysis

Here I remove all the suffixes I added earlier in the record linkage proces to standardize the column names for the final/linked homeless data set and the King County 2003-17 death data set containing records of all decedents with permanent homes. Note that this is not the sample data set that will be used to train the machine learning model later. For exploratory data analysis I chose to look at the full set of data of King County decedents with homes to compare with the homeless group.

I created a new feature to distinguish homeless from "with home" decedents and then merged the two data sets in preparation for exploratory data analysis.

``` r
# Combining linked homeless death data with 'with home' King County death
# data for exploratory data analysis and beyond.

h <- homelessfinal
wh <- KC0317_wh


# Standardize column names and merge final homeless with King Co 2003-17
# 'with home' death data

keepvars_eda <- c("certno.k", "dcounty.k", "attclass.k", "sex.k", "brgrace.k", 
    "hispanic.k", "manner.k", "rcounty.k", "rcity.k", "rstateFIPS.k", "rzip.k", 
    "dcity.k", "dplacecode.k", "dthyr.k", "UCOD.k", "educ.k", "marital.k", "occup.k", 
    "age5cat.k", "LCOD.k", "injury.k", "substance.k", "residence.k", "raceethnic5.k", 
    "raceethnic6.k", "codlit.k", "military.k")

h %<>% select(keepvars_eda)
h$status <- "Homeless"

wh %<>% select(keepvars_eda)
wh$status <- "With home"

stdnames <- c("certno", "dcounty", "attclass", "sex", "brgrace", "hispanic", 
    "manner", "rcounty", "rcity", "rstateFIPS", "rzip", "dcity", "dplacecode", 
    "dthyr", "UCOD", "educ", "marital", "occupcode", "age5cat", "LCOD", "injury", 
    "substance", "residence", "raceethnic5", "raceethnic6", "CODliteral", "military", 
    "status")

colnames(h) <- stdnames
colnames(wh) <- stdnames

EDAdf <- rbind(h, wh)
EDAdf$status <- as.factor(EDAdf$status)
EDAdf$dplacecode <- factor(EDAdf$dplacecode, levels = c("0", "1", "2", "3", 
    "4", "5", "6", "7", "8", "9"), labels = c("Home", "Other", "In transport", 
    "ER", "Hospital inpatient", "Nursing home/Longterm care", "Hospital", "Hospice", 
    "Other person's home", "Unknown"))
summary(EDAdf)
```

    ##      certno             dcounty          attclass      sex      
    ##  Min.   :2.003e+09   KING   :175393   1      :138279   F:87742  
    ##  1st Qu.:2.006e+09   ADAMS  :     0   2      : 23991   M:87647  
    ##  Median :2.010e+09   ASOTIN :     0   7      :  9979   U:    4  
    ##  Mean   :2.010e+09   BENTON :     0   3      :  2064            
    ##  3rd Qu.:2.013e+09   CHELAN :     0   6      :  1073            
    ##  Max.   :2.017e+09   CLALLAM:     0   (Other):     5            
    ##                      (Other):     0   NA's   :     2            
    ##     brgrace       hispanic            manner            rcounty      
    ##  1      :135921   N: 16257   Natural     :159967   KING     :153267  
    ##  2      :  9100   Y:159136   Accident    : 10439   SNOHOMISH:  8352  
    ##  5      :  2820              Suicide     :  3259   PIERCE   :  4253  
    ##  6      :  2331              Homicide    :   982   KITSAP   :  1387  
    ##  7      :  2314              Undetermined:   722   CLALLAM  :   812  
    ##  (Other): 10730              (Other)     :     1   (Other)  :  7287  
    ##  NA's   : 12177              NA's        :    23   NA's     :    35  
    ##          rcity         rstateFIPS          rzip                dcity      
    ##  SEATTLE    :57425   WA     :175168   98133  :  6324   SEATTLE    :79553  
    ##  BELLEVUE   :10358   ZZ     :   151   98003  :  4543   KIRKLAND   :12892  
    ##  RENTON     : 9418   CA     :    17   98118  :  4502   BELLEVUE   :12282  
    ##  KENT       : 8768   OR     :     9   98198  :  4411   RENTON     :10674  
    ##  FEDERAL WAY: 7326   AK     :     6   98125  :  3892   FEDERAL WAY: 9128  
    ##  (Other)    :82066   TX     :     4   (Other):151716   (Other)    :50848  
    ##  NA's       :   32   (Other):    38   NA's   :     5   NA's       :   16  
    ##                       dplacecode        dthyr            UCOD       
    ##  Hospital inpatient        :61984   2016   :13424   G309   : 10173  
    ##  Home                      :49495   2015   :13218   C349   :  9886  
    ##  Nursing home/Longterm care:47574   2014   :13089   I251   :  9497  
    ##  Other                     : 6964   2013   :12840   I250   :  6192  
    ##  Hospice                   : 6005   2012   :12696   I219   :  6081  
    ##  ER                        : 3228   2008   :12488   (Other):133520  
    ##  (Other)                   :  143   (Other):97638   NA's   :    44  
    ##                      educ       marital     occupcode     
    ##  H.S. grad/GED         :57646   A:  504   908    : 27793  
    ##  Some college          :28506   D:28755   183    :  5112  
    ##  Bachelors             :26713   M:62509   557    :  5104  
    ##  Unknown               :14861   P:  228   290    :  4315  
    ##  <=8th grade           :12424   S:22545   150    :  3470  
    ##  9-12th gr., no diploma:11353   U: 1466   (Other):125778  
    ##  (Other)               :23890   W:59386   NA's   :  3821  
    ##      age5cat                         LCOD      
    ##  <18yrs  :  3076   Other               :47642  
    ##  18-29yrs:  3083   Cancer              :38618  
    ##  30-44yrs:  6742   Heart Dis.          :36376  
    ##  45-64yrs: 33705   Alzheimers          :10659  
    ##  65+ yrs :128768   Stroke              :10368  
    ##  NA's    :    19   Injury-unintentional: 9895  
    ##                    (Other)             :21835  
    ##                      injury                    substance     
    ##  MV - all               :  2079   Alcohol-induced   :  2831  
    ##  No injury              :165486   Drug-induced      :  3692  
    ##  Other injury           :  1571   No Substance abuse:168870  
    ##  Unintentional fall     :  2997                              
    ##  Unintentional poisoning:  3260                              
    ##                                                              
    ##                                                              
    ##         residence           raceethnic5       raceethnic6    
    ##  Out of state:    74   AIAN NH    :  1566   White NH:134319  
    ##  WA resident :175168   Asian/PI NH: 12738   Unknown : 12177  
    ##  NA's        :   151   Black NH   :  8988   Asian   : 11837  
    ##                        Hispanic   :  4117   Black NH:  8988  
    ##                        Other      :  1488   Hispanic:  4117  
    ##                        Unknown    : 12177   AIAN NH :  1566  
    ##                        White NH   :134319   (Other) :  2389  
    ##                                                 CODliteral     military  
    ##  LUNG CANCER                                         :  1053   N:128208  
    ##  PANCREATIC CANCER                                   :   739   U:  1392  
    ##  ALZHEIMERS DEMENTIA                                 :   704   Y: 45793  
    ##  METASTATIC BREAST CANCER                            :   650             
    ##  PROBABLE ATHEROSCLEROTIC CARDIOVASCULAR DISEASE     :   521             
    ##  (Other)                                             :171667             
    ##  NA's                                                :    59             
    ##        status      
    ##  Homeless :  1093  
    ##  With home:174300  
    ##                    
    ##                    
    ##                    
    ##                    
    ## 

``` r
write.csv(EDAdf, file = "HomelessFinal.csv")
```

In the next section, I will use this data set for exploratary data analysis prior to training machine learning models in the last section.
