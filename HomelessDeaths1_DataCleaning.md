Part 1 - Classification of Homeless Deaths: data cleaning and preparation
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
library(here)

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

    ## 'data.frame':    227829 obs. of  33 variables:
    ##  $ certno      : int  2017012363 2017019356 2017019357 2017019358 2017019359 2017026057 2017019361 2017019363 2017019367 2017019368 ...
    ##  $ dob         : Factor w/ 31027 levels "01/01/1900","01/01/1902",..: 8905 10404 30623 22503 23100 18470 2916 16971 407 2740 ...
    ##  $ dod         : Factor w/ 2724 levels "01/01/2003","01/01/2004",..: 476 889 889 881 881 1231 849 881 905 905 ...
    ##  $ lname       : Factor w/ 60991 levels "A'BEAR","A'NIJEHOLT",..: 56150 7475 2907 25869 53508 22764 7700 18233 18620 34724 ...
    ##  $ fname       : Factor w/ 17061 levels "\"FAY\"","A",..: 14848 4124 14316 16504 15258 7530 13520 13465 3835 4260 ...
    ##  $ mname       : Factor w/ 19569 levels "-","--","-VERNIE-",..: 3333 NA 5257 10253 NA 6253 11924 7373 5482 9328 ...
    ##  $ sex         : Factor w/ 2 levels "F","M": 1 2 1 2 1 1 1 2 1 2 ...
    ##  $ ssn         : Factor w/ 229483 levels "000-00-0005",..: 161462 16036 181537 213037 5675 23306 46056 33586 176179 27891 ...
    ##  $ attclass    : int  7 1 1 2 1 1 1 2 1 1 ...
    ##  $ brgrace     : int  1 1 1 1 1 1 1 1 1 1 ...
    ##  $ hispanic    : Factor w/ 2 levels "N","Y": 2 2 2 2 2 2 2 2 2 2 ...
    ##  $ manner      : Factor w/ 6 levels "A","C","H","N",..: 4 4 4 1 4 4 4 4 4 4 ...
    ##  $ rcounty     : Factor w/ 646 levels "ADA","ADAMS",..: 281 307 307 520 437 118 281 261 106 119 ...
    ##  $ rcity       : Factor w/ 2099 levels "4600 WELS","69006 LYON",..: 214 300 287 1139 683 1711 939 1021 1120 1948 ...
    ##  $ rstreet     : Factor w/ 190833 levels "#1 CONVALESCENT CENTER BLVD",..: 19873 3610 92236 32733 5913 149490 75508 140349 57534 166937 ...
    ##  $ resmatchcode: int  100 100 100 100 100 NA 100 100 100 100 ...
    ##  $ rstateFIPS  : Factor w/ 63 levels "AB","AK","AL",..: 58 58 58 58 58 58 58 58 58 58 ...
    ##  $ rzip        : Factor w/ 3157 levels "00000","00705",..: 2219 2544 2540 2308 2375 2432 2091 2293 2695 2655 ...
    ##  $ dstreet     : Factor w/ 66461 levels "-AT SEA","\"A PART OF THE FAMILY\" 2618 W 10TH",..: 65176 1285 NA 64551 63426 NA 66074 46802 19248 66079 ...
    ##  $ dcity       : Factor w/ 1457 levels "A. MUANG THAILAND",..: 1156 206 199 760 477 1163 896 670 749 1352 ...
    ##  $ dzip        : Factor w/ 1291 levels "01960","03104",..: 566 858 857 649 709 755 581 640 1019 969 ...
    ##  $ dcounty     : Factor w/ 523 levels "ACADIA","ADA",..: 223 251 251 430 351 83 223 202 74 84 ...
    ##  $ dstateFIPS  : Factor w/ 77 levels "AK","AL","AR",..: 73 73 73 73 73 73 73 73 73 73 ...
    ##  $ dplacelit   : Factor w/ 19 levels "DECEDENT'S HOME",..: 14 14 11 14 14 14 15 1 1 5 ...
    ##  $ dplacecode  : int  5 5 4 5 5 5 1 0 0 7 ...
    ##  $ dthyr       : int  2017 2017 2017 2017 2017 2017 2017 2017 2017 2017 ...
    ##  $ UCOD        : Factor w/ 2363 levels "A029","A044",..: 897 997 805 1164 992 990 918 918 319 984 ...
    ##  $ MCOD        : Factor w/ 121491 levels "A029 I714 N180",..: NA NA NA NA NA NA NA NA NA NA ...
    ##  $ educ        : int  4 3 6 6 3 3 4 4 4 1 ...
    ##  $ marital     : Factor w/ 7 levels "A","D","M","P",..: 2 7 7 3 7 7 7 5 3 7 ...
    ##  $ occup       : Factor w/ 414 levels "`","000","007",..: 391 232 134 95 391 161 165 141 182 335 ...
    ##  $ military    : Factor w/ 3 levels "N","U","Y": 1 1 1 3 1 1 1 1 1 3 ...
    ##  $ codlit      : Factor w/ 170052 levels ";LARGE CELL LYMPHOMA    CHRONIC A FIB, DEMENTIA, DIABETES, POST STROKE SYNDROME ",..: 51019 48458 160364 139881 163228 125632 67582 48426 83578 62276 ...

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
    ##  1st Qu.:2.004e+09   1st Qu.:1919-05-08   1st Qu.:2004-03-26  
    ##  Median :2.005e+09   Median :1927-07-23   Median :2005-11-19  
    ##  Mean   :2.006e+09   Mean   :1932-06-11   Mean   :2006-03-06  
    ##  3rd Qu.:2.008e+09   3rd Qu.:1942-04-13   3rd Qu.:2008-01-02  
    ##  Max.   :2.017e+09   Max.   :2017-08-08   Max.   :2017-08-21  
    ##                      NA's   :27                               
    ##     lname              fname               mname        sex       
    ##  Length:227829      Length:227829      MARIE  :  4675   F:114606  
    ##  Class :character   Class :character   LEE    :  4561   M:113223  
    ##  Mode  :character   Mode  :character   ANN    :  4104             
    ##                                        M      :  3828             
    ##                                        L      :  3419             
    ##                                        (Other):186770             
    ##                                        NA's   : 20472             
    ##      ssn               attclass         brgrace       hispanic  
    ##  Length:227829      1      :181979   1      :165175   N: 50208  
    ##  Class :character   2      : 31690   2      :  4645   Y:177621  
    ##  Mode  :character   3      :  6709   15     :  2579             
    ##                     7      :  5964   3      :  2369             
    ##                     6      :  1467   6      :  1138             
    ##                     9      :    13   (Other):  5898             
    ##                     (Other):     7   NA's   : 46025             
    ##   manner            rcounty            rcity       
    ##  A   : 12432   KING     :55535   SEATTLE  : 21288  
    ##  C   :   804   PIERCE   :26809   SPOKANE  : 11384  
    ##  H   :  1099   SNOHOMISH:20595   TACOMA   : 11384  
    ##  N   :209380   SPOKANE  :18082   VANCOUVER:  9061  
    ##  P   :     8   CLARK    :11931   EVERETT  :  5261  
    ##  S   :  4064   (Other)  :94657   (Other)  :169406  
    ##  NA's:    42   NA's     :  220   NA's     :    45  
    ##                    rstreet        resmatchcode      rstateFIPS    
    ##  UNKNOWN               :   371   Min.   :  0.00   WA     :221968  
    ##  7500 SEWARD PARK AVE S:   217   1st Qu.:100.00   OR     :  2052  
    ##  4831 35TH AVE SW      :   215   Median :100.00   ID     :  1085  
    ##  534 BOYER AVE         :   213   Mean   : 95.53   CA     :   514  
    ##  13023 GREENWOOD AVE N :   187   3rd Qu.:100.00   AK     :   376  
    ##  19303 FREMONT AVE N   :   187   Max.   :100.00   (Other):  1833  
    ##  (Other)               :226439   NA's   :182      NA's   :     1  
    ##       rzip                                       dstreet      
    ##  98632  :  2644   FRANCISCAN HOSPICE HOUSE           :  1019  
    ##  98133  :  2357   12822 124TH LANE NE                :   318  
    ##  98902  :  2144   TRI-CITIES CHAPLAINCY HOSPICE HOUSE:   266  
    ##  98382  :  1953   12822 124TH LN NE                  :   155  
    ##  99205  :  1899   HOSPICE HOUSE                      :   126  
    ##  (Other):216768   (Other)                            : 73418  
    ##  NA's   :    64   NA's                               :152527  
    ##        dcity             dzip             dcounty      dstateFIPS 
    ##  SEATTLE  : 30438   98122  :  3976   KING     :63002   WA:227829  
    ##  SPOKANE  : 16414   98201  :  3841   PIERCE   :27351              
    ##  TACOMA   : 12648   98902  :  3599   SPOKANE  :20604              
    ##  VANCOUVER: 10824   98104  :  3400   SNOHOMISH:18716              
    ##  EVERETT  :  7240   98632  :  3320   CLARK    :12657              
    ##  (Other)  :150216   (Other):163680   THURSTON : 9107              
    ##  NA's     :    49   NA's   : 46013   (Other)  :76392              
    ##                        dplacelit       dplacecode        dthyr      
    ##  Hospital (inpatient)       :69621   4      :70042   2003   :45924  
    ##  Home                       :67619   0      :68079   2004   :44809  
    ##  Nursing home/long term care:62799   5      :63089   2008   :27889  
    ##  Other place                :11506   1      :11578   2009   :27751  
    ##  Hospice                    : 7392   7      : 7499   2007   :27169  
    ##  Emergency room             : 7215   3      : 7254   2006   :26485  
    ##  (Other)                    : 1677   (Other):  288   (Other):27802  
    ##       UCOD               MCOD             educ       marital  
    ##  C349   : 15380   C349 F179:  4091   3      :72704   A:  441  
    ##  I251   : 15243   G309     :  3075   9      :43838   D:35210  
    ##  G309   : 12054   C349     :  3000   4      :30057   M:87655  
    ##  I219   : 11713   I250     :  2219   6      :19838   P:   73  
    ##  J449   : 10203   C509     :  2016   1      :19172   S:21756  
    ##  (Other):163132   (Other)  :211897   2      :18954   U:  995  
    ##  NA's   :   104   NA's     :  1531   (Other):23266   W:81699  
    ##      occup        military                        codlit      
    ##  908    : 43764   N:160495   LUNG CANCER             :  2136  
    ##  183    :  5326   U:  1153   ALZHEIMERS DEMENTIA     :  1060  
    ##  290    :  4668   Y: 66181   COPD                    :   957  
    ##  396    :  4050              PANCREATIC CANCER       :   937  
    ##  150    :  3947              ASCVD                   :   926  
    ##  (Other):161214              (Other)                 :221746  
    ##  NA's   :  4860              NA's                    :    67

