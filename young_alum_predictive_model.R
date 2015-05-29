setwd("C:/Users/pawlusm/Desktop/decTree")

ya <- read.csv("young_alums2.csv")

library(ggplot2)

names(ya)
table(ya$donor)
prop.table(table(ya$donor))

library(caret)

inTrain <- createDataPartition(y=ya$donor,
                               p=0.7, list=FALSE)
training <- ya[inTrain,]
testing <- ya[-inTrain,]
dim(training)
dim(testing)

str(training)
str(testing)

training <- training[,2:14]
testing <- testing[,2:14]

prop.table(table(training$donor))
prop.table(table(testing$donor))

gbmSet <- trainControl(method='repeatedcv', repeats = 10, number=3)

set.seed(212)
results_rf = train(donor~.,data=training,method = "rf",trControl = gbmSet)
results_rf
varImp(results_rf)

predictions <- predict(results_rf,newdata=testing)

prop.table(table(predictions))

confusionMatrix(predictions,testing$donor)
predictions


##multiple regression 

training <- training[,c(2,4:14,16)]
testing <- testing[,c(2,4:14,16)]

str(training)
str(testing)

lmMod <- lm(log_tg ~ .,data=training)
summary(lmMod)

par(mfrow=c(2,2))
plot(lmMod)

par(mfrow=c(1,1)) 
plot(cooks.distance(lmMod))

anova(lmMod)

library(car)
influencePlot(lmMod)

lmPred <- predict(lmMod, newdata = data.frame(testing)) 
range(lmPred)
length(lmPred)
dim(testing)
lmTest <- cbind(testing,lmPred)
str(lmTest)

lmMod <- lm(log_tg ~ coreprefyr + stu_grp + evnt + job + st_gov + top_caller + athlete + volunteered,data=training)
summary(lmMod)

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

lmPred <- predict(lmMod, newdata = data.frame(testing)) 
lmTest <- cbind(testing,lmPred)
str(lmTest)

predVals  <- data.frame  (coreid =	lmTest$coreid,	giving =	lmTest$ttl_gv, pred = lmTest$lmPred)
write.csv(predVals,  file	=	"mill_pred1.csv",	row.names=FALSE)
