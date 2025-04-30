
install.packages(c("tidyverse", "caret", "randomForest", "e1071", "actuar", "fitdistrplus", "glmnet", "pROC", "ROCR", "data.table"))

library(tidyverse)
library(caret)
library(randomForest)
library(e1071)
library(actuar)
library(fitdistrplus)
library(glmnet)
library(pROC)
library(ROCR)
library(data.table)

loan_data <- fread("https://raw.githubusercontent.com/veeranalytics/Credit-Risk-Model/master/loan_data.csv")

# Data cleaning
loan_data <- loan_data %>%
  mutate(
    annual_inc = as.numeric(gsub("[$,]", "", annual_inc)),
    loan_amnt = as.numeric(gsub("[$,]", "", loan_amnt)),
    int_rate = as.numeric(gsub("[%]", "", int_rate)),
    emp_length = as.numeric(gsub("[^0-9]", "", emp_length))
  ) %>%
  filter(!is.na(annual_inc) & !is.na(loan_amnt) & !is.na(int_rate) & !is.na(emp_length))

loan_data <- loan_data %>%
  mutate(default = ifelse(loan_status %in% c("Charged Off", "Default"), 1, 0)) %>%
  select(-loan_status)
# Summary statistics
summary(loan_data)

# Correlation matrix
cor_matrix <- cor(loan_data %>% select_if(is.numeric))
corrplot::corrplot(cor_matrix, method = "color", tl.cex = 0.8)
# Split data into training and testing sets
set.seed(123)
train_index <- createDataPartition(loan_data$default, p = 0.7, list = FALSE)
train_data <- loan_data[train_index, ]
test_data <- loan_data[-train_index, ]

# Fit logistic regression model
log_model <- glm(default ~ ., data = train_data, family = binomial)


pred_probs <- predict(log_model, newdata = test_data, type = "response")
pred_classes <- ifelse(pred_probs > 0.5, 1, 0)

# Evaluate model
conf_matrix <- confusionMatrix(factor(pred_classes), factor(test_data$default))
print(conf_matrix)
# Fit random forest model
rf_model <- randomForest(factor(default) ~ ., data = train_data, ntree = 100)

# Predict on test data
rf_preds <- predict(rf_model, newdata = test_data)

# Evaluate model
rf_conf_matrix <- confusionMatrix(rf_preds, factor(test_data$default))
print(rf_conf_matrix)

# Calculate LGD
loan_data <- loan_data %>%
  mutate(LGD = ifelse(default == 1, (loan_amnt - recoveries) / loan_amnt, 0))

# Fit beta distribution to LGD
lgd_data <- loan_data %>% filter(default == 1) %>% pull(LGD)
fit_beta <- fitdist(lgd_data, "beta", method = "mle")

# Plot fit
plot(fit_beta)

# Calculate EAD
loan_data <- loan_data %>%
  mutate(EAD = ifelse(default == 1, loan_amnt, 0))

# gamma distribution to EAD
ead_data <- loan_data %>% filter(default == 1) %>% pull(EAD)
fit_gamma <- fitdist(ead_data, "gamma", method = "mle")

# Plot fit
plot(fit_gamma)
# Calculate portfolio losses
portfolio_losses <- loan_data$EAD * loan_data$LGD

# Compute VaR at 95% confidence level
VaR_95 <- quantile(portfolio_losses, 0.95)
print(paste("VaR at 95% confidence level:", round(VaR_95, 2)))
# ROC for logistic regression
roc_obj <- roc(test_data$default, pred_probs)
auc_value <- auc(roc_obj)
plot(roc_obj, main = paste("ROC Curve (AUC =", round(auc_value, 2), ")"))
# Binning continuous variables
loan_data <- loan_data %>%
  mutate(
    inc_bin = cut(annual_inc, breaks = quantile(annual_inc, probs = seq(0, 1, 0.1)), include.lowest = TRUE),
    int_rate_bin = cut(int_rate, breaks = quantile(int_rate, probs = seq(0, 1, 0.1)), include.lowest = TRUE)
  )


# Simulate economic downturn by increasing default rates
loan_data_stress <- loan_data %>%
  mutate(default = ifelse(runif(n()) < 0.2, 1, default))

# Recalculate portfolio losses
portfolio_losses_stress <- loan_data_stress$EAD * loan_data_stress$LGD

# Compute stressed VaR at 95% confidence level
VaR_95_stress <- quantile(portfolio_losses_stress, 0.95)
print(paste("Stressed VaR at 95% confidence level:", round(VaR_95_stress, 2)))
