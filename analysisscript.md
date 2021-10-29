

```r
###############################
# analysis script
#
#this script loads the processed, cleaned data, does a simple analysis
#and saves the results to the results folder

#load needed packages. make sure they are installed.
library(broom) #for cleaning up output from lm()
library(here) #for data loading/saving
```

```
## here() starts at D:/GitHub/andreashandel/andreas-MADA-analysis3
```

```r
library(recipes)
```

```
## Loading required package: dplyr
```

```
## 
## Attaching package: 'dplyr'
```

```
## The following objects are masked from 'package:stats':
## 
##     filter, lag
```

```
## The following objects are masked from 'package:base':
## 
##     intersect, setdiff, setequal, union
```

```
## 
## Attaching package: 'recipes'
```

```
## The following object is masked from 'package:stats':
## 
##     step
```

```r
library(parsnip)
library(rsample)
library(workflows)

#path to data
#note the use of the here() package and not absolute paths
data_location <- here::here("data","processed_data","processeddata.rds")

#load data. 
mydata <- readRDS(data_location)

# for reproducibility
set.seed(123)


############################
# Data Partitioning
############################

# split train and test, using the outcome as stratifier
data_split <- rsample::initial_split(mydata,strata = 'BodyTemp')

# Create data frames for the two sets:
train_data <- rsample::training(data_split)
test_data  <- rsample::testing(data_split)

# create CV object from training data
cv_data <- rsample::vfold_cv(train_data, v = 5, repeats = 5, strata = 'BodyTemp')


############################
# Preprocessing
############################

#create a recipe for the model fitting
# we don't need to remove any NA or do imputation or standardization or anything else
# therefore our recipe is fairly short
# we just code all categorical variables as dummy variables
fit_recipe <- 
  recipe(BodyTemp ~ ., data = train_data) %>%
  step_dummy(all_nominal()) 

#in this alternative recipe, we specify the ordered factors separately
#fit_recipe_2 <- 
 # recipe(BodyTemp ~ ., data = train_data) %>% 
  #step_ordinalscore(c("Weakness","CoughIntensity","Myalgia")) %>%



##########################
# tune different models
##########################

##########################
#tree model
tree_model <-  decision_tree() %>% 
  set_args( cost_complexity = tune(), tree_depth = tune()) %>% 
  set_engine("rpart") %>% 
  set_mode("regression")           

#workflow
tree_wf <- workflow() %>%
  add_model(tree_model) %>%
  add_recipe(fit_recipe)

#tuning grid
tree_grid <- dials::grid_regular(cost_complexity(),
                          tree_depth(),
                          levels = 5)
```

```
## Error in tree_depth(): could not find function "tree_depth"
```

```r
#tune the model
tree_tune_res <- tree_wf %>% 
  tune_grid(
    resamples = cv_data,
    grid = tree_grid,
    metrics = metric_set(rmse) 
  )
```

```
## Error in tune_grid(., resamples = cv_data, grid = tree_grid, metrics = metric_set(rmse)): could not find function "tune_grid"
```

```r
#see a plot of performance for different tuning parameters
tree_tune_res %>% autoplot()
```

```
## Error in autoplot(.): could not find function "autoplot"
```

```r
# get the tuned model that performs best 
best_tree <- tree_tune_res %>%  select_best(metric = "rmse")
```

```
## Error in select_best(., metric = "rmse"): could not find function "select_best"
```

```r
# finalize workflow with best model
final_wf <- tree_wf %>% finalize_workflow(best_tree)
```

```
## Error in finalize_workflow(., best_tree): could not find function "finalize_workflow"
```

```r
# fitting best performing model
final_fit <- final_wf %>% 
             fit(data = train_data)
```

```
## Error in fit(., data = train_data): object 'final_wf' not found
```

```r
tree_pred <- predict(final_fit, train_data)
```

```
## Error in predict(final_fit, train_data): object 'final_fit' not found
```

```r
#looking at predictions
plot(tree_pred$.pred,train_data$BodyTemp)
```

```
## Error in plot(tree_pred$.pred, train_data$BodyTemp): object 'tree_pred' not found
```

```r
collect_metrics
```

```
## Error in eval(expr, envir, enclos): object 'collect_metrics' not found
```

```r
##########################
# LASSO linear model

lr_model <- inear_reg() %>%
  set_mode("regression") %>%           
  set_engine("glmnet") %>%
  set_args(penalty = tune(), mixture = 1) #mixture = 1 means LASSO model
```

```
## Error in inear_reg(): could not find function "inear_reg"
```

```r
#workflow
lr_wf <- workflow() %>%
  add_model(lr_model) %>% 
  add_recipe(fit_recipe)
```

