Maya Bhat-Gregerson

    ## here() starts at H:/Mortality/Homeless/IntroDSCapstone

    ## 
    ## Attaching package: 'dplyr'

    ## The following objects are masked from 'package:stats':
    ## 
    ##     filter, lag

    ## The following objects are masked from 'package:base':
    ## 
    ##     intersect, setdiff, setequal, union

    ## 
    ## Attaching package: 'data.table'

    ## The following objects are masked from 'package:dplyr':
    ## 
    ##     between, first, last

I. Overview
-----------

The purpose of this project is to create a machine learning model that will classify deaths in Washington State according to the residential status of decedents at the time of death i.e. with permanent housing vs. homeless.

The datasets used for this project include Washington State final annual death files 2003-2017(including records for all deaths occurring within Washington State in a given calendar year) and the King County Medical Examiner Office\`s registry of deaths among homeless individuals who died in King County, Washington. This registry contains identification information and place of death for homeless individuals who died between 2003 through late 2017.

II. Data pre-processing
-----------------------

### A. Overview

#### 1. Data cleaning and standardization

I will prepare the data sets will in the following order:

1.  Limit Washington mortality data sets (WAMD) to attributes that are likely to be relevant to training the machine learning model.

2.  Standardize attribute names and formats in both WAMD and King County Homeless Death Registry (HDR) data. Due to changes in data collection practices for WAMD over the years, attribute names and formats are inconsistent.

3.  Limit records in WAMD to decedents who were Washington State residents who died in Washington State.

#### 2. Linking homeless death data to their death certificates

This will add the additional attributes from WAMD to each of the records in HDR so that they have the necessary attributes to train the model.

#### 3. Creating a subset of WAMDR with decedents who had permanent homes

I will limit this to approximately 1,000 randomly selected records from the 2017 WAMD datafile. I will identify decedents who had permanent homes at the time of death by the facility type (type of facility where the person died) and place of death variables.

### B. Washington State mortality data

Washington State requires by law that all deaths occurring in the state must be registered with the Washington State Department of Health by the funeral director organizing the disposal of the body and the decedents\` regular health care provider. In the absence of a health care provider the medical examiner or coroner in the county where the body was found has jurisdiction over the death. The Washington State death data set for 2017 contains over 58,000 unique observations (death records) and over 250 attributes. Most of the attributes are not relevant to train the machine learning model for this project.

This section addresses cleaning and limiting the data sets (in terms of number of attributes).

1.  **Cleaning and standardizing WAMD annual data 2003-2017**

``` r
keepvars <- c("certno" , "last_name" , "first_name" ,"middle_name" , "date_of_death" , "dob" , "ssn" , "res_street" , "res_city" , "res_zip" , "sex" , "dth_yr" , "race" , "hisp" , "city_occ" , "cnty_occ" , "facility" , "fac_type" , "married" , "city_res" , "cnty_res" , "underly" , "contrib" , "attclass" , "educ" , "zipcode", "st_res", "st_occ")

newnames <- c("certno", "lname", "fname", "mname", "dod", "dob", "ssn", "resst", "rescity", "reszip", "sex", "dthyr", "race", "hisp", "cityocc", "cntyocc", "facility", "factype", "married", "cityres", "cntyres", "underly", "contrib", "attclass", "educ", "zip", "stres", "stocc")

dth03 <- fread("H:/Mortality/Homeless/IntroDSCapstone/Data/statname2003.csv", 
               select = keepvars)
dth03_wa <- subset(dth03, st_res==48 & st_occ==48)
names(dth03_wa)=newnames

dth04 <-fread("H:/Mortality/Homeless/IntroDSCapstone/Data/statname2004.csv", 
               select = keepvars)
dth04_wa <- subset(dth04, st_res==48 & st_occ==48)
names(dth04_wa)=newnames

dth05 <-fread("H:/Mortality/Homeless/IntroDSCapstone/Data/statname2005.csv", 
               select = keepvars)
dth05_wa <- subset(dth05, st_res==48 & st_occ==48)
names(dth05_wa)=newnames