``` r
str(WA0317)
```

    ## 'data.frame':    227829 obs. of  33 variables:
    ##  $ certno      : int  2017012363 2017019356 2017019357 2017019358 2017019359 2017026057 2017019361 2017019363 2017019367 2017019368 ...
    ##  $ dob         : Date, format: "1945-04-15" "1918-05-03" ...
    ##  $ dod         : Date, format: "2017-03-03" "2017-04-24" ...
    ##  $ lname       : chr  "VANRY" "BYERS" "BASKIN" "JOHNSON" ...
    ##  $ fname       : chr  "SYLVIA" "DOUGLAS" "SHIRLEY" "WILLARD" ...
    ##  $ mname       : Factor w/ 19569 levels "-","--","-VERNIE-",..: 3333 NA 5257 10253 NA 6253 11924 7373 5482 9328 ...
    ##  $ sex         : Factor w/ 2 levels "F","M": 1 2 1 2 1 1 1 2 1 2 ...
    ##  $ ssn         : chr  "537446055" "258429171" "539181252" "559307744" ...
    ##  $ attclass    : Factor w/ 9 levels "0","1","2","3",..: 8 2 2 3 2 2 2 3 2 2 ...
    ##  $ brgrace     : Factor w/ 20 levels "1","2","3","4",..: 1 1 1 1 1 1 1 1 1 1 ...
    ##  $ hispanic    : Factor w/ 2 levels "N","Y": 2 2 2 2 2 2 2 2 2 2 ...
    ##  $ manner      : Factor w/ 6 levels "A","C","H","N",..: 4 4 4 1 4 4 4 4 4 4 ...
    ##  $ rcounty     : Factor w/ 643 levels "ADA","ADAMS",..: 279 305 305 517 434 117 279 259 106 118 ...
    ##  $ rcity       : Factor w/ 2090 levels "4600 WELS","69006 LYON",..: 211 297 284 1133 677 1703 933 1015 1114 1939 ...
    ##  $ rstreet     : Factor w/ 186694 levels "#1 CONVALESCENT CENTER BLVD",..: 19429 3519 90183 31977 5763 146232 73794 137277 56202 163330 ...
    ##  $ resmatchcode: num  100 100 100 100 100 NA 100 100 100 100 ...
    ##  $ rstateFIPS  : Factor w/ 63 levels "AB","AK","AL",..: 58 58 58 58 58 58 58 58 58 58 ...
    ##  $ rzip        : Factor w/ 3141 levels "00000","00705",..: 2208 2530 2526 2297 2364 2420 2080 2282 2681 2641 ...
    ##  $ dstreet     : Factor w/ 66461 levels "-AT SEA","\"A PART OF THE FAMILY\" 2618 W 10TH",..: 65176 1285 NA 64551 63426 NA 66074 46802 19248 66079 ...
    ##  $ dcity       : Factor w/ 639 levels "ABERDEEN","ACME",..: 505 86 84 340 210 510 396 295 332 594 ...
    ##  $ dzip        : Factor w/ 947 levels "03282","06232",..: 226 517 516 308 368 414 241 299 678 628 ...
    ##  $ dcounty     : Factor w/ 40 levels "ADAMS","ASOTIN",..: 17 21 21 32 27 5 17 15 4 6 ...
    ##  $ dstateFIPS  : Factor w/ 1 level "WA": 1 1 1 1 1 1 1 1 1 1 ...
    ##  $ dplacelit   : Factor w/ 18 levels "DECEDENT'S HOME",..: 13 13 10 13 13 13 14 1 1 5 ...
    ##  $ dplacecode  : Factor w/ 10 levels "0","1","2","3",..: 6 6 5 6 6 6 2 1 1 8 ...
    ##  $ dthyr       : Factor w/ 9 levels "2003","2004",..: 9 9 9 9 9 9 9 9 9 9 ...
    ##  $ UCOD        : Factor w/ 2333 levels "A029","A044",..: 890 990 800 1156 985 983 911 911 315 977 ...
    ##  $ MCOD        : Factor w/ 119173 levels "A029 I714 N180",..: NA NA NA NA NA NA NA NA NA NA ...
    ##  $ educ        : Factor w/ 9 levels "1","2","3","4",..: 4 3 6 6 3 3 4 4 4 1 ...
    ##  $ marital     : Factor w/ 7 levels "A","D","M","P",..: 2 7 7 3 7 7 7 5 3 7 ...
    ##  $ occup       : Factor w/ 414 levels "`","000","007",..: 391 232 134 95 391 161 165 141 182 335 ...
    ##  $ military    : Factor w/ 3 levels "N","U","Y": 1 1 1 3 1 1 1 1 1 3 ...
    ##  $ codlit      : Factor w/ 170052 levels ";LARGE CELL LYMPHOMA    CHRONIC A FIB, DEMENTIA, DIABETES, POST STROKE SYNDROME ",..: 51019 48458 160364 139881 163228 125632 67582 48426 83578 62276 ...

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

    ## 'data.frame':    227829 obs. of  41 variables:
    ##  $ certno      : int  2017012363 2017019356 2017019357 2017019358 2017019359 2017026057 2017019361 2017019363 2017019367 2017019368 ...
    ##  $ dob         : Date, format: "1945-04-15" "1918-05-03" ...
    ##  $ dod         : Date, format: "2017-03-03" "2017-04-24" ...
    ##  $ lname       : chr  "VANRY" "BYERS" "BASKIN" "JOHNSON" ...
    ##  $ fname       : chr  "SYLVIA" "DOUGLAS" "SHIRLEY" "WILLARD" ...
    ##  $ mname       : Factor w/ 19569 levels "-","--","-VERNIE-",..: 3333 NA 5257 10253 NA 6253 11924 7373 5482 9328 ...
    ##  $ sex         : Factor w/ 2 levels "F","M": 1 2 1 2 1 1 1 2 1 2 ...
    ##  $ ssn         : chr  "537446055" "258429171" "539181252" "559307744" ...
    ##  $ attclass    : Factor w/ 9 levels "0","1","2","3",..: 8 2 2 3 2 2 2 3 2 2 ...
    ##  $ brgrace     : Factor w/ 20 levels "1","2","3","4",..: 1 1 1 1 1 1 1 1 1 1 ...
    ##  $ hispanic    : Factor w/ 2 levels "N","Y": 2 2 2 2 2 2 2 2 2 2 ...
    ##  $ manner      : Factor w/ 7 levels "Accident","Undetermined",..: 4 4 4 1 4 4 4 4 4 4 ...
    ##  $ rcounty     : Factor w/ 643 levels "ADA","ADAMS",..: 279 305 305 517 434 117 279 259 106 118 ...
    ##  $ rcity       : Factor w/ 2090 levels "4600 WELS","69006 LYON",..: 211 297 284 1133 677 1703 933 1015 1114 1939 ...
    ##  $ rstreet     : Factor w/ 186694 levels "#1 CONVALESCENT CENTER BLVD",..: 19429 3519 90183 31977 5763 146232 73794 137277 56202 163330 ...
    ##  $ resmatchcode: num  100 100 100 100 100 NA 100 100 100 100 ...
    ##  $ rstateFIPS  : Factor w/ 63 levels "AB","AK","AL",..: 58 58 58 58 58 58 58 58 58 58 ...
    ##  $ rzip        : Factor w/ 3141 levels "00000","00705",..: 2208 2530 2526 2297 2364 2420 2080 2282 2681 2641 ...
    ##  $ dstreet     : Factor w/ 66461 levels "-AT SEA","\"A PART OF THE FAMILY\" 2618 W 10TH",..: 65176 1285 NA 64551 63426 NA 66074 46802 19248 66079 ...
    ##  $ dcity       : Factor w/ 639 levels "ABERDEEN","ACME",..: 505 86 84 340 210 510 396 295 332 594 ...
    ##  $ dzip        : Factor w/ 947 levels "03282","06232",..: 226 517 516 308 368 414 241 299 678 628 ...
    ##  $ dcounty     : Factor w/ 40 levels "ADAMS","ASOTIN",..: 17 21 21 32 27 5 17 15 4 6 ...
    ##  $ dstateFIPS  : Factor w/ 1 level "WA": 1 1 1 1 1 1 1 1 1 1 ...
    ##  $ dplacelit   : Factor w/ 18 levels "DECEDENT'S HOME",..: 13 13 10 13 13 13 14 1 1 5 ...
    ##  $ dplacecode  : Factor w/ 10 levels "0","1","2","3",..: 6 6 5 6 6 6 2 1 1 8 ...
    ##  $ dthyr       : Factor w/ 9 levels "2003","2004",..: 9 9 9 9 9 9 9 9 9 9 ...
    ##  $ UCOD        : Factor w/ 2333 levels "A029","A044",..: 890 990 800 1156 985 983 911 911 315 977 ...
    ##  $ MCOD        : Factor w/ 119173 levels "A029 I714 N180",..: NA NA NA NA NA NA NA NA NA NA ...
    ##  $ educ        : Factor w/ 9 levels "<=8th grade",..: 4 3 6 6 3 3 4 4 4 1 ...
    ##  $ marital     : Factor w/ 7 levels "A","D","M","P",..: 2 7 7 3 7 7 7 5 3 7 ...
    ##  $ occup       : Factor w/ 414 levels "`","000","007",..: 391 232 134 95 391 161 165 141 182 335 ...
    ##  $ military    : Factor w/ 3 levels "N","U","Y": 1 1 1 3 1 1 1 1 1 3 ...
    ##  $ codlit      : Factor w/ 170052 levels ";LARGE CELL LYMPHOMA    CHRONIC A FIB, DEMENTIA, DIABETES, POST STROKE SYNDROME ",..: 51019 48458 160364 139881 163228 125632 67582 48426 83578 62276 ...
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
    ##  1st Qu.:2.004e+09   1st Qu.:1919-05-08   1st Qu.:2004-03-26  
    ##  Median :2.005e+09   Median :1927-07-23   Median :2005-11-19  
    ##  Mean   :2.006e+09   Mean   :1932-06-11   Mean   :2006-03-06  
    ##  3rd Qu.:2.008e+09   3rd Qu.:1942-04-13   3rd Qu.:2008-01-02  
    ##  Max.   :2.017e+09   Max.   :2017-08-08   Max.   :2017-08-21  
    ##                      NA's   :27                               
    ##     lname              fname               mname        sex       
    ##  Length:227829      Length:227829      MARIE  :  4675   F:114606  
    ##  Class :character   Class :character   LEE    :  4561   M:113223  
    ##  Mode  :character   Mode  :character   ANN    :  4104             
    ##                                        M      :  3828             
    ##                                        L      :  3419             
    ##                                        (Other):186770             
    ##                                        NA's   : 20472             
    ##      ssn               attclass         brgrace       hispanic  
    ##  Length:227829      1      :181979   1      :165175   N: 50208  
    ##  Class :character   2      : 31690   2      :  4645   Y:177621  
    ##  Mode  :character   3      :  6709   15     :  2579             
    ##                     7      :  5964   3      :  2369             
    ##                     6      :  1467   6      :  1138             
    ##                     9      :    13   (Other):  5898             
    ##                     (Other):     7   NA's   : 46025             
    ##           manner            rcounty            rcity       
    ##  Natural     :209380   KING     :55535   SEATTLE  : 21288  
    ##  Accident    : 12432   PIERCE   :26809   SPOKANE  : 11384  
    ##  Suicide     :  4064   SNOHOMISH:20595   TACOMA   : 11384  
    ##  Homicide    :  1099   SPOKANE  :18082   VANCOUVER:  9061  
    ##  Undetermined:   804   CLARK    :11931   EVERETT  :  5261  
    ##  (Other)     :     8   (Other)  :94657   (Other)  :169406  
    ##  NA's        :    42   NA's     :  220   NA's     :    45  
    ##                    rstreet        resmatchcode      rstateFIPS    
    ##  UNKNOWN               :   371   Min.   :  0.00   WA     :221968  
    ##  7500 SEWARD PARK AVE S:   217   1st Qu.:100.00   OR     :  2052  
    ##  4831 35TH AVE SW      :   215   Median :100.00   ID     :  1085  
    ##  534 BOYER AVE         :   213   Mean   : 95.53   CA     :   514  
    ##  13023 GREENWOOD AVE N :   187   3rd Qu.:100.00   AK     :   376  
    ##  19303 FREMONT AVE N   :   187   Max.   :100.00   (Other):  1833  
    ##  (Other)               :226439   NA's   :182      NA's   :     1  
    ##       rzip                                       dstreet      
    ##  98632  :  2644   FRANCISCAN HOSPICE HOUSE           :  1019  
    ##  98133  :  2357   12822 124TH LANE NE                :   318  
    ##  98902  :  2144   TRI-CITIES CHAPLAINCY HOSPICE HOUSE:   266  
    ##  98382  :  1953   12822 124TH LN NE                  :   155  
    ##  99205  :  1899   HOSPICE HOUSE                      :   126  
    ##  (Other):216768   (Other)                            : 73418  
    ##  NA's   :    64   NA's                               :152527  
    ##        dcity             dzip             dcounty      dstateFIPS 
    ##  SEATTLE  : 30438   98122  :  3976   KING     :63002   WA:227829  
    ##  SPOKANE  : 16414   98201  :  3841   PIERCE   :27351              
    ##  TACOMA   : 12648   98902  :  3599   SPOKANE  :20604              
    ##  VANCOUVER: 10824   98104  :  3400   SNOHOMISH:18716              
    ##  EVERETT  :  7240   98632  :  3320   CLARK    :12657              
    ##  (Other)  :150216   (Other):163680   THURSTON : 9107              
    ##  NA's     :    49   NA's   : 46013   (Other)  :76392              
    ##                        dplacelit       dplacecode        dthyr      
    ##  Hospital (inpatient)       :69621   4      :70042   2003   :45924  
    ##  Home                       :67619   0      :68079   2004   :44809  
    ##  Nursing home/long term care:62799   5      :63089   2008   :27889  
    ##  Other place                :11506   1      :11578   2009   :27751  
    ##  Hospice                    : 7392   7      : 7499   2007   :27169  
    ##  Emergency room             : 7215   3      : 7254   2006   :26485  
    ##  (Other)                    : 1677   (Other):  288   (Other):27802  
    ##       UCOD               MCOD                            educ      
    ##  C349   : 15380   C349 F179:  4091   H.S. grad/GED         :72704  
    ##  I251   : 15243   G309     :  3075   Unknown               :43838  
    ##  G309   : 12054   C349     :  3000   Some college          :30057  
    ##  I219   : 11713   I250     :  2219   Bachelors             :19838  
    ##  J449   : 10203   C509     :  2016   <=8th grade           :19172  
    ##  (Other):163132   (Other)  :211897   9-12th gr., no diploma:18954  
    ##  NA's   :   104   NA's     :  1531   (Other)               :23266  
    ##  marital       occup        military                        codlit      
    ##  A:  441   908    : 43764   N:160495   LUNG CANCER             :  2136  
    ##  D:35210   183    :  5326   U:  1153   ALZHEIMERS DEMENTIA     :  1060  
    ##  M:87655   290    :  4668   Y: 66181   COPD                    :   957  
    ##  P:   73   396    :  4050              PANCREATIC CANCER       :   937  
    ##  S:21756   150    :  3947              ASCVD                   :   926  
    ##  U:  995   (Other):161214              (Other)                 :221746  
    ##  W:81699   NA's   :  4860              NA's                    :    67  
    ##       age             age5cat                          LCOD      
    ##  Min.   :  0.00   <18yrs  :  3420   Heart Dis.           :52988  
    ##  1st Qu.: 64.00   18-29yrs:  3942   Other                :52966  
    ##  Median : 79.00   30-44yrs:  8462   Cancer               :50580  
    ##  Mean   : 73.74   45-64yrs: 42096   Stroke               :14756  
    ##  3rd Qu.: 87.00   65+ yrs :169882   Chronic Lwr Resp Dis.:13310  
    ##  Max.   :111.00   NA's    :    27   Alzheimers           :12470  
    ##  NA's   :27                         (Other)              :30759  
    ##                      injury                    substance     
    ##  MV - all               :  3388   Alcohol-induced   :  3357  
    ##  No injury              :215749   Drug-induced      :  4079  
    ##  Other injury           :  2110   No Substance abuse:220393  
    ##  Unintentional fall     :  3082                              
    ##  Unintentional poisoning:  3500                              
    ##                                                              
    ##                                                              
    ##         residence           raceethnic5       raceethnic6    
    ##  Out of state:  5703   AIAN NH    :  2298   White NH:163709  
    ##  WA resident :221968   Asian/PI NH:  5847   Unknown : 46025  
    ##  NA's        :   158   Black NH   :  4583   Asian   :  5240  
    ##                        Hispanic   :  4270   Black NH:  4583  
    ##                        Other      :  1097   Hispanic:  4270  
    ##                        Unknown    : 46025   AIAN NH :  2298  
    ##                        White NH   :163709   (Other) :  1704

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

    ## 'data.frame':    63002 obs. of  41 variables:
    ##  $ certno.k      : int  2017012363 2017019361 2017025187 2017025188 2017025189 2017025190 2017025192 2017025196 2017025197 2017007506 ...
    ##  $ dob.k         : Date, format: "1945-04-15" "1928-02-04" ...
    ##  $ dod.k         : Date, format: "2017-03-03" "2017-04-19" ...
    ##  $ lname.k       : chr  "VANRY" "CALLERY" "BURNETT" "LEE" ...
    ##  $ fname.k       : chr  "SYLVIA" "ROSALIE" "CHARLES" "DOUGLAS" ...
    ##  $ mname.k       : Factor w/ 19569 levels "-","--","-VERNIE-",..: 3333 11924 18203 9110 NA 15917 434 14700 18516 14939 ...
    ##  $ sex.k         : Factor w/ 2 levels "F","M": 1 1 2 2 1 1 2 1 2 1 ...
    ##  $ ssn.k         : chr  "537446055" "476289831" "527366846" "019488823" ...
    ##  $ attclass.k    : Factor w/ 9 levels "0","1","2","3",..: 8 2 2 8 2 2 2 2 2 3 ...
    ##  $ brgrace.k     : Factor w/ 20 levels "1","2","3","4",..: 1 1 1 1 10 1 1 1 5 1 ...
    ##  $ hispanic.k    : Factor w/ 2 levels "N","Y": 2 2 2 2 2 2 2 2 2 2 ...
    ##  $ manner.k      : Factor w/ 7 levels "Accident","Undetermined",..: 4 4 4 4 4 4 4 4 4 4 ...
    ##  $ rcounty.k     : Factor w/ 643 levels "ADA","ADAMS",..: 279 279 279 279 517 279 279 279 279 279 ...
    ##  $ rcity.k       : Factor w/ 2090 levels "4600 WELS","69006 LYON",..: 211 933 2063 1556 1089 124 466 1691 933 1164 ...
    ##  $ rstreet.k     : Factor w/ 186694 levels "#1 CONVALESCENT CENTER BLVD",..: 19429 73794 55478 87264 62953 83392 19898 87167 27381 95725 ...
    ##  $ resmatchcode.k: num  100 100 100 100 100 100 100 100 100 100 ...
    ##  $ rstateFIPS.k  : Factor w/ 63 levels "AB","AK","AL",..: 58 58 58 58 58 58 58 58 58 58 ...
    ##  $ rzip.k        : Factor w/ 3141 levels "00000","00705",..: 2208 2080 2125 2107 2086 2044 2217 2219 2077 2092 ...
    ##  $ dstreet.k     : Factor w/ 66461 levels "-AT SEA","\"A PART OF THE FAMILY\" 2618 W 10TH",..: 65176 66074 NA 8868 NA 64640 NA NA 9376 32752 ...
    ##  $ dcity.k       : Factor w/ 639 levels "ABERDEEN","ACME",..: 505 396 274 274 505 35 65 505 268 354 ...
    ##  $ dzip.k        : Factor w/ 947 levels "03282","06232",..: 226 241 126 126 206 94 225 197 122 133 ...
    ##  $ dcounty.k     : Factor w/ 40 levels "ADAMS","ASOTIN",..: 17 17 17 17 17 17 17 17 17 17 ...
    ##  $ dstateFIPS.k  : Factor w/ 1 level "WA": 1 1 1 1 1 1 1 1 1 1 ...
    ##  $ dplacelit.k   : Factor w/ 18 levels "DECEDENT'S HOME",..: 13 14 10 5 10 13 10 10 1 3 ...
    ##  $ dplacecode.k  : Factor w/ 10 levels "0","1","2","3",..: 6 2 5 8 5 6 5 5 1 1 ...
    ##  $ dthyr.k       : Factor w/ 9 levels "2003","2004",..: 9 9 9 9 9 9 9 9 9 9 ...
    ##  $ UCOD.k        : Factor w/ 2333 levels "A029","A044",..: 890 911 1177 1017 354 651 223 1013 168 1244 ...
    ##  $ MCOD.k        : Factor w/ 119173 levels "A029 I714 N180",..: NA NA NA NA NA NA NA NA NA NA ...
    ##  $ educ.k        : Factor w/ 9 levels "<=8th grade",..: 4 4 8 1 5 7 6 7 3 6 ...
    ##  $ marital.k     : Factor w/ 7 levels "A","D","M","P",..: 2 7 3 2 3 2 3 3 3 5 ...
    ##  $ occup.k       : Factor w/ 414 levels "`","000","007",..: 391 165 77 131 391 94 286 64 368 131 ...
    ##  $ military.k    : Factor w/ 3 levels "N","U","Y": 1 1 3 3 1 1 3 1 1 1 ...
    ##  $ codlit.k      : Factor w/ 170052 levels ";LARGE CELL LYMPHOMA    CHRONIC A FIB, DEMENTIA, DIABETES, POST STROKE SYNDROME ",..: 51019 67582 11122 4642 148961 9041 98444 11397 104515 118826 ...
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

    ## 'data.frame':    58862 obs. of  41 variables:
    ##  $ certno.k      : int  2017012363 2017019361 2017025187 2017025188 2017025189 2017025190 2017025192 2017025196 2017025197 2017007506 ...
    ##  $ dob.k         : Date, format: "1945-04-15" "1928-02-04" ...
    ##  $ dod.k         : Date, format: "2017-03-03" "2017-04-19" ...
    ##  $ lname.k       : chr  "VANRY" "CALLERY" "BURNETT" "LEE" ...
    ##  $ fname.k       : chr  "SYLVIA" "ROSALIE" "CHARLES" "DOUGLAS" ...
    ##  $ mname.k       : Factor w/ 19569 levels "-","--","-VERNIE-",..: 3333 11924 18203 9110 NA 15917 434 14700 18516 14939 ...
    ##  $ sex.k         : Factor w/ 2 levels "F","M": 1 1 2 2 1 1 2 1 2 1 ...
    ##  $ ssn.k         : chr  "537446055" "476289831" "527366846" "019488823" ...
    ##  $ attclass.k    : Factor w/ 9 levels "0","1","2","3",..: 8 2 2 8 2 2 2 2 2 3 ...
    ##  $ brgrace.k     : Factor w/ 20 levels "1","2","3","4",..: 1 1 1 1 10 1 1 1 5 1 ...
    ##  $ hispanic.k    : Factor w/ 2 levels "N","Y": 2 2 2 2 2 2 2 2 2 2 ...
    ##  $ manner.k      : Factor w/ 7 levels "Accident","Undetermined",..: 4 4 4 4 4 4 4 4 4 4 ...
    ##  $ rcounty.k     : Factor w/ 643 levels "ADA","ADAMS",..: 279 279 279 279 517 279 279 279 279 279 ...
    ##  $ rcity.k       : Factor w/ 2090 levels "4600 WELS","69006 LYON",..: 211 933 2063 1556 1089 124 466 1691 933 1164 ...
    ##  $ rstreet.k     : Factor w/ 186694 levels "#1 CONVALESCENT CENTER BLVD",..: 19429 73794 55478 87264 62953 83392 19898 87167 27381 95725 ...
    ##  $ resmatchcode.k: num  100 100 100 100 100 100 100 100 100 100 ...
    ##  $ rstateFIPS.k  : Factor w/ 63 levels "AB","AK","AL",..: 58 58 58 58 58 58 58 58 58 58 ...
    ##  $ rzip.k        : Factor w/ 3141 levels "00000","00705",..: 2208 2080 2125 2107 2086 2044 2217 2219 2077 2092 ...
    ##  $ dstreet.k     : Factor w/ 66461 levels "-AT SEA","\"A PART OF THE FAMILY\" 2618 W 10TH",..: 65176 66074 NA 8868 NA 64640 NA NA 9376 32752 ...
    ##  $ dcity.k       : Factor w/ 639 levels "ABERDEEN","ACME",..: 505 396 274 274 505 35 65 505 268 354 ...
    ##  $ dzip.k        : Factor w/ 947 levels "03282","06232",..: 226 241 126 126 206 94 225 197 122 133 ...
    ##  $ dcounty.k     : Factor w/ 40 levels "ADAMS","ASOTIN",..: 17 17 17 17 17 17 17 17 17 17 ...
    ##  $ dstateFIPS.k  : Factor w/ 1 level "WA": 1 1 1 1 1 1 1 1 1 1 ...
    ##  $ dplacelit.k   : Factor w/ 18 levels "DECEDENT'S HOME",..: 13 14 10 5 10 13 10 10 1 3 ...
    ##  $ dplacecode.k  : Factor w/ 10 levels "0","1","2","3",..: 6 2 5 8 5 6 5 5 1 1 ...
    ##  $ dthyr.k       : Factor w/ 9 levels "2003","2004",..: 9 9 9 9 9 9 9 9 9 9 ...
    ##  $ UCOD.k        : Factor w/ 2333 levels "A029","A044",..: 890 911 1177 1017 354 651 223 1013 168 1244 ...
    ##  $ MCOD.k        : Factor w/ 119173 levels "A029 I714 N180",..: NA NA NA NA NA NA NA NA NA NA ...
    ##  $ educ.k        : Factor w/ 9 levels "<=8th grade",..: 4 4 8 1 5 7 6 7 3 6 ...
    ##  $ marital.k     : Factor w/ 7 levels "A","D","M","P",..: 2 7 3 2 3 2 3 3 3 5 ...
    ##  $ occup.k       : Factor w/ 414 levels "`","000","007",..: 391 165 77 131 391 94 286 64 368 131 ...
    ##  $ military.k    : Factor w/ 3 levels "N","U","Y": 1 1 3 3 1 1 3 1 1 1 ...
    ##  $ codlit.k      : Factor w/ 170052 levels ";LARGE CELL LYMPHOMA    CHRONIC A FIB, DEMENTIA, DIABETES, POST STROKE SYNDROME ",..: 51019 67582 11122 4642 148961 9041 98444 11397 104515 118826 ...
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
    ##  Min.   :2.003e+09   Min.   :1894-12-16   Min.   :2003-01-01  
    ##  1st Qu.:2.004e+09   1st Qu.:1919-01-01   1st Qu.:2004-03-16  
    ##  Median :2.005e+09   Median :1927-03-05   Median :2005-10-25  
    ##  Mean   :2.006e+09   Mean   :1932-09-04   Mean   :2006-02-16  
    ##  3rd Qu.:2.007e+09   3rd Qu.:1943-03-05   3rd Qu.:2007-12-17  
    ##  Max.   :2.017e+09   Max.   :2017-08-08   Max.   :2017-08-20  
    ##                      NA's   :9                                
    ##    lname.k            fname.k             mname.k      sex.k    
    ##  Length:58862       Length:58862       M      : 1247   F:29940  
    ##  Class :character   Class :character   MARIE  : 1129   M:28922  
    ##  Mode  :character   Mode  :character   ANN    : 1008            
    ##                                        L      :  992            
    ##                                        A      :  990            
    ##                                        (Other):46749            
    ##                                        NA's   : 6747            
    ##     ssn.k             attclass.k      brgrace.k     hispanic.k
    ##  Length:58862       1      :48753   1      :39450   N:13134   
    ##  Class :character   2      : 7554   2      : 2520   Y:45728   
    ##  Mode  :character   7      : 1909   5      :  737             
    ##                     3      :  502   7      :  651             
    ##                     6      :  139   6      :  630             
    ##                     4      :    2   (Other): 2716             
    ##                     (Other):    3   NA's   :12158             
    ##          manner.k         rcounty.k            rcity.k     
    ##  Natural     :54014   KING     :51133   SEATTLE    :20258  
    ##  Accident    : 3302   SNOHOMISH: 3035   BELLEVUE   : 3415  
    ##  Suicide     :  996   PIERCE   : 1478   RENTON     : 2979  
    ##  Homicide    :  330   KITSAP   :  531   KENT       : 2767  
    ##  Undetermined:  201   CLALLAM  :  284   SHORELINE  : 2369  
    ##  (Other)     :    0   THURSTON :  250   FEDERAL WAY: 2342  
    ##  NA's        :   19   (Other)  : 2151   (Other)    :24732  
    ##                   rstreet.k     resmatchcode.k  rstateFIPS.k  
    ##  7500 SEWARD PARK AVE S:  217   Min.   : 95    WA     :58858  
    ##  4831 35TH AVE SW      :  215   1st Qu.:100    AK     :    1  
    ##  13023 GREENWOOD AVE N :  187   Median :100    NY     :    1  
    ##  19303 FREMONT AVE N   :  181   Mean   :100    OR     :    1  
    ##  1122 S 216TH ST       :  140   3rd Qu.:100    TX     :    1  
    ##  2717 DEXTER AVE N     :  116   Max.   :100    AB     :    0  
    ##  (Other)               :57806                  (Other):    0  
    ##      rzip.k                    dstreet.k            dcity.k     
    ##  98133  : 2167   12822 124TH LANE NE:  299   SEATTLE    :28181  
    ##  98118  : 1596   12822 124TH LN NE  :  146   KIRKLAND   : 4066  
    ##  98198  : 1513   2424 156TH AVE NE  :   38   BELLEVUE   : 4025  
    ##  98003  : 1476   1122 S 216TH ST    :   37   RENTON     : 3315  
    ##  98125  : 1312   4430 TALBOT RD S   :   32   FEDERAL WAY: 2885  
    ##  98155  : 1222   (Other)            :16843   (Other)    :16378  
    ##  (Other):49576   NA's               :41467   NA's       :   12  
    ##      dzip.k        dcounty.k     dstateFIPS.k
    ##  98122  : 3744   KING   :58862   WA:58862    
    ##  98034  : 2973   ADAMS  :    0               
    ##  98104  : 2946   ASOTIN :    0               
    ##  98133  : 2939   BENTON :    0               
    ##  98004  : 1916   CHELAN :    0               
    ##  (Other):32165   CLALLAM:    0               
    ##  NA's   :12179   (Other):    0               
    ##                       dplacelit.k     dplacecode.k      dthyr.k     
    ##  Hospital (inpatient)       :21933   4      :22050   2003   :12129  
    ##  Nursing home/long term care:16394   5      :16454   2004   :11772  
    ##  Home                       :15426   0      :15501   2008   : 7122  
    ##  Other place                : 2286   1      : 2308   2009   : 6985  
    ##  Hospice                    : 1576   7      : 1589   2007   : 6901  
    ##  Emergency room             :  919   3      :  921   2006   : 6852  
    ##  (Other)                    :  328   (Other):   39   (Other): 7101  
    ##      UCOD.k            MCOD.k                         educ.k     
    ##  C349   : 3606   C349 F179:  880   H.S. grad/GED         :17052  
    ##  I251   : 3411   I250     :  775   Unknown               :12239  
    ##  G309   : 3130   C349     :  747   Some college          : 8069  
    ##  I219   : 2468   G309     :  645   Bachelors             : 6997  
    ##  I250   : 2201   C259     :  506   <=8th grade           : 4077  
    ##  (Other):44017   (Other)  :54985   9-12th gr., no diploma: 3699  
    ##  NA's   :   29   NA's     :  324   (Other)               : 6729  
    ##  marital.k    occup.k      military.k                     codlit.k    
    ##  A:   89   908    :10193   N:42647    LUNG CANCER             :  397  
    ##  D: 9079   557    : 1632   U:  417    PROBABLE ASCVD          :  342  
    ##  M:21523   183    : 1590   Y:15798    ASCVD                   :  302  
    ##  P:   27   290    : 1387              ALZHEIMERS DEMENTIA     :  239  
    ##  S: 7155   150    : 1153              PANCREATIC CANCER       :  235  
    ##  U:  354   (Other):41523              (Other)                 :57320  
    ##  W:20635   NA's   : 1384              NA's                    :   27  
    ##      age.k           age5cat.k                      LCOD.k     
    ##  Min.   :  0.00   <18yrs  : 1096   Other               :15115  
    ##  1st Qu.: 63.00   18-29yrs: 1063   Cancer              :13177  
    ##  Median : 79.00   30-44yrs: 2325   Heart Dis.          :12739  
    ##  Mean   : 73.46   45-64yrs:11208   Stroke              : 4112  
    ##  3rd Qu.: 87.00   65+ yrs :43161   Alzheimers          : 3274  
    ##  Max.   :110.00   NA's    :    9   Injury-unintentional: 3105  
    ##  NA's   :9                         (Other)             : 7340  
    ##                     injury.k                 substance.k   
    ##  MV - all               :  802   Alcohol-induced   :  791  
    ##  No injury              :55749   Drug-induced      : 1034  
    ##  Other injury           :  503   No Substance abuse:57037  
    ##  Unintentional fall     :  926                             
    ##  Unintentional poisoning:  882                             
    ##                                                            
    ##                                                            
    ##        residence.k        raceethnic5.k    raceethnic6.k  
    ##  Out of state:    4   AIAN NH    :  416   White NH:39107  
    ##  WA resident :58858   Asian/PI NH: 3299   Unknown :12158  
    ##                       Black NH   : 2495   Asian   : 3052  
    ##                       Hispanic   : 1001   Black NH: 2495  
    ##                       Other      :  386   Hispanic: 1001  
    ##                       Unknown    :12158   AIAN NH :  416  
    ##                       White NH   :39107   (Other) :  633

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
    ##  Min.   :2.003e+09   Length:335         Length:335        
    ##  1st Qu.:2.004e+09   Class :character   Class :character  
    ##  Median :2.006e+09   Mode  :character   Mode  :character  
    ##  Mean   :2.006e+09                                        
    ##  3rd Qu.:2.007e+09                                        
    ##  Max.   :2.017e+09                                        
    ##                                                           
    ##      dob.h                age.h         mname.h         
    ##  Min.   :1913-02-27   Min.   :19.00   Length:335        
    ##  1st Qu.:1950-09-02   1st Qu.:41.00   Class :character  
    ##  Median :1957-09-29   Median :48.00   Mode  :character  
    ##  Mean   :1957-12-19   Mean   :48.22                     
    ##  3rd Qu.:1964-10-26   3rd Qu.:56.00                     
    ##  Max.   :1987-07-12   Max.   :93.00                     
    ##                                                         
    ##      dod.h                              placeofdeath.h deathaddr.h       
    ##  Min.   :1991-09-01   HARBORVIEW MEDICAL CENTER: 58    Length:335        
    ##  1st Qu.:2004-12-11   OUTDOORS                 : 12    Class :character  
    ##  Median :2006-07-15   VEHICLE                  : 10    Mode  :character  
    ##  Mean   :2006-10-16   RESIDENCE                :  9                      
    ##  3rd Qu.:2007-12-29   HOSPITAL INPATIENT       :  8                      
    ##  Max.   :2063-01-01   (Other)                  :163                      
    ##  NA's   :16           NA's                     : 75                      
    ##       deathcity.h      dzip.h    eventaddr.h             eventcity.h 
    ##  SEATTLE    :260   98104  : 99   Length:335         SEATTLE    :236  
    ##  KENT       : 13   98101  : 20   Class :character   KENT       : 14  
    ##  RENTON     : 11   98122  : 15   Mode  :character   RENTON     : 11  
    ##  FEDERAL WAY:  7   98133  : 14                      TUKWILA    : 10  
    ##  TUKWILA    :  7   98107  : 11                      FEDERAL WAY:  7  
    ##  AUBURN     :  6   (Other):174                      (Other)    : 49  
    ##  (Other)    : 31   NA's   :  2                      NA's       :  8  
    ##    dcounty.k     attclass.k  sex.k     brgrace.k   hispanic.k
    ##  KING   :335   2      :280   F: 59   1      :212   N: 37     
    ##  ADAMS  :  0   1      : 53   M:276   2      : 58   Y:298     
    ##  ASOTIN :  0   6      :  1           3      : 22             
    ##  BENTON :  0   7      :  1           15     : 21             
    ##  CHELAN :  0   0      :  0           99     :  4             
    ##  CLALLAM:  0   3      :  0           (Other): 12             
    ##  (Other):  0   (Other):  0           NA's   :  6             
    ##          manner.k       rcounty.k      rcity.k   
    ##  Accident    :138   KING     :209   SEATTLE:127  
    ##  Natural     :138   UNKNOWN  : 45   UNKNOWN: 61  
    ##  Suicide     : 23   SNOHOMISH: 12   UNK    : 13  
    ##  Homicide    : 19   UNK      : 12   KENT   : 10  
    ##  Undetermined: 16   PIERCE   : 11   BURIEN :  7  
    ##  (Other)     :  0   (Other)  : 35   (Other):106  
    ##  NA's        :  1   NA's     : 11   NA's   : 11  
    ##                        rstreet.k    rstateFIPS.k        rzip.k   
    ##  UNKNOWN                    : 57   WA     :254   99999     : 89  
    ##  HOMELESS                   : 21   ZZ     : 60   98104     : 22  
    ##  NO PERMANENT ADDRESS       : 11   CA     :  6   99999-9999: 16  
    ##  NO PERMANENT PLACE OF ABODE:  7   OR     :  5   98101     : 12  
    ##  UNK                        :  6   AK     :  2   98032     :  7  
    ##  77 S WASHINGTON ST         :  5   GA     :  1   98121     :  7  
    ##  (Other)                    :228   (Other):  7   (Other)   :182  
    ##         dcity.k                         dplacelit.k   dplacecode.k
    ##  SEATTLE    :262   Other place                :191   1      :192  
    ##  KENT       : 13   Hospital (inpatient)       : 88   4      : 89  
    ##  RENTON     : 11   Home                       : 27   0      : 27  
    ##  FEDERAL WAY:  7   Emergency room             : 14   3      : 16  
    ##  AUBURN     :  6   Nursing home/long term care:  9   5      :  9  
    ##  BELLEVUE   :  6   Hospice                    :  2   7      :  2  
    ##  (Other)    : 30   (Other)                    :  4   (Other):  0  
    ##     dthyr.k       UCOD.k          MCOD.k                       educ.k   
    ##  2004   :83   X420   : 54   I250     :  8   H.S. grad/GED         :112  
    ##  2006   :62   X440   : 32   I119     :  7   Unknown               :104  
    ##  2005   :52   I250   : 23   I250 I119:  4   9-12th gr., no diploma: 62  
    ##  2007   :52   K703   : 18   K703     :  3   Some college          : 33  
    ##  2009   :39   I119   : 17   R99      :  3   Bachelors             : 10  
    ##  2008   :38   (Other):190   (Other)  :305   <=8th grade           :  8  
    ##  (Other): 9   NA's   :  1   NA's     :  5   (Other)               :  6  
    ##  marital.k    occup.k       age5cat.k                         LCOD.k   
    ##  A:  1     999    : 85   <18yrs  :  0   Injury-unintentional     :133  
    ##  D:108     980    : 20   18-29yrs: 27   Other                    : 77  
    ##  M: 28     982    : 18   30-44yrs: 85   Heart Dis.               : 50  
    ##  P:  0     998    : 11   45-64yrs:194   Suicide-all              : 23  
    ##  S:131     997    : 10   65+ yrs : 28   Chronic Liver dis./cirrh.: 21  
    ##  U: 60     (Other):181   NA's    :  1   Cancer                   :  9  
    ##  W:  7     NA's   : 10                  (Other)                  : 22  
    ##                     injury.k               substance.k        residence.k 
    ##  MV - all               : 18   Alcohol-induced   : 29   Out of state: 21  
    ##  No injury              :200   Drug-induced      :100   WA resident :254  
    ##  Other injury           : 13   No Substance abuse:206   NA's        : 60  
    ##  Unintentional fall     :  8                                              
    ##  Unintentional poisoning: 96                                              
    ##                                                                           
    ##                                                                           
    ##      raceethnic5.k  raceethnic6.k
    ##  AIAN NH    : 22   White NH:206  
    ##  Asian/PI NH:  6   Black NH: 56  
    ##  Black NH   : 56   Hispanic: 32  
    ##  Hispanic   : 32   AIAN NH : 22  
    ##  Other      :  7   Other   :  7  
    ##  Unknown    :  6   Unknown :  6  
    ##  White NH   :206   (Other) :  6  
    ##                                                          codlit.k  
    ##  ASCVD                                                       :  7  
    ##  HYPERTENSIVE CARDIOVASCULAR DISEASE                         :  4  
    ##  HYPERTENSIVE AND ASCVD                                      :  3  
    ##  HYPERTENSIVE AND ATHEROSCLEROTIC CARDIOVASCULAR DISEASE     :  3  
    ##  ACUTE BACTERIAL BRONCHOPNEUMONIA    HYPERTENSIVE AND ASCVD  :  2  
    ##  (Other)                                                     :315  
    ##  NA's                                                        :  1  
    ##  military.k
    ##  N:228     
    ##  U: 39     
    ##  Y: 68     
    ##            
    ##            
    ##            
    ## 

