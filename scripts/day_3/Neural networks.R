#### Getting started ####

# Load packages
require(keras)
require(tidyverse)

# ---- Tensor functions --------------------------------------------------------------------------

x <- k_constant(c(1,2,3,4), 
                shape = c(2,2))
x

k_mean(x, axis = 1)

k_mean(x, axis = 2)

y <- k_constant(c(1,2,3,4,5,6,7,8), 
                shape = c(2,2,2))

k_mean(y, axis = 1)

## ----------------------------------------------------------------------------------------------
## ----Your Turn---------------------------------------------------------------------------------


## ----Your Turn ends here-----------------------------------------------------------------------
## ----------------------------------------------------------------------------------------------

#### Neural network fundamentals ####

# ---- Loading MNIST --------------------------------------------------------------------------


# download the dataset from the online repository
#mnist <- dataset_mnist()
# load the dataset from the course files
load('data/mnist.RData')

# create new variables for the input and output data
input <- mnist$train$x
output <- mnist$train$y
test_input <- mnist$test$x
test_output <- mnist$test$y

class(input)
dim(input)

# ---- Preparing MNIST --------------------------------------------------------------------------

# normalize the input data and 
# convert the matrix structure into a vector
input <- array_reshape(input, 
                       c(nrow(input), 28*28)) / 255
test_input <- array_reshape(test_input, 
                            c(nrow(test_input), 28*28)) / 255

# create 10 dummy variables for the digits (0-9)
output <- to_categorical(output, 10)
test_output <- to_categorical(test_output, 10)

# function for plotting images from the mnist dataset.
plot_image <- function(data, legend = TRUE) {
  dimension <- sqrt(length(data))
  df <- data.frame(col = rep(1:dimension, dimension), row = rep(dimension:1, each = dimension), value = data);
  figure <- ggplot(df) +
    theme_void() +
    xlab('') + ylab('') +
    geom_raster(aes(x = col, y = row, fill = value))
  
  if(all(data >= 0)) {
    figure <- figure + scale_fill_gradient(high = 'white', low = 'black')
  } else {
    figure <- figure + scale_fill_gradient2(low = 'red', mid = 'black', high = 'green', midpoint = 0)
  }
  
  if(!legend) {
    figure <- figure + theme(legend.position = 'none')
  }
  
  return(figure)
}

plot_image(input[17, ])


## ----------------------------------------------------------------------------------------------
## ----Your Turn---------------------------------------------------------------------------------
## Fill in the blanks to construct your first neural network for the MNIST dataset

model <- keras_model_sequential() %>%
  layer_dense(units = ,
              activation = ,
              input_shape = ) %>%
  layer_dense(units = ,
              activation = )

summary(model)

model <- model %>%
  compile(loss = ,
          optimize = ,
          metrics = c('accuracy'))

model %>%
  fit(,
      ,
      batch_size = , 
      epochs = , 
      validation_split = )

## ----Your Turn ends here-----------------------------------------------------------------------
## ----------------------------------------------------------------------------------------------

## ----------------------------------------------------------------------------------------------
## ----Your Turn---------------------------------------------------------------------------------
## Evaluate the model that you constructed

## ----Your Turn ends here-----------------------------------------------------------------------
## ----------------------------------------------------------------------------------------------


# ---- Visualizing the weight matrix ------------------------------------------------------------

node <- 9
layer <- 1
weights <- model$weights[[2*(layer-1) + 1]][, node]
plot_image(as.numeric(weights))

#### ---- Auto encoders -------------------------------------------------------------------------

## ----------------------------------------------------------------------------------------------
## ----Your Turn---------------------------------------------------------------------------------
## Implement your own auto encoder

## ----Your Turn ends here-----------------------------------------------------------------------
## ----------------------------------------------------------------------------------------------


# ---- Evaluating model performance -------------------------------------------------------------

result <- predict(model, input[1, , drop = FALSE])
plot_image(input[1, ]) # the original image
plot_image(result[1, ]) # the reconstruction of the model

# test on random data
random <- matrix(runif(28^2), nrow = 1)
grid.arrange(
  plot_image(random[1, ]) + theme(legend.position = 'none'),
  plot_image(predict(model, random)[1, ]) + theme(legend.position = 'none'),
  nrow = 1)

