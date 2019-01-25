# This mini-project is based on the K-Means exercise from 'R in Action'
# Go here for the original blog post and solutions
# http://www.r-bloggers.com/k-means-clustering-from-r-in-action/

# Exercise 0: Install these packages if you don't have them already

# install.packages(c("cluster", "rattle.data","NbClust"))

# Now load the data and look at the first few rows
data(wine, package="rattle.data")
head(wine)

# Exercise 1: Remove the first column from the data and scale
# it using the scale() function

wine_scale <- scale(wine[-1])
head(wine_scale)

# Now we'd like to cluster the data using K-Means. 
# How do we decide how many clusters to use if you don't know that already?
# We'll try two methods.

# Method 1: A plot of the total within-groups sums of squares against the 
# number of clusters in a K-means solution can be helpful. A bend in the 
# graph can suggest the appropriate number of clusters. 

wssplot <- function(data, nc=15, seed=1234){
  wss <- (nrow(data)-1)*sum(apply(data,2,var))
  for (i in 2:nc){
    set.seed(seed)
    wss[i] <- sum(kmeans(data, centers=i)$withinss)}
  
  plot(1:nc, wss, type="b", xlab="Number of Clusters",
       ylab="Within groups sum of squares")
}

wssplot(wine_scale)

# Exercise 2:
#   * How many clusters does this method suggest?

###############
## THIS PLOT SUGGESTS 3 CLUSTERS AS THE BEND IN THE LINE GRAPH
## OCCURS WHERE CLUSTERS = 3
##############

#   * Why does this method work? What's the intuition behind it?
#   * Look at the code for wssplot() and figure out how it works

##  THIS METHOD LOOKS FOR WITHIN CLUSTER SUM OF SQUARES FOR 
## CLUSTERS RANGING FROM 1 THROUGH 15 AND PLOTS THESE SUMS.
## INITIALLY THE SUM OF SQUARES DECREASES DRASTICALLY FROM 1
## TO 3 CLUSTERS. THE DECREASE IN SUM OF SQUARES IS SMALLER FOR
## EACH INCREASE IN CLUSTERS AFTER THIS POINT INDICATING THAT 
## THE MODEL HAS MADE THE MOST SIGNIFICANT MINIMIZATION OF SUMS OF SQUARES 
## AT THIS POINT - THE MEMBERS OF EACH CLUSTER ARE CLOSER TO THE MEAN OF THE CLUSTER
## WITH 3 CLUSTERS COMPARED WITH 1 CLUSTER AND ANY ADDITIONAL # OF CLUSTERS GIVES
## DIMINISHING RETURNS IN TERMS OF MINIMIZING SUM OF SQUARES.

# Method 2: Use the NbClust library, which runs many experiments
# and gives a distribution of potential number of clusters.

library(NbClust)
set.seed(1234)
nc <- NbClust(wine_scale, min.nc=2, max.nc=15, method="kmeans")
barplot(table(nc$Best.n[1,]),
        xlab="Numer of Clusters", ylab="Number of Criteria",
        main="Number of Clusters Chosen by 26 Criteria")


# Exercise 3: How many clusters does this method suggest?

## THE TALLEST BAR IN THIS BARGRAPH IS AT 3 CLUSTERS INDICATING 
## ONCE AGAIN THAT WE SHOULD SET K TO 3.

# Exercise 4: Once you've picked the number of clusters, run k-means 
# using this number of clusters. Output the result of calling kmeans()
# into a variable fit.km



fit.km <- kmeans(wine_scale, centers = 3)
str(fit.km)


# Now we want to evaluate how well this clustering does.

# Exercise 5: using the table() function, show how the clusters in fit.km$clusters
# compares to the actual wine types in wine$Type. Would you consider this a good
# clustering?

table(wine$Type, fit.km$cluster)
## THE MODELED CLUSTERS MATCH THE ACTUAL WINE TYPES QUITE WELL.

# Exercise 6:
# * Visualize these clusters using  function clusplot() from the cluster library
# * Would you consider this a good clustering?

#clusplot( ... )
cluster::clusplot(wine_scale, fit.km$cluster)