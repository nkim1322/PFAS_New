# Random forest
# Library -----------------------------------------------------------------

library(tree)
library(randomForest)
library(caret)
library(tidyverse)
library(reshape2)

# Load --------------------------------------------------------------------

compounds_data <- readRDS('modeling_data/compounds_data.rds')
compounds_logreg <- readRDS('models/compounds_logreg.rds')

# Model -------------------------------------------------------------------
# Uses the same train and test sets as logistic regression

# A list of 5 lists (1 per compound)
# - Each list contains 1) full RF; 2) detects only RF; 3) test data; 4) train data; 
#     5) forest predictions; 6) outbag_predictions; 7) test_err

compounds <- names(compounds_data)
parameters <- data.frame(compound = c("PFOA","PFHXA","PFPEA","PFHPA","PFOS"),
                         ntree = c(1000, 1000, 1000, 1000, 1000),
                         mtry = c(8, 23, 22, 5, 9),
                         nodesize = c(3, 6, 6, 10, 7))

reg_parameters <- data.frame(compound = c("PFOA","PFHXA","PFPEA","PFHPA","PFOS"),
                             ntree = c(500, 500, 500, 500, 500),
                             mtry = c(9, 13, 17, 22, 17),
                             nodesize = c(4, 10, 10, 10, 8))

compounds_forest <- list()
for (comp in compounds) {
  clist <- compounds_logreg[[comp]]
  # Forest 1: Classification
  set.seed(123)
  # (Following line included only to replicate previous results)
  x <- compounds_data[[comp]]$final %>% createDataPartition(p = 0.7, list = FALSE) 
  forest <- randomForest(final~., data = clist[['train_data']][,-c(1:2)], 
                         ntree = parameters[parameters$compound == comp, 'ntree'],
                         mtry = parameters[parameters$compound == comp, 'mtry'], 
                         nodesize = parameters[parameters$compound == comp, 'nodesize'], 
                         importance = TRUE)
  predictions <- forest %>% predict(clist[['test_data']], type = "class")
  
  # forest_correct <- predictions == clist[['test_data']]$final
  # forest_correct <- as.numeric(forest_correct)
  
  # Forest 2: Regression; only with detects, log transform
  set.seed(123)
  reg <- compounds_data[[comp]][compounds_data[[comp]]$final == 1, ]
  reg$reg_log <- log(reg$reg)
  ids <- sample(0.7*nrow(reg))
  reg_train <- reg[ids,]
  reg_test <- reg[-ids,]

  reg_forest <- randomForest(reg_log~., data = reg_train[,-c(1:3)], 
                             ntree = reg_parameters[reg_parameters$compound == comp, 'ntree'],
                             mtry = reg_parameters[reg_parameters$compound == comp, 'mtry'], 
                             nodesize = reg_parameters[reg_parameters$compound == comp, 'nodesize'],
                             importance = TRUE)
  outbag_predictions <- reg_forest %>% predict(reg_test[,-c(1:3)])
  test.err <- with(reg_test, mean((log(reg_test$reg) - outbag_predictions)^2))
  
  compounds_forest[[comp]] <- 
    list(forest = forest, 
         reg_forest = reg_forest, 
         train_data = clist[['train_data']], 
         test_data = clist[['test_data']], 
         predictions = predictions,
         outbag_predictions = outbag_predictions,
         test_err = test.err)
}



# Save --------------------------------------------------------------------

saveRDS(compounds_forest, 'models/compounds_forest.rds')