``` r
str(homelessfinal)
```

    ## 'data.frame':    335 obs. of  42 variables:
    ##  $ certno.k      : int  2004023773 2005056470 2005063775 2004006096 2006040788 2004004628 2008061185 2004017739 2005081423 2005052126 ...
    ##  $ lname.h       : chr  "ALLEN" "ALSTON" "ANAGICK" "ANDERSON" ...
    ##  $ fname.h       : chr  "RONALD" "KAMAL" "MICHAEL" "GARY" ...
    ##  $ dob.h         : Date, format: "1940-08-07" "1983-11-08" ...
    ##  $ age.h         : int  63 21 39 57 69 50 56 78 33 55 ...
    ##  $ mname.h       : chr  "FRANK" "RAHMAN MARLEY" "PETER" "SCOTT" ...
    ##  $ dod.h         : Date, format: "2004-06-29" "2005-05-11" ...
    ##  $ placeofdeath.h: Factor w/ 349 levels "\"TENT CITY\"",..: NA 261 123 NA 143 NA 123 NA NA 123 ...
    ##  $ deathaddr.h   : chr  "HARBORVIEW MEDICAL CENTER" "33819 26TH AVENUE SW" "325 NINTH AVENUE" "ALASKAN WAY & BLANCHARD" ...
    ##  $ deathcity.h   : Factor w/ 32 levels "AUBURN","BELLEVUE",..: 25 10 25 25 25 13 25 25 25 25 ...
    ##  $ dzip.h        : Factor w/ 74 levels "98001","98002",..: 38 12 38 51 53 19 38 38 46 38 ...
    ##  $ eventaddr.h   : chr  "325 9TH AVE (HMC)" "33819 26TH AVENUE SW" "1521 15TH AVE." "ALASKAN WAY & BLANCHARD" ...
    ##  $ eventcity.h   : Factor w/ 60 levels "ABERDEEN","ACME",..: 45 17 45 45 45 24 45 45 45 45 ...
    ##  $ dcounty.k     : Factor w/ 40 levels "ADAMS","ASOTIN",..: 17 17 17 17 17 17 17 17 17 17 ...
    ##  $ attclass.k    : Factor w/ 9 levels "0","1","2","3",..: 2 3 3 3 2 3 2 2 3 3 ...
    ##  $ sex.k         : Factor w/ 2 levels "F","M": 2 2 2 2 2 2 1 2 1 2 ...
    ##  $ brgrace.k     : Factor w/ 20 levels "1","2","3","4",..: 1 2 3 1 1 1 1 1 1 1 ...
    ##  $ hispanic.k    : Factor w/ 2 levels "N","Y": 2 2 2 2 2 2 2 2 2 2 ...
    ##  $ manner.k      : Factor w/ 7 levels "Accident","Undetermined",..: 4 3 1 1 4 1 4 1 1 2 ...
    ##  $ rcounty.k     : Factor w/ 643 levels "ADA","ADAMS",..: 279 279 13 559 279 279 279 279 279 517 ...
    ##  $ rcity.k       : Factor w/ 2090 levels "4600 WELS","69006 LYON",..: 1691 598 47 1357 1691 1684 1691 1691 466 1183 ...
    ##  $ rstreet.k     : Factor w/ 186694 levels "#1 CONVALESCENT CENTER BLVD",..: 186179 59939 108726 129940 30643 73564 136112 121746 57721 31104 ...
    ##  $ rstateFIPS.k  : Factor w/ 63 levels "AB","AK","AL",..: 58 58 2 58 58 58 58 58 58 58 ...
    ##  $ rzip.k        : Factor w/ 3141 levels "00000","00705",..: 2186 2065 2932 2516 2188 2217 2145 2143 2217 2055 ...
    ##  $ dcity.k       : Factor w/ 639 levels "ABERDEEN","ACME",..: 505 187 505 505 505 268 505 505 505 505 ...
    ##  $ dplacelit.k   : Factor w/ 18 levels "DECEDENT'S HOME",..: 6 17 6 17 6 17 6 6 17 6 ...
    ##  $ dplacecode.k  : Factor w/ 10 levels "0","1","2","3",..: 5 2 5 2 5 2 5 5 2 5 ...
    ##  $ dthyr.k       : Factor w/ 9 levels "2003","2004",..: 2 3 3 2 4 2 6 2 3 3 ...
    ##  $ UCOD.k        : Factor w/ 2333 levels "A029","A044",..: 1342 2256 2138 2215 1158 2213 1008 1966 2029 2289 ...
    ##  $ MCOD.k        : Factor w/ 119173 levels "A029 I714 N180",..: 100763 111947 110420 112195 99608 112230 89095 4921 110460 110656 ...
    ##  $ educ.k        : Factor w/ 9 levels "<=8th grade",..: 9 3 2 2 9 3 3 4 3 4 ...
    ##  $ marital.k     : Factor w/ 7 levels "A","D","M","P",..: 5 5 5 5 6 2 2 3 5 2 ...
    ##  $ occup.k       : Factor w/ 414 levels "`","000","007",..: 414 360 360 NA 131 406 414 51 169 170 ...
    ##  $ age5cat.k     : Factor w/ 5 levels "<18yrs","18-29yrs",..: 4 2 3 4 5 4 4 5 3 4 ...
    ##  $ LCOD.k        : Factor w/ 11 levels "Alzheimers","Cancer",..: 3 9 8 8 4 8 10 8 8 9 ...
    ##  $ injury.k      : Factor w/ 5 levels "MV - all","No injury",..: 2 2 4 5 2 5 2 1 1 2 ...
    ##  $ substance.k   : Factor w/ 3 levels "Alcohol-induced",..: 1 3 3 2 3 2 3 3 3 3 ...
    ##  $ residence.k   : Factor w/ 2 levels "Out of state",..: 2 2 1 2 2 2 2 2 2 2 ...
    ##  $ raceethnic5.k : Factor w/ 7 levels "AIAN NH","Asian/PI NH",..: 7 3 1 7 7 7 7 7 7 7 ...
    ##  $ raceethnic6.k : Factor w/ 8 levels "AIAN NH","Asian",..: 8 3 1 8 8 8 8 8 8 8 ...
    ##  $ codlit.k      : Factor w/ 170052 levels ";LARGE CELL LYMPHOMA    CHRONIC A FIB, DEMENTIA, DIABETES, POST STROKE SYNDROME ",..: 25580 84562 48776 3882 147872 3837 127552 129605 158181 49013 ...
    ##  $ military.k    : Factor w/ 3 levels "N","U","Y": 2 1 1 1 2 1 1 3 1 3 ...

