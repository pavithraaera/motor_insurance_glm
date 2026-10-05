# ============================================================
# Motor Insurance Claim Frequency Modelling using GLMs
# ============================================================

# 1. Load packages
library(MASS)
library(ggplot2)

# 2. Load data
data <- read.csv("freMTPL2freq.csv")

# 3. Basic data overview
dim(data)
str(data)
summary(data)

# 4. Check for missing values
colSums(is.na(data))

# 5. Overall claim frequency
total_claims <- sum(data$ClaimNb)
total_exposure <- sum(data$Exposure)

overall_frequency <- total_claims / total_exposure

total_claims
total_exposure
overall_frequency


# ============================================================
# 6. Create driver age groups
# ============================================================

data$AgeGroup <- cut(
  data$DrivAge,
  breaks = c(17, 25, 35, 45, 55, 65, 100),
  labels = c(
    "18-25", "26-35", "36-45",
    "46-55", "56-65", "66+"
  )
)


# ============================================================
# 7. Poisson GLM
# ============================================================

model_poisson <- glm(
  ClaimNb ~ DrivAge + VehAge + VehPower + BonusMalus +
    Area + VehGas + offset(log(Exposure)),
  data = data,
  family = poisson(link = "log")
)

summary(model_poisson)


# ============================================================
# 8. Check for overdispersion
# ============================================================

pearson_dispersion <- sum(
  residuals(model_poisson, type = "pearson")^2
) / df.residual(model_poisson)

pearson_dispersion


# ============================================================
# 9. Negative Binomial GLM
# ============================================================

model_nb <- glm.nb(
  ClaimNb ~ DrivAge + VehAge + VehPower + BonusMalus +
    Area + VehGas + offset(log(Exposure)),
  data = data
)

summary(model_nb)


# ============================================================
# 10. Negative Binomial model with age groups
# ============================================================

model_nb_age <- glm.nb(
  ClaimNb ~ AgeGroup + VehAge + VehPower + BonusMalus +
    Area + VehGas + offset(log(Exposure)),
  data = data
)

summary(model_nb_age)


# ============================================================
# 11. Model comparison
# ============================================================

AIC(model_poisson, model_nb, model_nb_age)


# ============================================================
# 12. Final model relativities
# ============================================================

final_results <- data.frame(
  Term = names(coef(model_nb_age)),
  Estimate = coef(model_nb_age),
  Relativity = exp(coef(model_nb_age)),
  P_value = summary(model_nb_age)$coefficients[, 4]
)

final_results$Estimate <- round(final_results$Estimate, 4)
final_results$Relativity <- round(final_results$Relativity, 4)
final_results$P_value <- round(final_results$P_value, 4)

final_results


# ============================================================
# 13. Final model dispersion
# ============================================================

pearson_final <- sum(
  residuals(model_nb_age, type = "pearson")^2
) / df.residual(model_nb_age)

pearson_final


# ============================================================
# 14. Claim frequency by driver age group
# ============================================================

age_freq <- aggregate(
  cbind(ClaimNb, Exposure) ~ AgeGroup,
  data = data,
  FUN = sum
)

age_freq$Frequency <- age_freq$ClaimNb / age_freq$Exposure

p_age <- ggplot(
  age_freq,
  aes(x = AgeGroup, y = Frequency)
) +
  geom_col() +
  labs(
    title = "Observed Claim Frequency by Driver Age Group",
    x = "Driver Age Group",
    y = "Claim Frequency"
  ) +
  theme_minimal()

p_age

ggsave(
  "claim_frequency_age.png",
  plot = p_age,
  width = 8,
  height = 5,
  dpi = 300
)


# ============================================================
# 15. Claim frequency by Bonus-Malus band
# ============================================================

data$BMGroup <- cut(
  data$BonusMalus,
  breaks = c(0, 50, 75, 100, 125, 150, 200),
  labels = c(
    "≤50", "51-75", "76-100",
    "101-125", "126-150", "151+"
  ),
  include.lowest = TRUE
)

bm_freq <- aggregate(
  cbind(ClaimNb, Exposure) ~ BMGroup,
  data = data,
  FUN = sum
)

bm_freq$Frequency <- bm_freq$ClaimNb / bm_freq$Exposure

p_bm <- ggplot(
  bm_freq,
  aes(x = BMGroup, y = Frequency)
) +
  geom_col() +
  labs(
    title = "Observed Claim Frequency by Bonus-Malus Band",
    x = "Bonus-Malus Band",
    y = "Claim Frequency"
  ) +
  theme_minimal()

p_bm

ggsave(
  "claim_frequency_bonus_malus.png",
  plot = p_bm,
  width = 8,
  height = 5,
  dpi = 300
)