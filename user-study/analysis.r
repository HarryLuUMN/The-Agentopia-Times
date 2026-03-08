# Statistical Analysis: Control vs Treatment Groups
# Comparing pre-post differences in correct answers

# Load required libraries
library(dplyr)
library(ggplot2)
library(car)  # For repeated measures ANOVA

# Read the data
control <- read.csv("control.csv", stringsAsFactors = FALSE)
treatment <- read.csv("treatment.csv", stringsAsFactors = FALSE)

# Clean the data - remove percentage signs and convert to numeric
clean_percentage <- function(x) {
  as.numeric(gsub("%", "", x))
}

# Extract differences column (remove last row if it's a summary)
control_diff <- clean_percentage(control$Differences[1:(nrow(control)-1)])
treatment_diff <- clean_percentage(treatment$Differences[1:nrow(treatment)])

# Also extract pre and post scores for more detailed analysis
control_pre <- clean_percentage(control$Correct.pre[1:(nrow(control)-1)])
control_post <- clean_percentage(control$Correct.post[1:(nrow(control)-1)])
treatment_pre <- clean_percentage(treatment$Correct.pre[1:nrow(treatment)])
treatment_post <- clean_percentage(treatment$Correct.post[1:nrow(treatment)])

# Create data frames for easier analysis
control_df <- data.frame(
  group = "Control",
  pre = control_pre,
  post = control_post,
  difference = control_diff
)

treatment_df <- data.frame(
  group = "Treatment",
  pre = treatment_pre,
  post = treatment_post,
  difference = treatment_diff
)

combined_df <- rbind(control_df, treatment_df)

# ============================================
# DESCRIPTIVE STATISTICS
# ============================================
cat("\n=== DESCRIPTIVE STATISTICS ===\n\n")

cat("CONTROL GROUP:\n")
cat(sprintf("  Sample size: %d\n", length(control_diff)))
cat(sprintf("  Mean difference: %.2f%%\n", mean(control_diff)))
cat(sprintf("  Median difference: %.2f%%\n", median(control_diff)))
cat(sprintf("  SD: %.2f%%\n", sd(control_diff)))
cat(sprintf("  Min: %.2f%%\n", min(control_diff)))
cat(sprintf("  Max: %.2f%%\n", max(control_diff)))
cat(sprintf("  Mean pre-score: %.2f%%\n", mean(control_pre)))
cat(sprintf("  Mean post-score: %.2f%%\n", mean(control_post)))

cat("\nTREATMENT GROUP:\n")
cat(sprintf("  Sample size: %d\n", length(treatment_diff)))
cat(sprintf("  Mean difference: %.2f%%\n", mean(treatment_diff)))
cat(sprintf("  Median difference: %.2f%%\n", median(treatment_diff)))
cat(sprintf("  SD: %.2f%%\n", sd(treatment_diff)))
cat(sprintf("  Min: %.2f%%\n", min(treatment_diff)))
cat(sprintf("  Max: %.2f%%\n", max(treatment_diff)))
cat(sprintf("  Mean pre-score: %.2f%%\n", mean(treatment_pre)))
cat(sprintf("  Mean post-score: %.2f%%\n", mean(treatment_post)))

# ============================================
# STATISTICAL TESTS
# ============================================
cat("\n=== STATISTICAL TESTS ===\n\n")

# Test for normality (Shapiro-Wilk test)
shapiro_control <- shapiro.test(control_diff)
shapiro_treatment <- shapiro.test(treatment_diff)

cat("NORMALITY TESTS (Shapiro-Wilk):\n")
cat(sprintf("  Control group: W = %.4f, p = %.4f\n", 
            shapiro_control$statistic, shapiro_control$p.value))
cat(sprintf("  Treatment group: W = %.4f, p = %.4f\n", 
            shapiro_treatment$statistic, shapiro_treatment$p.value))

if (shapiro_control$p.value < 0.05 || shapiro_treatment$p.value < 0.05) {
  cat("  -> Data may not be normally distributed\n")
} else {
  cat("  -> Data appears normally distributed\n")
}

