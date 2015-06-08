setwd("C:/Users/pawlusm/Desktop/decTree")

## read in the dataset
ya <- read.csv("young_alums2.csv")

## load the ggplot2 library for plotting
library(ggplot2)

## explore the columns in the dataset
names(ya)

## quick check the proportion of donors to non-donors
table(ya$donor)
prop.table(table(ya$donor))

## load the caret package for modelling
library(caret)

## partition the data to create a training set and a test set
inTrain <- createDataPartition(y=ya$donor,
                               p=0.7, list=FALSE)
training <- ya[inTrain,]
testing <- ya[-inTrain,]

## look at dimensions of the new data frames to ensure correct partitioning
dim(training)
dim(testing)

## check the structure of the data frames to create a subset of data types
str(training)
str(testing)

training <- training[,2:14]
testing <- testing[,2:14]

## quick check both subsets to ensure the proportion of donor to non-donor is still similar
prop.table(table(training$donor))
prop.table(table(testing$donor))

## set some tuning parameters for the model
## in this case, repeated cross validation: 3 folds, 10 repeats
rfSet <- trainControl(method='repeatedcv', repeats = 10, number=3)

## set a seed since some (quasi)random numbers are used to ensure consistent, reproducible results
set.seed(212)

## train the model using the random forest algorithm
results_rf = train(donor~.,data=training,method = "rf",trControl = rfSet)

## look at the results
results_rf

## order the variables in order of importance
varImp(results_rf)

## use the model to predict donors in the test set
predictions <- predict(results_rf,newdata=testing)

## look at the proportion of donors and non-donors predicted
prop.table(table(predictions))

## evaluate how often the model correctly identified a donor or non-donor
confusionMatrix(predictions,testing$donor)
predictions

## unfortunately, in this case, donor prediction is low so another model will need to be tried


##multiple regression 

## for multiple rergession, subset the data so only numeric data types remain
training <- training[,c(2,4:14,16)]
testing <- testing[,c(2,4:14,16)]

## look at the structure to test that the data frames were properly subsetted
str(training)
str(testing)

## train a linear model on the data using log of total giving as the independent variable
lmMod <- lm(log_tg ~ .,data=training)
## check which variables are statistically significant
summary(lmMod)

## plot some diagnostics
par(mfrow=c(2,2))
plot(lmMod)

par(mfrow=c(1,1)) 
plot(cooks.distance(lmMod))

anova(lmMod)

library(car)
influencePlot(lmMod)

## from the diagnostics, we see some outliers but the data seems usable

## predict probabilities in the test set
lmPred <- predict(lmMod, newdata = data.frame(testing)) 
## quick analysis of the results
range(lmPred)
length(lmPred)
dim(testing)

## add the probabilities to the test set
lmTest <- cbind(testing,lmPred)
str(lmTest)

## to try to improve the model include only those variables which are statistically significant predictors
lmMod <- lm(log_tg ~ coreprefyr + stu_grp + evnt + job + st_gov + top_caller + athlete + volunteered,data=training)
summary(lmMod)

## run diagnostics

par(mfrow=c(2,2))
plot(lmMod)

par(mfrow=c(1,1)) 
influencePlot(lmMod)

# Bootstrap Measures of Relative Importance (1000 samples)
install.packages("relaimpo")
library(relaimpo)
boot <- boot.relimp(lmMod, b = 1000, type = c("lmg", 
                                            "last", "first", "pratt"), rank = TRUE, 
                    diff = TRUE, rela = TRUE)
booteval.relimp(boot) # print result
plot(booteval.relimp(boot,sort=TRUE)) # plot result

## predict probabilities again and add to the test set

lmPred <- predict(lmMod, newdata = data.frame(testing)) 
lmTest <- cbind(testing,lmPred)
str(lmTest)

## create a new data frame with just the predictions
predVals  <- data.frame  (coreid =	lmTest$coreid,	giving =	lmTest$ttl_gv, pred = lmTest$lmPred)
## write a file to evaluate the predictions against the database
write.csv(predVals,  file	=	"mill_pred1.csv",	row.names=FALSE)

## these results were overall suprisingly good at predicting young alum prospects with significant propensity to give
## this was verified by qualitative data in the database which the model did not use for predicting