``` r
a <- table(homelessfinal$injury.k)
a
```

    ## 
    ##                MV - all               No injury            Other injury 
    ##                      18                     200                      13 
    ##      Unintentional fall Unintentional poisoning 
    ##                       8                      96

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

write_csv(h, "C:/Users/mbg0303/Documents/IntroDSCapstone/h.csv")
write_csv(wh, "C:/Users/mbg0303/Documents/IntroDSCapstone/wh.csv")

EDAdf <- rbind(h, wh)
EDAdf$status <- as.factor(EDAdf$status)
EDAdf$dplacecode <- factor(EDAdf$dplacecode, levels = c("0", "1", "2", "3", 
    "4", "5", "6", "7", "8", "9"), labels = c("Home", "Other", "In transport", 
    "ER", "Hospital inpatient", "Nursing home/Longterm care", "Hospital", "Hospice", 
    "Other person's home", "Unknown"))
summary(EDAdf)
```

    ##      certno             dcounty         attclass     sex      
    ##  Min.   :2.003e+09   KING   :59197   1      :48806   F:29999  
    ##  1st Qu.:2.004e+09   ADAMS  :    0   2      : 7834   M:29198  
    ##  Median :2.005e+09   ASOTIN :    0   7      : 1910            
    ##  Mean   :2.006e+09   BENTON :    0   3      :  502            
    ##  3rd Qu.:2.007e+09   CHELAN :    0   6      :  140            
    ##  Max.   :2.017e+09   CLALLAM:    0   4      :    2            
    ##                      (Other):    0   (Other):    3            
    ##     brgrace      hispanic           manner           rcounty     
    ##  1      :39662   N:13171   Natural     :54152   KING     :51342  
    ##  2      : 2578   Y:46026   Accident    : 3440   SNOHOMISH: 3047  
    ##  5      :  737             Suicide     : 1019   PIERCE   : 1489  
    ##  7      :  651             Homicide    :  349   KITSAP   :  534  
    ##  6      :  631             Undetermined:  217   CLALLAM  :  284  
    ##  (Other): 2774             (Other)     :    0   (Other)  : 2490  
    ##  NA's   :12164             NA's        :   20   NA's     :   11  
    ##        rcity         rstateFIPS         rzip               dcity      
    ##  SEATTLE  :20385   WA     :59112   98133  : 2173   SEATTLE    :28443  
    ##  BELLEVUE : 3421   ZZ     :   60   98118  : 1600   KIRKLAND   : 4069  
    ##  RENTON   : 2986   CA     :    6   98198  : 1518   BELLEVUE   : 4031  
    ##  KENT     : 2777   OR     :    6   98003  : 1476   RENTON     : 3326  
    ##  SHORELINE: 2373   AK     :    3   98125  : 1318   FEDERAL WAY: 2892  
    ##  (Other)  :27244   TX     :    2   98155  : 1227   (Other)    :16424  
    ##  NA's     :   11   (Other):    8   (Other):49885   NA's       :   12  
    ##                       dplacecode        dthyr            UCOD      
    ##  Hospital inpatient        :22139   2003   :12134   C349   : 3610  
    ##  Nursing home/Longterm care:16463   2004   :11855   I251   : 3413  
    ##  Home                      :15528   2008   : 7160   G309   : 3130  
    ##  Other                     : 2500   2009   : 7024   I219   : 2472  
    ##  Hospice                   : 1591   2007   : 6953   I250   : 2224  
    ##  ER                        :  937   2006   : 6914   (Other):44318  
    ##  (Other)                   :   39   (Other): 7157   NA's   :   30  
    ##                      educ       marital     occupcode         age5cat     
    ##  H.S. grad/GED         :17164   A:   90   908    :10202   <18yrs  : 1096  
    ##  Unknown               :12343   D: 9187   557    : 1634   18-29yrs: 1090  
    ##  Some college          : 8102   M:21551   183    : 1590   30-44yrs: 2410  
    ##  Bachelors             : 7007   P:   27   290    : 1390   45-64yrs:11402  
    ##  <=8th grade           : 4085   S: 7286   150    : 1153   65+ yrs :43189  
    ##  9-12th gr., no diploma: 3761   U:  414   (Other):41834   NA's    :   10  
    ##  (Other)               : 6735   W:20642   NA's   : 1394                   
    ##                    LCOD                           injury     
    ##  Other               :15192   MV - all               :  820  
    ##  Cancer              :13186   No injury              :55949  
    ##  Heart Dis.          :12789   Other injury           :  516  
    ##  Stroke              : 4115   Unintentional fall     :  934  
    ##  Alzheimers          : 3274   Unintentional poisoning:  978  
    ##  Injury-unintentional: 3238                                  
    ##  (Other)             : 7403                                  
    ##               substance            residence          raceethnic5   
    ##  Alcohol-induced   :  820   Out of state:   25   AIAN NH    :  438  
    ##  Drug-induced      : 1134   WA resident :59112   Asian/PI NH: 3305  
    ##  No Substance abuse:57243   NA's        :   60   Black NH   : 2551  
    ##                                                  Hispanic   : 1033  
    ##                                                  Other      :  393  
    ##                                                  Unknown    :12164  
    ##                                                  White NH   :39313  
    ##    raceethnic6                       CODliteral    military 
    ##  White NH:39313   LUNG CANCER             :  397   N:42875  
    ##  Unknown :12164   PROBABLE ASCVD          :  343   U:  456  
    ##  Asian   : 3056   ASCVD                   :  309   Y:15866  
    ##  Black NH: 2551   ALZHEIMERS DEMENTIA     :  239            
    ##  Hispanic: 1033   PANCREATIC CANCER       :  235            
    ##  AIAN NH :  438   (Other)                 :57646            
    ##  (Other) :  642   NA's                    :   28            
    ##        status     
    ##  Homeless :  335  
    ##  With home:58862  
    ##                   
    ##                   
    ##                   
    ##                   
    ## 

``` r
write.csv(EDAdf, file = "HomelessFinal.csv")
```

In the next section, I will use this data set for exploratary data analysis prior to training machine learning models in the last section.