```
## Error in is_model_spec(spec): object 'lr_model' not found
```

```r
#tuning grid
lr_reg_grid <- tibble(penalty = 10^seq(-4, -1, length.out = 30))

#tune model
lr_tune_res <- lr_wf %>% 
  tune_grid(resamples = cv_data,
            grid = lr_reg_grid,
            control = control_grid(save_pred = TRUE),
            metrics = metric_set(rmse)
            )
```

```
## Error in tune_grid(., resamples = cv_data, grid = lr_reg_grid, control = control_grid(save_pred = TRUE), : could not find function "tune_grid"
```

```r
#see a plot of performance for different tuning parameters
lr_tune_res %>% autoplot()
```

```
## Error in autoplot(.): could not find function "autoplot"
```

```r
# get the tuned model that performs best 
best_lr <- lr_tune_res %>%  select_best(metric = "rmse")
```

```
## Error in select_best(., metric = "rmse"): could not find function "select_best"
```

```r
# finalize workflow with best model
final_wf <- lr_wf %>% finalize_workflow(best_lr)
```

```
## Error in finalize_workflow(., best_lr): could not find function "finalize_workflow"
```

```r
# fitting best performing model
final_fit <- final_wf %>% 
  fit(data = train_data)
```

```
## Error in fit(., data = train_data): object 'final_wf' not found
```

```r
lr_pred <- predict(final_fit, train_data)
```

```
## Error in predict(final_fit, train_data): object 'final_fit' not found
```

```r
#looking at predictions
plot(lr_pred$.pred,train_data$BodyTemp)
```

```
## Error in plot(lr_pred$.pred, train_data$BodyTemp): object 'lr_pred' not found
```

```r
##########################
# random forest model

#set number of cores to use for parallel running.
#not requrired but makes things faster
cores = 10 

rf_model <- rand_forest() %>%
  # specify that the `mtry` parameter needs to be tuned
  set_args(mtry = tune()) %>%
  # select the engine/package that underlies the model
  set_engine("ranger", num.threads = cores) %>%
  # choose either the continuous regression or binary classification mode
  set_mode("regression")           

#workflow
rf_wf <- workflow() %>%
  add_model(rf_model) %>% 
  add_recipe(fit_recipe)

#tuning grid
rf_grid <- expand.grid(mtry = c(3, 4, 5))

# tune the model, optimizing RMSE
rf_tune_res <- rf_workflow %>%
  tune_grid(
            resamples = cv_data, #CV object
            grid = rf_grid, # grid of values to try
            metrics = metric_set(rmse) 
  )
```

```
## Error in tune_grid(., resamples = cv_data, grid = rf_grid, metrics = metric_set(rmse)): could not find function "tune_grid"
```

```r
#see a plot of performance for different tuning parameters
rf_tune_res %>% autoplot()
```

```
## Error in autoplot(.): could not find function "autoplot"
```

```r
# get the tuned model that performs best 
rf_best <- rf_tune_res %>% select_best(metric = "rmse")
```

```
## Error in select_best(., metric = "rmse"): could not find function "select_best"
```

```r
########################
# Model Comparison
########################

# look at performance of each of the best models

# make predictions for training data, compare with actual data by checking residuals

# look at uncertainty in predictions




########################
# Final Model Evaluation
########################


# fit on the training set and evaluate on test set
final_fit <- rf_workflow %>%
  finalize_workflow(param_final)   %>%
  last_fit(data_split)
```

```
## Error in last_fit(., data_split): could not find function "last_fit"
```

```r
test_performance <- final_fit %>% collect_metrics()
```

```
## Error in collect_metrics(.): could not find function "collect_metrics"
```

```r
test_performance
```

```
## Error in eval(expr, envir, enclos): object 'test_performance' not found
```

```r
test_predictions <- final_fit %>% collect_predictions()
```

```
## Error in collect_predictions(.): could not find function "collect_predictions"
```

```r
##########################
#linear LASSO model
##########################
lin_mod <- linear_reg() %>% 
  set_engine("lm")


# make workflows

lin_workflow <- workflow() %>% 
  add_model(lin_mod) %>% 
  add_recipe(fit_recipe_1)
```

```
## Error in is_recipe(recipe): object 'fit_recipe_1' not found
```

```r
# tuning
lin_grid <- expand.grid(mtry = c(3, 4, 5))
# extract results
rf_tune_results <- rf_workflow %>%
  tune_grid(resamples = cv_data, #CV object
            grid = rf_grid, # grid of values to try
            metrics = metric_set(rmse) 
  )
```

```
## Error in tune_grid(., resamples = cv_data, grid = rf_grid, metrics = metric_set(rmse)): could not find function "tune_grid"
```