summary(dth03_wa)
```

    ##      certno             lname              fname          
    ##  Min.   :2.003e+09   Length:44762       Length:44762      
    ##  1st Qu.:2.003e+09   Class :character   Class :character  
    ##  Median :2.003e+09   Mode  :character   Mode  :character  
    ##  Mean   :2.003e+09                                        
    ##  3rd Qu.:2.003e+09                                        
    ##  Max.   :2.003e+09                                        
    ##                                                           
    ##     mname               dod                dob           
    ##  Length:44762       Length:44762       Length:44762      
    ##  Class :character   Class :character   Class :character  
    ##  Mode  :character   Mode  :character   Mode  :character  
    ##                                                          
    ##                                                          
    ##                                                          
    ##                                                          
    ##       ssn               resst             rescity              reszip     
    ##  Min.   :  1042086   Length:44762       Length:44762       Min.   :98001  
    ##  1st Qu.:510223151   Class :character   Class :character   1st Qu.:98146  
    ##  Median :534122010   Mode  :character   Mode  :character   Median :98373  
    ##  Mean   :496621590                                         Mean   :98481  
    ##  3rd Qu.:538266158                                         3rd Qu.:98674  
    ##  Max.   :999999999                                         Max.   :99999  
    ##                                                                           
    ##      sex                dthyr          race                hisp        
    ##  Length:44762       Min.   :2003   Length:44762       Min.   :0.00000  
    ##  Class :character   1st Qu.:2003   Class :character   1st Qu.:0.00000  
    ##  Mode  :character   Median :2003   Mode  :character   Median :0.00000  
    ##                     Mean   :2003                      Mean   :0.04218  
    ##                     3rd Qu.:2003                      3rd Qu.:0.00000  
    ##                     Max.   :2003                      Max.   :9.00000  
    ##                                                                        
    ##     cityocc        cntyocc         facility        factype     
    ##  Min.   : 100   Min.   : 1.00   Min.   :  1.0   Min.   :0.000  
    ##  1st Qu.:1701   1st Qu.:17.00   1st Qu.:162.0   1st Qu.:0.000  
    ##  Median :1805   Median :18.00   Median :800.0   Median :4.000  
    ##  Mean   :2214   Mean   :22.11   Mean   :569.4   Mean   :2.855  
    ##  3rd Qu.:3104   3rd Qu.:31.00   3rd Qu.:810.0   3rd Qu.:5.000  
    ##  Max.   :3909   Max.   :39.00   Max.   :999.0   Max.   :9.000  
    ##                                                                
    ##     married         cityres        cntyres        underly         
    ##  Min.   :1.000   Min.   : 100   Min.   : 1.00   Length:44762      
    ##  1st Qu.:2.000   1st Qu.:1701   1st Qu.:17.00   Class :character  
    ##  Median :3.000   Median :2100   Median :21.00   Mode  :character  
    ##  Mean   :2.821   Mean   :2222   Mean   :22.19                     
    ##  3rd Qu.:4.000   3rd Qu.:3104   3rd Qu.:31.00                     
    ##  Max.   :9.000   Max.   :3909   Max.   :39.00                     
    ##                                                                   
    ##  contrib           attclass          educ            zip       
    ##  Mode:logical   Min.   :1.000   Min.   : 0.00   Min.   :98001  
    ##  NA's:44762     1st Qu.:1.000   1st Qu.:12.00   1st Qu.:98146  
    ##                 Median :1.000   Median :12.00   Median :98373  
    ##                 Mean   :1.206   Mean   :12.13   Mean   :98481  
    ##                 3rd Qu.:1.000   3rd Qu.:14.00   3rd Qu.:98674  
    ##                 Max.   :7.000   Max.   :17.00   Max.   :99999  
    ##                                 NA's   :649                    
    ##      stres        stocc   
    ##  Min.   :48   Min.   :48  
    ##  1st Qu.:48   1st Qu.:48  
    ##  Median :48   Median :48  
    ##  Mean   :48   Mean   :48  
    ##  3rd Qu.:48   3rd Qu.:48  
    ##  Max.   :48   Max.   :48  
    ## 

``` r
###THIS PROCESS SHOULD BE REPEATED FOR EACH YEAR OF DEATH DATA THROUGH 2017. IN THE INTEREST OF TIME COMPLETED THIS IN STATA AND READ IN THE RESULTING FILES INTO R.
```

1.  **Creating a training data set of decedents who had permanent homes at time of death**

Use fields: - `Place of Death` with values of `Hospice`, `Nursing Home/Longterm Care`, `Decedent Home`, `Hospital` - `Res Geo Match Score` of 100 - `Residence Zip` is not `99999` - Check with Craig Ferguson/Brianna about this. - `Residence Street` does not have blanks or `homeless` or `Transient` or `&`

``` r
dth16_King <- read_csv("H:/Mortality/Homeless/IntroDSCapstone/Data/dth16_KingCo.csv")