# Test for equal variances (Levene's test via F-test)
var_test <- var.test(control_diff, treatment_diff)
cat(sprintf("\nEQUAL VARIANCES TEST (F-test):\n"))
cat(sprintf("  F = %.4f, p = %.4f\n", var_test$statistic, var_test$p.value))
if (var_test$p.value < 0.05) {
  cat("  -> Variances are significantly different (use Welch's t-test)\n")
} else {
  cat("  -> Variances are not significantly different\n")
}

# ============================================
# PAIRED T-TEST (within-group pre-post comparison)
# ============================================
cat("\n=== PAIRED T-TEST RESULTS (Pre vs Post within each group) ===\n\n")

# Paired t-test for Control group
paired_control <- t.test(control_post, control_pre, paired = TRUE)
paired_control_1t <- t.test(control_post, control_pre, paired = TRUE, alternative = "greater")

cat("CONTROL GROUP (Pre vs Post):\n")
cat("  Two-tailed paired t-test:\n")
cat(sprintf("    t = %.4f, df = %d, p = %.6f\n", 
            paired_control$statistic, paired_control$parameter, paired_control$p.value))
cat(sprintf("    Mean difference (Post - Pre): %.2f%%\n", 
            mean(control_post) - mean(control_pre)))
cat(sprintf("    95%% CI: [%.2f%%, %.2f%%]\n", 
            paired_control$conf.int[1], paired_control$conf.int[2]))
if (paired_control$p.value < 0.001) {
  cat("    -> HIGHLY SIGNIFICANT (p < 0.001) ***\n")
} else if (paired_control$p.value < 0.01) {
  cat("    -> VERY SIGNIFICANT (p < 0.01) **\n")
} else if (paired_control$p.value < 0.05) {
  cat("    -> SIGNIFICANT (p < 0.05) *\n")
} else {
  cat("    -> NOT SIGNIFICANT (p >= 0.05)\n")
}

cat("\n  One-tailed paired t-test (Post > Pre):\n")
cat(sprintf("    t = %.4f, df = %d, p = %.6f\n", 
            paired_control_1t$statistic, paired_control_1t$parameter, paired_control_1t$p.value))
cat(sprintf("    95%% CI: [%.2f%%, Inf]\n", 
            paired_control_1t$conf.int[1]))
if (paired_control_1t$p.value < 0.05) {
  cat("    -> SIGNIFICANT: Post significantly greater than Pre\n")
} else {
  cat("    -> NOT SIGNIFICANT: No significant improvement\n")
}

# Paired t-test for Treatment group
paired_treatment <- t.test(treatment_post, treatment_pre, paired = TRUE)
paired_treatment_1t <- t.test(treatment_post, treatment_pre, paired = TRUE, alternative = "greater")

cat("\nTREATMENT GROUP (Pre vs Post):\n")
cat("  Two-tailed paired t-test:\n")
cat(sprintf("    t = %.4f, df = %d, p = %.6f\n", 
            paired_treatment$statistic, paired_treatment$parameter, paired_treatment$p.value))
cat(sprintf("    Mean difference (Post - Pre): %.2f%%\n", 
            mean(treatment_post) - mean(treatment_pre)))
cat(sprintf("    95%% CI: [%.2f%%, %.2f%%]\n", 
            paired_treatment$conf.int[1], paired_treatment$conf.int[2]))
if (paired_treatment$p.value < 0.001) {
  cat("    -> HIGHLY SIGNIFICANT (p < 0.001) ***\n")
} else if (paired_treatment$p.value < 0.01) {
  cat("    -> VERY SIGNIFICANT (p < 0.01) **\n")
} else if (paired_treatment$p.value < 0.05) {
  cat("    -> SIGNIFICANT (p < 0.05) *\n")
} else {
  cat("    -> NOT SIGNIFICANT (p >= 0.05)\n")
}

cat("\n  One-tailed paired t-test (Post > Pre):\n")
cat(sprintf("    t = %.4f, df = %d, p = %.6f\n", 
            paired_treatment_1t$statistic, paired_treatment_1t$parameter, paired_treatment_1t$p.value))
cat(sprintf("    95%% CI: [%.2f%%, Inf]\n", 
            paired_treatment_1t$conf.int[1]))
if (paired_treatment_1t$p.value < 0.05) {
  cat("    -> SIGNIFICANT: Post significantly greater than Pre\n")
} else {
  cat("    -> NOT SIGNIFICANT: No significant improvement\n")
}

