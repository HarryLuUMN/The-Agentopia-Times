# Create comparison plot similar to the reference image
# Horizontal bar charts showing Pre-study, Post-study, and Improvement

library(ggplot2)
library(dplyr)

# Read the data
control <- read.csv("control.csv", stringsAsFactors = FALSE)
treatment <- read.csv("treatment.csv", stringsAsFactors = FALSE)

# Clean the data - remove percentage signs and convert to numeric
clean_percentage <- function(x) {
  as.numeric(gsub("%", "", x))
}

# Extract data (remove last row if it's a summary)
control_pre <- clean_percentage(control$Correct.pre[1:(nrow(control)-1)])
control_post <- clean_percentage(control$Correct.post[1:(nrow(control)-1)])
control_diff <- clean_percentage(control$Differences[1:(nrow(control)-1)])

treatment_pre <- clean_percentage(treatment$Correct.pre[1:nrow(treatment)])
treatment_post <- clean_percentage(treatment$Correct.post[1:nrow(treatment)])
treatment_diff <- clean_percentage(treatment$Differences[1:nrow(treatment)])

# Function to calculate mean and 95% CI
calc_stats <- function(data) {
  n <- length(data)
  mean_val <- mean(data)
  se <- sd(data) / sqrt(n)
  ci_lower <- mean_val - 1.96 * se
  ci_upper <- mean_val + 1.96 * se
  return(list(mean = mean_val, ci_lower = ci_lower, ci_upper = ci_upper))
}

# Calculate statistics for each group
control_pre_stats <- calc_stats(control_pre)
control_post_stats <- calc_stats(control_post)
control_diff_stats <- calc_stats(control_diff)

treatment_pre_stats <- calc_stats(treatment_pre)
treatment_post_stats <- calc_stats(treatment_post)
treatment_diff_stats <- calc_stats(treatment_diff)

# Paired t-test for pre-post comparison within each group
control_prepost_test <- t.test(control_post, control_pre, paired = TRUE)
treatment_prepost_test <- t.test(treatment_post, treatment_pre, paired = TRUE)

# Independent t-test for improvement comparison between groups
improvement_test <- t.test(treatment_diff, control_diff, var.equal = FALSE)

# Create data frame for plotting
plot_data <- data.frame(
  Group = rep(c("Treatment", "Control"), each = 3),
  Metric = rep(c("Pre-study", "Post-study", "Improvement"), 2),
  Mean = c(
    treatment_pre_stats$mean,
    treatment_post_stats$mean,
    treatment_diff_stats$mean,
    control_pre_stats$mean,
    control_post_stats$mean,
    control_diff_stats$mean
  ),
  CI_Lower = c(
    treatment_pre_stats$ci_lower,
    treatment_post_stats$ci_lower,
    treatment_diff_stats$ci_lower,
    control_pre_stats$ci_lower,
    control_post_stats$ci_lower,
    control_diff_stats$ci_lower
  ),
  CI_Upper = c(
    treatment_pre_stats$ci_upper,
    treatment_post_stats$ci_upper,
    treatment_diff_stats$ci_upper,
    control_pre_stats$ci_upper,
    control_post_stats$ci_upper,
    control_diff_stats$ci_upper
  )
)

# Set factor levels for proper ordering
plot_data$Metric <- factor(plot_data$Metric, 
                           levels = c("Pre-study", "Post-study", "Improvement"))
plot_data$Group <- factor(plot_data$Group, levels = c("Treatment", "Control"))

# Create p-value annotations
p_control_prepost <- control_prepost_test$p.value
p_treatment_prepost <- treatment_prepost_test$p.value
p_improvement_diff <- improvement_test$p.value

# Format p-values
format_pvalue <- function(p) {
  if (p < 0.001) {
    return(sprintf("p = %.3e", p))
  } else if (p < 0.01) {
    return(sprintf("p = %.4f", p))
  } else {
    return(sprintf("p = %.4f", p))
  }
}

# Create annotation data
annotations <- data.frame(
  Group = c("Treatment", "Control", "Treatment"),
  Metric = c("Post-study", "Post-study", "Improvement"),
  x = c(
    treatment_post_stats$ci_upper + 5,
    control_post_stats$ci_upper + 5,
    max(plot_data$CI_Upper) + 10
  ),
  y = c(2, 5, 1.5),
  label = c(
    format_pvalue(p_treatment_prepost),
    format_pvalue(p_control_prepost),
    format_pvalue(p_improvement_diff)
  )
)

# Calculate max x limit for consistent scaling
max_x <- max(plot_data$CI_Upper) + 25

# Create the plot
p <- ggplot(plot_data, aes(x = Mean, y = Metric, fill = Group)) +
  geom_bar(stat = "identity", width = 0.6, alpha = 0.85) +
  geom_errorbar(aes(xmin = CI_Lower, xmax = CI_Upper), 
                width = 0.2, orientation = "y") +
  facet_wrap(~Group, ncol = 1, scales = "free_y") +
  scale_fill_manual(values = c("Treatment" = "#2E86AB", "Control" = "#A23B72")) +
  scale_x_continuous(limits = c(0, max_x), 
                     breaks = seq(0, 100, 20),
                     labels = paste0(seq(0, 100, 20), "%"),
                     expand = expansion(mult = c(0, 0.1)),
                     name = "Mean ± 95% CI (measure in accuracy rate)") +
  scale_y_discrete(limits = rev(levels(plot_data$Metric))) +
  labs(title = "",
       y = "") +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
    axis.text.y = element_text(size = 11, color = "black"),
    axis.text.x = element_text(size = 10),
    axis.title.x = element_text(size = 11, margin = margin(t = 10)),
    strip.text = element_text(size = 12, face = "bold", margin = margin(b = 10)),
    legend.position = "none",
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_line(color = "gray90", linetype = "dashed"),
    panel.background = element_rect(fill = "white", color = NA),
    strip.background = element_rect(fill = "white", color = NA),
    plot.margin = margin(20, 40, 20, 20)
  )

# Create annotation data frame for p-values
pvalue_annotations <- data.frame(
  Group = c("Treatment", "Control"),
  Metric = c("Post-study", "Post-study"),
  x = c(treatment_post_stats$ci_upper + 3, control_post_stats$ci_upper + 3),
  label = c(format_pvalue(p_treatment_prepost), format_pvalue(p_control_prepost))
)

# Add p-value annotations for pre-post comparison (next to Post-study bars)
p <- p + geom_text(data = pvalue_annotations,
                   aes(x = x, y = Metric, label = label),
                   inherit.aes = FALSE, size = 3.5, hjust = 0, color = "black")

# Add p-value for improvement difference (on the right, spanning both groups)
# We'll add it to both facets
improvement_annotation <- data.frame(
  Group = c("Treatment", "Control"),
  Metric = c("Improvement", "Improvement"),
  x = max_x - 2,
  label = format_pvalue(p_improvement_diff)
)

p <- p + geom_text(data = improvement_annotation,
                   aes(x = x, y = Metric, label = label),
                   inherit.aes = FALSE, size = 3.5, hjust = 1, color = "black")

# Save the plot
ggsave("comparison_plot.png", plot = p, width = 10, height = 6, dpi = 300)

cat("\nPlot saved as 'comparison_plot.png'\n")
cat("\nP-values:\n")
cat(sprintf("  Treatment pre-post: %s\n", format_pvalue(p_treatment_prepost)))
cat(sprintf("  Control pre-post: %s\n", format_pvalue(p_control_prepost)))
cat(sprintf("  Improvement difference: %s\n", format_pvalue(p_improvement_diff)))