summary(dth16_King)
```

    ##      certno             lname              fname          
    ##  Min.   :2.016e+09   Length:12817       Length:12817      
    ##  1st Qu.:2.016e+09   Class :character   Class :character  
    ##  Median :2.016e+09   Mode  :character   Mode  :character  
    ##  Mean   :2.016e+09                                        
    ##  3rd Qu.:2.016e+09                                        
    ##  Max.   :2.016e+09                                        
    ##                                                           
    ##     mname               sex                dob           
    ##  Length:12817       Length:12817       Length:12817      
    ##  Class :character   Class :character   Class :character  
    ##  Mode  :character   Mode  :character   Mode  :character  
    ##                                                          
    ##                                                          
    ##                                                          
    ##                                                          
    ##       ssn                dod                dthyr      deathaddress      
    ##  Min.   :  1188904   Length:12817       Min.   :2016   Length:12817      
    ##  1st Qu.:498308680   Class :character   1st Qu.:2016   Class :character  
    ##  Median :534205574   Mode  :character   Median :2016   Mode  :character  
    ##  Mean   :493866333                      Mean   :2016                     
    ##  3rd Qu.:538504357                      3rd Qu.:2016                     
    ##  Max.   :999999999                      Max.   :2016                     
    ##                                                                          
    ##   deathcity         deathcitycode   deathcitywacode deathcountywacode
    ##  Length:12817       Min.   :  100   Min.   : 301    Min.   : 3.00    
    ##  Class :character   1st Qu.:23515   1st Qu.:1701    1st Qu.:17.00    
    ##  Mode  :character   Median :57745   Median :1704    Median :17.00    
    ##                     Mean   :43795   Mean   :1759    Mean   :17.52    
    ##                     3rd Qu.:63000   3rd Qu.:1714    3rd Qu.:17.00    
    ##                     Max.   :99077   Max.   :3904    Max.   :39.00    
    ##                                     NA's   :1       NA's   :1        
    ##   deathstate             zip        placeofdeathtype    facility    
    ##  Length:12817       Min.   :95155   Min.   :0.000    Min.   :  1.0  
    ##  Class :character   1st Qu.:98031   1st Qu.:0.000    1st Qu.:155.0  
    ##  Mode  :character   Median :98101   Median :4.000    Median :800.0  
    ##                     Mean   :98095   Mean   :2.683    Mean   :581.5  
    ##                     3rd Qu.:98126   3rd Qu.:5.000    3rd Qu.:810.0  
    ##                     Max.   :99336   Max.   :7.000    Max.   :820.0  
    ##                     NA's   :1                        NA's   :23     
    ##  placeofdeath         marital               educ         bridgerace    
    ##  Length:12817       Length:12817       Min.   :1.000   Min.   : 1.000  
    ##  Class :character   Class :character   1st Qu.:3.000   1st Qu.: 1.000  
    ##  Mode  :character   Mode  :character   Median :4.000   Median : 1.000  
    ##                                        Mean   :4.236   Mean   : 2.355  
    ##                                        3rd Qu.:6.000   3rd Qu.: 1.000  
    ##                                        Max.   :9.000   Max.   :99.000  
    ##                                                        NA's   :4       
    ##   hispanicno           resst             rescity         
    ##  Length:12817       Length:12817       Length:12817      
    ##  Class :character   Class :character   Class :character  
    ##  Mode  :character   Mode  :character   Mode  :character  
    ##                                                          
    ##                                                          
    ##                                                          
    ##                                                          
    ##  residencecitywacode    res_cnty      stres    resgeomatchscore
    ##  Min.   :1700        Min.   :17   Min.   :48   Min.   :  0.00  
    ##  1st Qu.:1701        1st Qu.:17   1st Qu.:48   1st Qu.:100.00  
    ##  Median :1705        Median :17   Median :48   Median :100.00  
    ##  Mean   :1708        Mean   :17   Mean   :48   Mean   : 98.67  
    ##  3rd Qu.:1714        3rd Qu.:17   3rd Qu.:48   3rd Qu.:100.00  
    ##  Max.   :1733        Max.   :17   Max.   :48   Max.   :100.00  
    ##                                                NA's   :23      
    ##  certifierdesignation   underly             manner         
    ##  Min.   :1.000        Length:12817       Length:12817      
    ##  1st Qu.:1.000        Class :character   Class :character  
    ##  Median :1.000        Mode  :character   Mode  :character  
    ##  Mean   :1.774                                             
    ##  3rd Qu.:2.000                                             
    ##  Max.   :7.000                                             
    ##  NA's   :5

``` r
miss_var_summary(dth16_King)
```

    ## # A tibble: 32 x 3
    ##    variable             n_miss pct_miss
    ##    <chr>                 <int>    <dbl>
    ##  1 deathaddress           4487 35.0    
    ##  2 mname                  1498 11.7    
    ##  3 facility                 23  0.179  
    ##  4 resgeomatchscore         23  0.179  
    ##  5 certifierdesignation      5  0.0390 
    ##  6 bridgerace                4  0.0312 
    ##  7 underly                   4  0.0312 
    ##  8 fname                     1  0.00780
    ##  9 deathcitywacode           1  0.00780
    ## 10 deathcountywacode         1  0.00780
    ## # ... with 22 more rows

``` r
permhome <- subset(dth16_King, placeofdeathtype==0 | placeofdeathtype==5 | placeofdeathtype==7 & resgeomatchscore >=95)