# ============================================
# INDEPENDENT SAMPLES T-TEST (between-group comparison)
# ============================================
# Independent samples t-test (parametric)
# Student's t-test (equal variances assumed)
t_test_student_2t <- t.test(control_diff, treatment_diff, var.equal = TRUE)
t_test_student_1t <- t.test(control_diff, treatment_diff, var.equal = TRUE, alternative = "less")
t_test_welch <- t.test(control_diff, treatment_diff, var.equal = FALSE)

cat("\n=== INDEPENDENT SAMPLES T-TEST RESULTS (Between-group comparison) ===\n")
cat("\n1. STUDENT'S T-TEST (equal variances assumed, two-tailed):\n")
cat(sprintf("   t = %.4f, df = %d, p = %.6f\n", 
            t_test_student_2t$statistic, t_test_student_2t$parameter, t_test_student_2t$p.value))
cat(sprintf("   95%% CI: [%.2f%%, %.2f%%]\n", 
            t_test_student_2t$conf.int[1], t_test_student_2t$conf.int[2]))
if (t_test_student_2t$p.value < 0.05) {
  cat("   -> SIGNIFICANT (p < 0.05) *\n")
} else {
  cat("   -> NOT SIGNIFICANT (p >= 0.05)\n")
}

cat("\n2. STUDENT'S T-TEST (equal variances assumed, one-tailed, Treatment > Control):\n")
cat(sprintf("   t = %.4f, df = %d, p = %.6f\n", 
            t_test_student_1t$statistic, t_test_student_1t$parameter, t_test_student_1t$p.value))
cat(sprintf("   95%% CI: [-Inf, %.2f%%]\n", 
            t_test_student_1t$conf.int[2]))
if (t_test_student_1t$p.value < 0.05) {
  cat("   -> SIGNIFICANT (p < 0.05) *\n")
} else {
  cat("   -> NOT SIGNIFICANT (p >= 0.05)\n")
}

cat("\n3. WELCH'S T-TEST (unequal variances, two-tailed):\n")
cat(sprintf("   t = %.4f, df = %.2f, p = %.6f\n", 
            t_test_welch$statistic, t_test_welch$parameter, t_test_welch$p.value))
cat(sprintf("   95%% CI: [%.2f%%, %.2f%%]\n", 
            t_test_welch$conf.int[1], t_test_welch$conf.int[2]))
if (t_test_welch$p.value < 0.05) {
  cat("   -> SIGNIFICANT (p < 0.05) *\n")
} else {
  cat("   -> NOT SIGNIFICANT (p >= 0.05)\n")
}

# Mann-Whitney U test / Wilcoxon rank-sum test (non-parametric)
# Use exact=FALSE to handle ties and get approximate p-value
mw_test <- wilcox.test(control_diff, treatment_diff, exact = FALSE, conf.int = TRUE)

cat("\nWILCOXON RANK-SUM TEST / MANN-WHITNEY U TEST (non-parametric, two-tailed):\n")
cat(sprintf("  W statistic = %.2f\n", mw_test$statistic))
cat(sprintf("  p-value = %.6f\n", mw_test$p.value))
if (!is.null(mw_test$conf.int)) {
  cat(sprintf("  95%% CI for location shift: [%.2f%%, %.2f%%]\n", 
              mw_test$conf.int[1], mw_test$conf.int[2]))
}
cat("  Note: Using normal approximation due to ties in data\n")

# One-tailed Wilcoxon test (testing if treatment > control)
mw_test_onetail <- wilcox.test(control_diff, treatment_diff, exact = FALSE, 
                                alternative = "less", conf.int = TRUE)

cat("\nWILCOXON RANK-SUM TEST (one-tailed, testing Treatment > Control):\n")
cat(sprintf("  W statistic = %.2f\n", mw_test_onetail$statistic))
cat(sprintf("  p-value (one-tailed) = %.6f\n", mw_test_onetail$p.value))
if (!is.null(mw_test_onetail$conf.int)) {
  cat(sprintf("  95%% CI for location shift: [%.2f%%, Inf]\n", 
              mw_test_onetail$conf.int[1]))
}
if (mw_test_onetail$p.value < 0.05) {
  cat("  -> SIGNIFICANT: Treatment group shows significantly greater improvement\n")
} else {
  cat("  -> NOT SIGNIFICANT: No significant evidence that treatment > control\n")
}
cat("  Note: One-tailed test is more powerful for directional hypotheses\n")

