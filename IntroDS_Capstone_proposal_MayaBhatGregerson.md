Classifying deaths by residence status using machine learning
================
Maya Bhat-Gregerson
8/22/2018

#### A. Problem to be solved

Studies of sample populations in homeless shelters indicate that their life expectancy and leading causes of death are different from those of the general population. Unfortunately, Washington State's Electronic Death Registration System (EDRS) does not provide a *systematic* mechanism (such as a checkbox) to capture whether decedents' are homeless so we cannot determine if these study findings extend to the broader population. Death certifiers *can* enter words or phrases in text fields on the death certificate indicating that a decedent was homeless. However, data in text form cannot be analyzed readily.

#### B. Audience and potential uses of the analysis

Public health and social service agencies at the state and local (county or city) levels would find analysis of deaths in the homeless population very valuable. It would allow agencies to understand the distribution of disease and injury among the homeless and to plan evidence-based population-level interventions. In addition to understanding leading causes of death in this population, social service agencies would also have an understanding of the geographic distribution of homeless deaths, seasonal patterns to the death, and other trends that would allow them to provide assistance in a timely and effective manner.

#### C. Data sources

To classify deaths by homeless status I will use the following two data sets:

1.  **Mortality data** Annual death data files from 2003 through 2017 including the following variables:
    -   Last name
    -   First name
    -   Location/address where decedent was found
    -   Gender
    -   Date of birth (if available)
    -   Date of death
    -   Cause of death
    -   Classfication of person reporting death (physician, nurse, medical examiner, coroner etc.)
    -   Geocode match scores (how closely the latitude/longitude of the residential street address matches the reported zipcode)

Format: CSV files

1.  **King County Medical Examiner registry of deaths to homeless individuals** A list of persons who have died in King County (the most populous county in Washington State) since 2003 and who were verified as homeless by the medical examiner (ME). The list was compiled by the King County ME after collecting information about the decedents from various sources such as family members, law enforcement, social service agencies etc. There are over 1,100 homeless decedents on this list. Variables include:
    -   Last name
    -   First name
    -   Location/address where decedent was found
    -   Gender
    -   Date of birth
    -   Date of death

Format: Microsoft Excel file

#### D. Problem solving approach

1.  **Data cleaning** including:
    -   consistent variable names over the individual years of mortality data (names and formats changed after 2015),
    -   consistent variable names in the mortality and King County ME homeless death registry,
    -   consistent data formats (dates, numerics, character) across variables,
    -   finding and cleaning out of range variables
    -   standardizing text (all lower case)
2.  **Linkage of annual mortality files with homeless death registry** This allows us to see how the final death certificate was completed for persons on the homeless death registry

3.  **Exploratory data analysis**
    -   linked death-registry file: do a preliminary search for key words/phrases such as "homeless", "transient", "no permanent residence", or outdoor locations such as parks, under bridges, at street corners, or other indicators of homelessness.
    -   linked death-registry file: explore the distribution of homeless deaths by demographic characteristics (agegroup, gender, race/ethnicity), look at patterns of missing values.
4.  **Classification of deaths by homelessness status using machine learning algorithm**
    -   use King County ME's registry as a training data set and create an algorithm to use with remaining (test) death data to classify all deaths into two categories (homeless and not homeless) and create a flag variable for homeless deaths.

#### E. Analysis plan

Once I classify deaths into the two homeless categories I will analysis the data to understand basic demographics of homeless deaths (agegroup, gender, race/ethnicity), geographic distribution, seasonal trends, and leading causes of death compared with the overall population.

#### F. Capstone deliverables

Deliverables will include:

1.  Detailed documentation of the classification process applied to mortality data to classify deaths by residential status,
2.  R code used to conduct the classification including any obstacles to classification and an evaluation of the accuracy of the method
3.  R code to analyze the final data set
4.  Results of analysis i.e. descriptive analysis of homeless deaths compared with deaths in general population
5.  Slides describing methods and analytic findings.