#### ---- Convolutional neural networks (CNN) ---------------------------------------------------

# ---- Illustraing the function of a kernel -----------------------------------------------------

img <- mnist$train$x[3,,] / 255
img <- img[28:1, ]

kernel <- data.frame(x = c(1, 2, 3, 1, 2, 3, 1, 2, 3), y = c(1, 1, 1, 2, 2, 2, 3, 3, 3), z = c(1, 1, -2, 1, 1, -2, 1, 1, -2))

ggplot(kernel, aes(x, y)) +
  theme_void() +
  geom_tile(aes(fill = z), color = 'black', size = 1) + 
  scale_fill_gradient2(low = '#a83232', mid = 'black', high = '#32a866', midpoint = 0) +
  theme(legend.position = 'none') +
  geom_text(aes(x = x, y = y, label = round(z, 1)), color = 'black', size = 10)


kern <- matrix(c(1, 1, -2, 1, 1, -2, 1, 1, -2), nrow = 3, ncol = 3, byrow = TRUE)

result <- matrix(nrow = 26, ncol = 26)
for(i in 1:26) {
  for(j in 1:26) {
    result[i, j] <- sum(img[i:(i+2), j:(j+2)] * kern)
  }
}

df <- data.frame(x = as.numeric(col(result)), y = as.numeric(row(result)), z = as.numeric(result))

ggplot(df, aes(x, y)) +
  theme_void() +
  geom_tile(aes(fill = z), color = 'black', size = 1) + 
  scale_fill_gradient2(low = '#a83232', mid = 'black', high = '#32a866', midpoint = 0) +
  theme(legend.position = 'none') 

## ----------------------------------------------------------------------------------------------
## ----Your Turn---------------------------------------------------------------------------------
## Fit and evaluate a convolutional neural network

# data preparation
input_conv <- mnist$train$x / 255
test_input_conv <- mnist$test$x / 255

# We add a fourth dimension, such that one data point has size (28x28x1)
input_conv <- k_expand_dims(input_conv, axis = 4)
test_input_conv <- k_expand_dims(test_input_conv, axis = 4)

## ----Your Turn ends here-----------------------------------------------------------------------
## ----------------------------------------------------------------------------------------------


# ---- Evaluating the model ---------------------------------------------------------------------

# misclassification
prediction <- model %>% predict(test_input_conv)
category <- apply(prediction, 1, which.max)-1
actual_category <- apply(test_output, 1, which.max)-1
head(which(actual_category != category))

plot_image(test_input[93, ])

# on random data
random <- runif(28*28)
random_conv <- matrix(random, nrow = 28, ncol = 28)
random_conv <- k_expand_dims(random_conv, axis = 1)
random_conv <- k_expand_dims(random_conv, axis = 4)

plot_image(random)
predict(model, random_conv)

## visualizing the kernel
require(tidyverse)
require(gridExtra)
weights <- map(1:8, function(x) {plot_image(as.numeric(model$weights[[1]][,,,x]), FALSE)})
weights[['nrow']] <- 2
do.call(grid.arrange, weights)

#### ---- Regression ----------------------------------------------------------------

## data preparation
mtpl_orig <- read.table('./data/P&Cdata.txt', 
                        header = TRUE)
mtpl_orig <- as_tibble(mtpl_orig)
mtpl <- mtpl_orig %>%
  rename_all(function(.name) {.name %>% tolower })

require(rsample)
data_split <- initial_split(mtpl)
mtpl_train <- training(data_split)
mtpl_test  <- testing(data_split)
mtpl_train <- mtpl_train[sample(nrow(mtpl_train)), ]

## neural network:
claim_count_model <- keras_model_sequential() %>%
  layer_dense(units = 1, 
              activation = 'exponential', 
              input_shape = c(1), 
              use_bias = FALSE) %>%
  compile(loss = 'poisson',
          optimize = optimizer_rmsprop(),
          metrics = c('mse'))

## more data preparation

# (n x 1) matrix of constant one.
input <- matrix(1, 
                nrow = nrow(mtpl_train), 
                ncol = 1)
input_test <- matrix(1, 
                     nrow = nrow(mtpl_test), 
                     ncol = 1)
# (n x 1) matrix with the claim counts
output <- matrix(mtpl_train %>% pull(nclaims), 
                 nrow = nrow(mtpl_train), 
                 ncol = 1)