# Effect size (Cohen's d)
cohens_d <- function(x, y) {
  mean_diff <- mean(x) - mean(y)
  pooled_sd <- sqrt(((length(x) - 1) * var(x) + (length(y) - 1) * var(y)) / 
                     (length(x) + length(y) - 2))
  return(mean_diff / pooled_sd)
}

effect_size <- cohens_d(treatment_diff, control_diff)
cat("\nEFFECT SIZE (Cohen's d):\n")
cat(sprintf("  d = %.4f\n", effect_size))
if (abs(effect_size) < 0.2) {
  cat("  -> Negligible effect\n")
} else if (abs(effect_size) < 0.5) {
  cat("  -> Small effect\n")
} else if (abs(effect_size) < 0.8) {
  cat("  -> Medium effect\n")
} else {
  cat("  -> Large effect\n")
}

# ============================================
# ANOVA ANALYSIS
# ============================================
cat("\n=== ANOVA ANALYSIS ===\n\n")

# Prepare data for repeated measures ANOVA
# Create long format data
n_control <- length(control_pre)
n_treatment <- length(treatment_pre)

anova_data <- data.frame(
  Subject = c(1:n_control, 1:n_treatment, 1:n_control, 1:n_treatment),
  Group = factor(c(rep("Control", n_control), rep("Treatment", n_treatment),
                   rep("Control", n_control), rep("Treatment", n_treatment))),
  Time = factor(c(rep("Pre", n_control + n_treatment), 
                  rep("Post", n_control + n_treatment))),
  Score = c(control_pre, treatment_pre, control_post, treatment_post)
)

# Mixed-design ANOVA (between-subjects: Group, within-subjects: Time)
cat("MIXED-DESIGN ANOVA (Group × Time):\n")
cat("  Between-subjects factor: Group (Control vs Treatment)\n")
cat("  Within-subjects factor: Time (Pre vs Post)\n\n")

# Fit the ANOVA model
aov_model <- aov(Score ~ Group * Time + Error(Subject/Time), data = anova_data)
aov_summary <- summary(aov_model)

# Extract results
cat("ANOVA Results:\n")

# Print full summary for debugging
# cat("\nFull ANOVA Summary:\n")
# print(aov_summary)

# Main effect of Group
if ("Error: Subject" %in% names(aov_summary)) {
  group_effect <- aov_summary[["Error: Subject"]][[1]]
  if ("Group" %in% rownames(group_effect)) {
    cat("\n  Main Effect of Group:\n")
    cat(sprintf("    F(%d, %d) = %.4f, p = %.6f\n",
                group_effect["Group", "Df"],
                group_effect["Residuals", "Df"],
                group_effect["Group", "F value"],
                group_effect["Group", "Pr(>F)"]))
    if (group_effect["Group", "Pr(>F)"] < 0.05) {
      cat("    -> SIGNIFICANT: Groups differ significantly\n")
    } else {
      cat("    -> NOT SIGNIFICANT: No significant difference between groups\n")
    }
  } else {
    cat("\n  Main Effect of Group: Not available in this model structure\n")
  }
}

# Main effect of Time and Group × Time interaction
if ("Error: Subject:Time" %in% names(aov_summary)) {
  time_effects <- aov_summary[["Error: Subject:Time"]][[1]]
  
  if ("Time" %in% rownames(time_effects)) {
    p_time_val <- time_effects["Time", "Pr(>F)"]
    if (length(p_time_val) > 0 && !is.na(p_time_val) && is.numeric(p_time_val)) {
      cat("\n  Main Effect of Time:\n")
      cat(sprintf("    F(%d, %d) = %.4f, p = %.6f\n",
                  time_effects["Time", "Df"],
                  time_effects["Residuals", "Df"],
                  time_effects["Time", "F value"],
                  p_time_val))
      if (p_time_val < 0.05) {
        cat("    -> SIGNIFICANT: Significant change from pre to post\n")
      } else {
        cat("    -> NOT SIGNIFICANT: No significant change from pre to post\n")
      }
    }
  }
  
  if ("Group:Time" %in% rownames(time_effects)) {
    p_interaction_val <- time_effects["Group:Time", "Pr(>F)"]
    if (length(p_interaction_val) > 0 && !is.na(p_interaction_val) && is.numeric(p_interaction_val)) {
      cat("\n  Group × Time Interaction:\n")
      cat(sprintf("    F(%d, %d) = %.4f, p = %.6f\n",
                  time_effects["Group:Time", "Df"],
                  time_effects["Residuals", "Df"],
                  time_effects["Group:Time", "F value"],
                  p_interaction_val))
      
      if (p_interaction_val < 0.05) {
        cat("    -> SIGNIFICANT INTERACTION: The effect of time differs between groups\n")
      } else {
        cat("    -> No significant interaction: Time effect is similar across groups\n")
      }
    }
  }
} else {
  cat("\n  Note: Mixed-design ANOVA structure may differ. Using simpler one-way ANOVA instead.\n")
}