##RANDOMLY SELECT 1,200 persons from "PERMHOME"

set.seed(1)
sample <- sample(1:nrow(permhome), 1200)
permhome_sample <- permhome[sample, ]

str(permhome_sample)
```

    ## Classes 'tbl_df', 'tbl' and 'data.frame':    1200 obs. of  32 variables:
    ##  $ certno              : int  2016014362 2016020384 2016030787 2016049178 2016010968 2016048618 2016051185 2016035446 2016033805 2016003216 ...
    ##  $ lname               : chr  "BAKKE" "GELLERMANN" "ADATTO" "UNDERWOOD" ...
    ##  $ fname               : chr  "LETA" "LOUIS" "IRVING" "HELEN" ...
    ##  $ mname               : chr  "SUE" "WRIGHT" "JAMES" "JOAN" ...
    ##  $ sex                 : chr  "F" "M" "M" "F" ...
    ##  $ dob                 : chr  "8/4/1965" "8/18/1936" "4/30/1920" "10/22/1953" ...
    ##  $ ssn                 : int  539783850 533321739 537107049 555982230 502164234 538645725 532364908 569443099 574059167 569606326 ...
    ##  $ dod                 : chr  "4/3/2016" "5/13/2016" "7/29/2016" "12/2/2016" ...
    ##  $ dthyr               : int  2016 2016 2016 2016 2016 2016 2016 2016 2016 2016 ...
    ##  $ deathaddress        : chr  "37901 247TH AVENUE SE" "HEALTH AND REHAB OF NORTH SEATTLE" "KLINE GALLAND" "4515 49TH AVE S" ...
    ##  $ deathcity           : chr  "ENUMCLAW" "SEATTLE" "SEATTLE" "SEATTLE" ...
    ##  $ deathcitycode       : int  22045 63000 63000 63000 63960 35170 23515 63000 23515 35415 ...
    ##  $ deathcitywacode     : int  1704 1701 1701 1701 1726 1730 1719 1701 1719 1705 ...
    ##  $ deathcountywacode   : int  17 17 17 17 17 17 17 17 17 17 ...
    ##  $ deathstate          : chr  "WASHINGTON" "WASHINGTON" "WASHINGTON" "WASHINGTON" ...
    ##  $ zip                 : int  98022 98133 98118 98118 98133 98028 98003 98122 98003 98032 ...
    ##  $ placeofdeathtype    : int  0 5 5 0 5 0 5 5 5 0 ...
    ##  $ facility            : int  810 800 800 810 800 810 800 800 800 810 ...
    ##  $ placeofdeath        : chr  "Home" "Nursing home/long term care facility" "Nursing home/long term care facility" "Home" ...
    ##  $ marital             : chr  "M" "D" "M" "S" ...
    ##  $ educ                : int  3 7 4 6 6 3 6 5 3 6 ...
    ##  $ bridgerace          : int  1 1 1 1 1 1 1 1 1 1 ...
    ##  $ hispanicno          : chr  "Y" "Y" "Y" "Y" ...
    ##  $ resst               : chr  "37901 247TH AVE SE" "1048 NE 103RD ST" "1200 UNIVERSITY ST APT 1204" "4515 49TH AVE S" ...
    ##  $ rescity             : chr  "ENUMCLAW" "SEATTLE" "SEATTLE" "SEATTLE" ...
    ##  $ residencecitywacode : int  1704 1701 1701 1701 1701 1730 1719 1702 1705 1705 ...
    ##  $ res_cnty            : int  17 17 17 17 17 17 17 17 17 17 ...
    ##  $ stres               : int  48 48 48 48 48 48 48 48 48 48 ...
    ##  $ resgeomatchscore    : int  100 100 100 100 100 100 89 100 100 100 ...
    ##  $ certifierdesignation: int  1 1 7 1 7 1 1 1 1 7 ...
    ##  $ underly             : chr  "C900" "I516" "C159" "C56" ...
    ##  $ manner              : chr  "N" "N" "N" "N" ...

### B. King County Medical Examiner\`s Homeless Death Registry data - November 2003 to September 2017

This data set includes all deaths to homeless or transient individuals who died in King County, Washington State and for whom the death certifier (the person who submitted a death certificate to Washington State Department of Health) was the medical examiner for King County.

The King County Medical Examiner`s Office (KCMEO) established a given decedent`s homeless or transient status by gathering information from family members, acquaintances, social service agencies, and law enforcement (where available). In some situations, the medical examiner (ME) established homelessness based on his own assessment of the situation rather than what the family reported because the stigma associated with homelessness may have resulted in inaccurate reporting.

KCMEO defines `homelessness` based on the Chief Medical Examiner\`s criteria rather than standard federal Department of Housing and Urban Development (HUD) or Department of Social and Health Services (DSHS) criteria.

1.  **Cleaning KCMEO homeless registry**

``` r
homeless <- read_csv("H:/Mortality/Homeless/IntroDSCapstone/Data/HomelessRegistryKingCo.csv")


