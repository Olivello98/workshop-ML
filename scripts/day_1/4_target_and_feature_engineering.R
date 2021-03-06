## Target and feature engineering
library(tidyverse)
library(gridExtra)
library(AmesHousing)
library(caret)
library(rsample)
library(recipes)


KULbg <- "#116E8A"


## ----------------------------------------------------------------------------------------------
set.seed(123)  
split  <- rsample::initial_split(ames, prop = 0.7, strata = "Sale_Price")
ames_train  <- rsample::training(split)
ames_test   <- rsample::testing(split)


## ----------------------------------------------------------------------------------------------
summary(ames_train$Sale_Price)
summary(ames_test$Sale_Price)

## ----Your Turn---------------------------------------------------------------------------------
## ----two-linear-models-------------------------------------------------------------------------





## ----Your Turn ends here-----------------------------------------------------------------------
## ----------------------------------------------------------------------------------------------

## ----------------------------------------------------------------------------------------------
ames_train %>% group_by(Neighborhood) %>% 
  summarize(n_obs = n()) %>% arrange(n_obs) %>% slice(1:4) 


## ----------------------------------------------------------------------------------------------
df <- ames_train %>% group_by(Neighborhood) %>% 
  summarize(n_obs = n()) %>% arrange(n_obs)

ggplot(ames_train, aes(x = fct_infreq(Neighborhood))) + theme_bw() +
  geom_bar(col = KULbg, fill = KULbg, alpha = .5) + 
  coord_flip() + 
  xlab("") 


## ----------------------------------------------------------------------------------------------
mod_rec <- recipe(Sale_Price ~ ., data = ames_train)
mod_rec


## ----------------------------------------------------------------------------------------------
mod_rec <- mod_rec %>% step_log(all_outcomes()) %>%
  step_other(Neighborhood, threshold = 0.05)
mod_rec


## ----trained_recipe----------------------------------------------------------------------------
mod_rec_trained <- prep(mod_rec, training = ames_train, verbose = TRUE, retain = TRUE)
mod_rec_trained


## ----------------------------------------------------------------------------------------------
ames_test_prep <- bake(mod_rec_trained, new_data = ames_test)


## ----------------------------------------------------------------------------------------------
ames_test_prep %>% group_by(Neighborhood) %>% 
  summarize(n_obs = n()) %>% 
  arrange(n_obs) 


## ----------------------------------------------------------------------------------------------
juice(mod_rec_trained) %>% group_by(Neighborhood) %>% 
  summarize(n_obs = n()) %>% 
  arrange(n_obs) 

## ----Your Turn---------------------------------------------------------------------------------
## ----------------------------------------------------------------------------------------------




## ----Your Turn ends here------------------------------------------------------------------------
## -----------------------------------------------------------------------------------------------


## ----------------------------------------------------------------------------------------------
# get the simulated data
set.seed(123)  # for reproducibility
x <- seq(from = 0, to = 2 * pi, length = 500)
y <- sin(x) + rnorm(length(x), sd = 0.3)
df <- data.frame(x, y) %>% filter(x < 4.5)


## ----------------------------------------------------------------------------------------------
# specify the recipe
rec <- recipe(y ~ x, data = df)
rec <- rec %>% step_center(all_predictors()) %>%
  step_scale(all_predictors())


## ----------------------------------------------------------------------------------------------
# doing this on complete data set df
rec_df <- prep(rec, training = df)
mean(juice(rec_df)$x) # centered!
sd(juice(rec_df)$x)   # scaled!


## ----------------------------------------------------------------------------------------------
# now we combine the recipe with rsample steps
set.seed(123)  # for reproducibility
cv_rsample <- vfold_cv(df, 5)


## ----------------------------------------------------------------------------------------------
# we apply the steps in the recipe to each fold
cv_rsample$recipes <- map(cv_rsample$splits, prepper, 
                          recipe = rec)
# check `?prepper`


## ----------------------------------------------------------------------------------------------
cv_rsample$recipes[[1]]
juice(cv_rsample$recipes[[1]])
bake(cv_rsample$recipes[[1]],
      new_data = assessment(cv_rsample$splits[[1]]))


## ----------------------------------------------------------------------------------------------
holdout_results <- function(s, rec, k_val) {
  # Fit the model to the analysis data in split s
  df_train <- juice(rec)
  mod <- knnreg(y ~ x, k = k_val, data = df_train)
  # Get the remaining group
  holdout <- bake(rec, new_data = assessment(s))
  # Get predictions with the holdout data set
  res <- predict(mod, newdata = holdout)
  # Return observed and predicted values 
  #                            on holdout set
  res <- tibble(obs = holdout$y, pred = res)
  res
}


## ----------------------------------------------------------------------------------------------
res <- holdout_results(cv_rsample$splits[[2]], 
                       cv_rsample$recipes[[2]], 
                       k_val = 58)
sqrt(sum((res$obs - res$pred)^2)/nrow(res))


## ----------------------------------------------------------------------------------------------
RMSE <- numeric(nrow(hyper_grid))
SE <- numeric(nrow(hyper_grid))
for(i in 1:nrow(hyper_grid)){
  cv_rsample$results <- map2(cv_rsample$splits, cv_rsample$recipes,
                             holdout_results,
                             hyper_grid[i, ])
  res <- map_dbl(cv_rsample$results, 
                 function(x) mean((x$obs - x$pred)^2))
  RMSE[i] <- mean(sqrt(res)) ; SE[i] <- sd(sqrt(res))
}