# One-way ANOVA on improvement scores (simpler alternative)
cat("\n\nONE-WAY ANOVA (on Improvement scores):\n")
cat("  Comparing improvement between Control and Treatment groups\n\n")

anova_improvement <- aov(difference ~ group, data = combined_df)
anova_improvement_summary <- summary(anova_improvement)

cat("ANOVA Results:\n")
cat(sprintf("  F(%d, %d) = %.4f, p = %.6f\n",
            anova_improvement_summary[[1]][["group", "Df"]],
            anova_improvement_summary[[1]][["Residuals", "Df"]],
            anova_improvement_summary[[1]][["group", "F value"]],
            anova_improvement_summary[[1]][["group", "Pr(>F)"]]))

p_anova <- anova_improvement_summary[[1]][["group", "Pr(>F)"]]
if (p_anova < 0.001) {
  cat("  -> HIGHLY SIGNIFICANT (p < 0.001) ***\n")
} else if (p_anova < 0.01) {
  cat("  -> VERY SIGNIFICANT (p < 0.01) **\n")
} else if (p_anova < 0.05) {
  cat("  -> SIGNIFICANT (p < 0.05) *\n")
} else {
  cat("  -> NOT SIGNIFICANT (p >= 0.05)\n")
}

# Calculate eta-squared (effect size for ANOVA)
ss_group <- anova_improvement_summary[[1]][["group", "Sum Sq"]]
ss_total <- sum(anova_improvement_summary[[1]][["Sum Sq"]])
eta_squared <- ss_group / ss_total

cat("\n  Effect Size (Eta-squared):\n")
cat(sprintf("    η² = %.4f\n", eta_squared))
if (eta_squared < 0.01) {
  cat("    -> Negligible effect\n")
} else if (eta_squared < 0.06) {
  cat("    -> Small effect\n")
} else if (eta_squared < 0.14) {
  cat("    -> Medium effect\n")
} else {
  cat("    -> Large effect\n")
}

# ============================================
# SUMMARY AND INTERPRETATION
# ============================================
cat("\n=== SUMMARY ===\n\n")
cat(sprintf("Mean difference in improvement:\n"))
cat(sprintf("  Control: %.2f%%\n", mean(control_diff)))
cat(sprintf("  Treatment: %.2f%%\n", mean(treatment_diff)))
cat(sprintf("  Difference: %.2f%%\n", mean(treatment_diff) - mean(control_diff)))

cat("\nSTATISTICAL SIGNIFICANCE:\n\n")
cat("Within-group comparisons (Paired t-tests):\n")
cat(sprintf("  Control group (Pre vs Post, two-tailed): p = %.6f\n", paired_control$p.value))
cat(sprintf("  Control group (Pre vs Post, one-tailed): p = %.6f\n", paired_control_1t$p.value))
cat(sprintf("  Treatment group (Pre vs Post, two-tailed): p = %.6f\n", paired_treatment$p.value))
cat(sprintf("  Treatment group (Pre vs Post, one-tailed): p = %.6f\n", paired_treatment_1t$p.value))