output_test <- matrix(mtpl_test %>% pull(nclaims), 
                      nrow = nrow(mtpl_test), 
                      ncol = 1)

## Fit the model

claim_count_model %>% fit(input, 
                          output, 
                          epochs = 20,
                          batch_size = 1024, 
                          validation_split = 0)

## glm comparison

glm_fit <- glm(nclaims ~ 1, 
               data = mtpl_train, 
               family = poisson(link = log))
glm_fit
claim_count_model$weights

poisson_loss <- function(pred, actual) {
  mean(pred - actual * log(pred))
}

poisson_loss(predict(glm_fit, 
                     mtpl_test, 
                     type = 'response'), 
             mtpl_test$nclaims)

evaluate(claim_count_model, 
         input_test, 
         output_test, 
         verbose = FALSE)

## ----------------------------------------------------------------------------------------------
## ----Your Turn---------------------------------------------------------------------------------
## Implement a binomial GLM as a neural network

## ----Your Turn ends here-----------------------------------------------------------------------
## ----------------------------------------------------------------------------------------------


# ---- Adding exposure ---------------------------------------------------------------------

glm(nclaims ~ offset(log(expo)) + ageph, family = poisson, data = mtpl_train)
glm(nclaims / expo ~ ageph, family = poisson, data = mtpl_train, weights = expo)

exposure <- as.numeric(mtpl_train  %>% pull(expo),
                       nrow = nrow(mtpl_train),
                       ncol = 1)

claim_count_model <- keras_model_sequential() %>%
  layer_dense(units = 1, 
              activation = 'exponential', 
              input_shape = c(1), 
              use_bias = FALSE) %>%
  compile(loss = 'poisson',
          optimize = optimizer_rmsprop(),
          metrics = c('mse')) 

claim_count_model %>%
  fit(input, 
      output / exposure,
      epochs = 20, 
      batch_size = 1024, 
      validation_split = 0, 
      sample_weight = exposure)

exposure_test <- k_constant(mtpl_test %>% pull(expo),
                            shape = c(nrow(mtpl_test)))
claim_count_model %>%
  evaluate(input_test,
           output_test,
           sample_weight = exposure_test,
           verbose = FALSE)

# ---- Adding predictors ---------------------------------------------------------------------

input <- matrix(mtpl_train %>% pull(ageph), 
                nrow = nrow(mtpl_train), 
                ncol = 1)

claim_count_model <- keras_model_sequential() %>%
  layer_batch_normalization(input_shape = c(1)) %>%
  layer_dense(units = 5, activation = 'relu') %>%
  layer_dense(units = 1, 
              activation = 'exponential', 
              use_bias = TRUE) %>%
  compile(loss = 'poisson',
          optimize = optimizer_rmsprop(),
          metrics = c('mse'))

claim_count_model %>%
  fit(input, 
      output / exposure,
      epochs = 20, 
      batch_size = 1024, 
      validation_split = 0.2,
      sample_weight = exposure)

age <- 18:100 + 0.001
age_effect <- log(claim_count_model %>%
                    predict(age))
ggplot() +
  theme_bw() +
  geom_point(aes(age, age_effect))

require(mgcv)
gam_age <- gam(nclaims/exposure ~ s(ageph), 
               data = mtpl_train, 
               family = poisson, 
               weights = exposure)
df <- data.frame(ageph = age)
age_effect_gam <- log(
  predict(gam_age, 
          newdata = data.frame(ageph = age), 
          type = 'response'))

ggplot() +
  theme_bw() +
  geom_point(aes(age, age_effect, color = 'neural network')) +
  geom_point(aes(age, age_effect_gam, color = 'gam'))

#### ---- Case study ---------------------------------------------------------------------------

mtpl_orig <- read.table('./data/P&Cdata.txt', 
                        header = TRUE)
mtpl_orig <- as_tibble(mtpl_orig)
mtpl <- mtpl_orig %>%
  rename_all(function(.name) {.name %>% tolower })

## ----------------------------------------------------------------------------------------------
## ----Your Turn---------------------------------------------------------------------------------
## Case study

## ----Your Turn ends here-----------------------------------------------------------------------
## ----------------------------------------------------------------------------------------------