homeless <- rename(homeless, lname = namelast,
         fname = namefirst,
         mname_h = namemiddle,
         resaddr_h = resaddr,
         rescity_h = rescity,
         dob = birthdate,
         age_h = age,
         dod_h = eventdate, 
         ssn_h = ssn,
         dthzip = deathzip,
         marstat_h = maritalstatus,
         casenum_h = casenum)


##THE FOLLOWING CHANGES TO THE TWO DATE FIELDS (DATE OF BIRTH AND DATE OF DEATH) HAVE BEEN IMPLEMENTED TO MAKE
## THEM CONSISTENT WITH THE FORMAT IN THE DEATH CERTIFICATE DATA SET.  

#REMOVE HYPHENS IN DATES OF BIRTH AND DEATH TO MAKE THEM CONSISTENT WITH DEATH DATA
#DATES ARE IN DDMMMYY FORMAT TO BEGIN WITH.
homeless$dob <- gsub("-", "", homeless$dob)
homeless$dod_h <- gsub("-", "", homeless$dod_h)

#PASTE LEADING 0 TO DAY WHEN DAY IS 1 TO 9 TO MAKE THEM ALL 2 DIGIT DAYS
homeless$dob <- ifelse((nchar(homeless$dob)) < 7, paste("0",homeless$dob, sep = ""), homeless$dob)
homeless$dod_h <- ifelse((nchar(homeless$dod_h)) < 7, paste("0",homeless$dod_h, sep = ""), homeless$dod_h)

#INSERT CENTURY (19XX OR 20XX) TO YEARS TO MAKE ALL YEARS YYYY FORMAT
homeless$dob <- gsub("^([0-3][0-9][A-Z]{3})([0-9]{2})$", "\\119\\2", homeless$dob)
homeless$dod_h <- gsub("^([0-3][0-9][A-Z]{3})([0-9]{2})$", "\\120\\2", homeless$dod_h)