cat("\nBetween-group comparisons:\n")
# Collect all p-values
p_value_student_2t <- t_test_student_2t$p.value
p_value_student_1t <- t_test_student_1t$p.value
p_value_t <- t_test_welch$p.value
p_value_w <- mw_test$p.value
p_value_w_onetail <- mw_test_onetail$p.value
cat(sprintf("    p-value (Student's t-test, two-tailed): %.6f\n", p_value_student_2t))
cat(sprintf("    p-value (Student's t-test, one-tailed): %.6f\n", p_value_student_1t))
cat(sprintf("    p-value (Welch's t-test, two-tailed): %.6f\n", p_value_t))
cat(sprintf("    p-value (Wilcoxon rank-sum test, two-tailed): %.6f\n", p_value_w))
cat(sprintf("    p-value (Wilcoxon rank-sum test, one-tailed): %.6f\n", p_value_w_onetail))
cat(sprintf("    p-value (One-way ANOVA): %.6f\n", p_anova))

cat("\n  Paired t-test interpretation (within-group):\n")
cat("    Control group (Pre vs Post):\n")
if (paired_control$p.value < 0.001) {
  cat("      -> HIGHLY SIGNIFICANT (p < 0.001) ***\n")
} else if (paired_control$p.value < 0.01) {
  cat("      -> VERY SIGNIFICANT (p < 0.01) **\n")
} else if (paired_control$p.value < 0.05) {
  cat("      -> SIGNIFICANT (p < 0.05) *\n")
} else {
  cat("      -> NOT SIGNIFICANT (p >= 0.05)\n")
}

cat("    Treatment group (Pre vs Post):\n")
if (paired_treatment$p.value < 0.001) {
  cat("      -> HIGHLY SIGNIFICANT (p < 0.001) ***\n")
} else if (paired_treatment$p.value < 0.01) {
  cat("      -> VERY SIGNIFICANT (p < 0.01) **\n")
} else if (paired_treatment$p.value < 0.05) {
  cat("      -> SIGNIFICANT (p < 0.05) *\n")
} else {
  cat("      -> NOT SIGNIFICANT (p >= 0.05)\n")
}

cat("\n  Student's t-test (two-tailed) interpretation:\n")
if (p_value_student_2t < 0.001) {
  cat("    -> HIGHLY SIGNIFICANT (p < 0.001) ***\n")
} else if (p_value_student_2t < 0.01) {
  cat("    -> VERY SIGNIFICANT (p < 0.01) **\n")
} else if (p_value_student_2t < 0.05) {
  cat("    -> SIGNIFICANT (p < 0.05) *\n")
} else {
  cat("    -> NOT SIGNIFICANT (p >= 0.05)\n")
}

cat("\n  Student's t-test (one-tailed, Treatment > Control) interpretation:\n")
if (p_value_student_1t < 0.001) {
  cat("    -> HIGHLY SIGNIFICANT (p < 0.001) ***\n")
} else if (p_value_student_1t < 0.01) {
  cat("    -> VERY SIGNIFICANT (p < 0.01) **\n")
} else if (p_value_student_1t < 0.05) {
  cat("    -> SIGNIFICANT (p < 0.05) *\n")
} else {
  cat("    -> NOT SIGNIFICANT (p >= 0.05)\n")
}

cat("\n  Welch's t-test interpretation:\n")
if (p_value_t < 0.001) {
  cat("    -> HIGHLY SIGNIFICANT (p < 0.001) ***\n")
} else if (p_value_t < 0.01) {
  cat("    -> VERY SIGNIFICANT (p < 0.01) **\n")
} else if (p_value_t < 0.05) {
  cat("    -> SIGNIFICANT (p < 0.05) *\n")
} else {
  cat("    -> NOT SIGNIFICANT (p >= 0.05)\n")
}

cat("\n  Wilcoxon test (two-tailed) interpretation:\n")
if (p_value_w < 0.001) {
  cat("    -> HIGHLY SIGNIFICANT (p < 0.001) ***\n")
} else if (p_value_w < 0.01) {
  cat("    -> VERY SIGNIFICANT (p < 0.01) **\n")
} else if (p_value_w < 0.05) {
  cat("    -> SIGNIFICANT (p < 0.05) *\n")
} else {
  cat("    -> NOT SIGNIFICANT (p >= 0.05)\n")
}

cat("\n  Wilcoxon test (one-tailed, Treatment > Control) interpretation:\n")
if (p_value_w_onetail < 0.001) {
  cat("    -> HIGHLY SIGNIFICANT (p < 0.001) ***\n")
} else if (p_value_w_onetail < 0.01) {
  cat("    -> VERY SIGNIFICANT (p < 0.01) **\n")
} else if (p_value_w_onetail < 0.05) {
  cat("    -> SIGNIFICANT (p < 0.05) *\n")
} else {
  cat("    -> NOT SIGNIFICANT (p >= 0.05)\n")
}