homeless<- mutate_all(homeless, funs(toupper))
head(homeless, 10)
```

    ## # A tibble: 10 x 17
    ##    casenum_h lname fname mname_h age_h resaddr_h rescity_h marstat_h dob  
    ##    <chr>     <chr> <chr> <chr>   <chr> <chr>     <chr>     <chr>     <chr>
    ##  1 02-01287  POMME FRAN~ XAVIER  51    NO PERMA~ <NA>      NEVER MA~ 04JA~
    ##  2 03-01549  PATT~ FRAN~ DELANO  42    NO PERMA~ <NA>      NEVER MA~ 21JU~
    ##  3 03-01823  MANS~ JOHN  PATRICK 41    NO PERMA~ SEATTLE   NEVER MA~ 17AP~
    ##  4 03-01864  SPAR~ MARL~ RADCLI~ 44    NO PERMA~ SEATTLE   NEVER MA~ 19MA~
    ##  5 03-01873  HATF~ JOSH~ MICHAEL 30    NO PERMA~ <NA>      NEVER MA~ 26DE~
    ##  6 04-00003  BRYA~ RYAN  MICHAEL 23    POSSIBLE~ TACOMA    NEVER MA~ 17SE~
    ##  7 04-00016  ROTH  DENN~ ROBERT  35    3110 C S~ AUBURN    NEVER MA~ 15JU~
    ##  8 04-00024  BEAM~ DOLO~ <NA>    54    158 23RD~ SEATTLE   NEVER MA~ 02MA~
    ##  9 04-00043  THOM~ JEFF~ TRAVIS  57    NO PERMA~ COVINGTON NEVER MA~ 15JU~
    ## 10 04-00050  HUMA~ <NA>  <NA>    0     <NA>      <NA>      UNKNOWN   <NA> 
    ## # ... with 8 more variables: deathplace <chr>, deathaddr <chr>,
    ## #   deathcity <chr>, dthzip <chr>, dod_h <chr>, eventaddr <chr>,
    ## #   eventcity <chr>, ssn_h <chr>

1.  **Linking HDR with WAMD**

The HDR contains name, date of birth, date of death, place of death (address), and social security number. There is no additional information on cause of death, or other attributes that might be used in machine learning to classify persons as homeless or with a permanent home. For this reason, the HDR data must first be linked to full death certificate data to add the relevant attributes that can be found in the death certificate.

KCMEO is required by law to submit a death certificate for all deaths it investigates. For this reason, it is very likely that the decedents' last names, first names, and locations of death will be recorded in an identical manner in HDR as well as the death certificates (barring data entry error).

In this situation it is possible to use deterministic linkage to link HDR records with their complete death certificates. Using a derived attribute created by concatenating attributes in the HDR data set with low missing data ("namelast", "deathcity", "deathaddress", and "birthdate") and matching it with the same derived variable in the death data set should result in an accurate match and record linkage.

Pre-processing of the HDR and death datasets includes standardizing the values in the attributes to be used in the linkage, and creating the derived variable (concatenation of the above variables) in both datasets.

``` r
## left join homeless data by year (otherwise datasets are too large) with death certificate data

## rbind all individual years of data together
```

1.  **Missing Values**

Missing values in any of the attributes in either HDR or death certificate data may be useful in the upcoming machine learning phase as it is very likely that a key distinction between decedents who were homeless vs. those who had permanent homes is that their records cannot be completed due to lack of information from family members or other "informants".

``` r
miss_var_summary(homeless)
```

    ## # A tibble: 17 x 3
    ##    variable   n_miss pct_miss
    ##    <chr>       <int>    <dbl>
    ##  1 rescity_h     613   54.2  
    ##  2 ssn_h         286   25.3  
    ##  3 marstat_h     155   13.7  
    ##  4 mname_h       137   12.1  
    ##  5 deathplace     94    8.31 
    ##  6 resaddr_h      63    5.57 
    ##  7 dod_h          63    5.57 
    ##  8 eventaddr      38    3.36 
    ##  9 eventcity      35    3.09 
    ## 10 dthzip          6    0.531
    ## 11 fname           3    0.265
    ## 12 dob             3    0.265
    ## 13 deathaddr       2    0.177
    ## 14 deathcity       2    0.177
    ## 15 casenum_h       0    0    
    ## 16 lname           0    0    
    ## 17 age_h           0    0