cat("\n  ANOVA interpretation:\n")
if (p_anova < 0.001) {
  cat("    -> HIGHLY SIGNIFICANT (p < 0.001) ***\n")
} else if (p_anova < 0.01) {
  cat("    -> VERY SIGNIFICANT (p < 0.01) **\n")
} else if (p_anova < 0.05) {
  cat("    -> SIGNIFICANT (p < 0.05) *\n")
} else {
  cat("    -> NOT SIGNIFICANT (p >= 0.05)\n")
}

# Use the more conservative p-value for conclusion (two-tailed tests)
p_value <- min(p_value_student_2t, p_value_t, p_value_w, p_anova)

cat("\nCONCLUSION:\n")
cat("  Two-tailed tests:\n")
if (mean(treatment_diff) > mean(control_diff)) {
  if (p_value < 0.05) {
    cat("    The treatment group showed significantly greater improvement\n")
    cat("    compared to the control group.\n")
  } else {
    cat("    The treatment group showed greater improvement than the control group,\n")
    cat("    but the difference is not statistically significant.\n")
  }
} else {
  if (p_value < 0.05) {
    cat("    The control group showed significantly greater improvement\n")
    cat("    compared to the treatment group.\n")
  } else {
    cat("    There is no statistically significant difference between groups.\n")
  }
}

cat("\n  One-tailed tests:\n")
cat("  Student's t-test (testing Treatment > Control):\n")
if (mean(treatment_diff) > mean(control_diff)) {
  if (p_value_student_1t < 0.05) {
    cat(sprintf("    SIGNIFICANT: Treatment group shows significantly greater improvement\n"))
    cat(sprintf("    than control group (one-tailed test, p = %.6f).\n", p_value_student_1t))
  } else {
    cat(sprintf("    NOT SIGNIFICANT: No significant evidence that treatment > control\n"))
    cat(sprintf("    (one-tailed test, p = %.6f).\n", p_value_student_1t))
  }
} else {
  cat("    Note: One-tailed test not applicable (treatment not greater than control)\n")
}

cat("\n  One-tailed Wilcoxon test (testing Treatment > Control):\n")
if (mean(treatment_diff) > mean(control_diff)) {
  if (p_value_w_onetail < 0.05) {
    cat(sprintf("    SIGNIFICANT: Treatment group shows significantly greater improvement\n"))
    cat(sprintf("    than control group (one-tailed test, p = %.6f).\n", p_value_w_onetail))
  } else {
    cat(sprintf("    NOT SIGNIFICANT: No significant evidence that treatment > control\n"))
    cat(sprintf("    (one-tailed test, p = %.6f).\n", p_value_w_onetail))
  }
} else {
  cat("    Note: One-tailed test not applicable (treatment not greater than control)\n")
}

# ============================================
# VISUALIZATION
# ============================================
# Create boxplot
png("difference_comparison.png", width = 800, height = 600)
boxplot(control_diff, treatment_diff,
        names = c("Control", "Treatment"),
        ylab = "Improvement (%)",
        main = "Comparison of Pre-Post Improvement: Control vs Treatment",
        col = c("lightblue", "lightgreen"))
points(1, mean(control_diff), col = "red", pch = 19, cex = 1.5)
points(2, mean(treatment_diff), col = "red", pch = 19, cex = 1.5)
legend("topright", legend = c("Mean"), col = "red", pch = 19)
dev.off()

# Create histogram comparison
png("difference_histogram.png", width = 1000, height = 600)
par(mfrow = c(1, 2))
hist(control_diff, breaks = 10, main = "Control Group", 
     xlab = "Improvement (%)", col = "lightblue", xlim = c(-30, 110))
abline(v = mean(control_diff), col = "red", lwd = 2)
hist(treatment_diff, breaks = 10, main = "Treatment Group", 
     xlab = "Improvement (%)", col = "lightgreen", xlim = c(-30, 110))
abline(v = mean(treatment_diff), col = "red", lwd = 2)
dev.off()

cat("\nVisualizations saved:\n")
cat("  - difference_comparison.png (boxplot)\n")
cat("  - difference_histogram.png (histograms)\n")
