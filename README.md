# Salary/Compensation Analysis: Does Experience Predict Salary More Than Skillset?

**Source:** Stack Overflow Developer Survey 2025 (US respondents only, n=4,652 after cleaning)
**Tools:** MySQL (SQL layer), Python (pandas, scipy, statsmodels)

## The Question

The common assumption in tech hiring and career advice is that years of experience is the dominant driver of compensation. This project tests that assumption directly against an alternative: that specific skillset (programming languages), role, organization size, and remote-work arrangement may matter as much or more.

## Pipeline

1. **Data cleaning** (Python/pandas) — column selection, outlier detection, missing-data handling
2. **SQL layer** (MySQL) — normalized schema, aggregate queries, window functions
3. **Statistical testing** (scipy) — t-tests, one-way ANOVA, Tukey HSD post-hoc
4. **Regression** (statsmodels) — multiple linear regression on log-transformed salary, with VIF and residual diagnostics
5. **Conclusion** — synthesis of findings against the original question

## Data Preparation

**Columns used:** `ConvertedCompYearly` (target — SO's own USD-normalized salary, used instead of `CompTotal` to avoid cross-currency comparison issues), `WorkExp` (professional experience, chosen over `YearsCode` to exclude hobby/personal-project time), `Country` (filtered to United States only, to avoid cross-country salary confounding), `RemoteWork`, `DevType`, `EdLevel`, `OrgSize`, `LanguageHaveWorkedWith`.

**Scope decision:** Database, Platform, Webframe, and DevEnvs skill categories were excluded from this iteration in favor of programming language alone, to keep the model interpretable and avoid excessive multicollinearity from one-hot-encoding dozens of near-collinear tech categories. A natural extension would test whether adding these improves predictive power.

**Outlier handling (salary):** Used a percentile-jump method — comparing the ratio between adjacent percentiles to distinguish genuine variation from data entry errors. The 1st-to-5th percentile jump ($236 → $35,000, ~148x) and the 99th-to-max jump ($650,000 → $50M, ~77x) were both disproportionate relative to neighboring gaps, indicating likely bad data. Final range: **$35,000–$650,000**. This reduced the standard deviation from $712,318 to $89,331 with minimal change to the median ($150,000 → $150,000), confirming the filter removed extreme noise rather than genuine signal.

**Missing data:**
- `WorkExp` nulls (0.9%) and `EdLevel` nulls (0.06%): dropped after confirming salary distributions for null rows showed no distinct pattern (i.e., not a systematic "freshers only" subgroup).
- `LanguageHaveWorkedWith` nulls (4.8%): dropped as likely non-response rather than "zero skills."
- `OrgSize` nulls (7.3%): tested via t-test against the existing "I don't know" response category (t=1.983, p=0.049, ~12.6% mean salary gap) — evidence the two groups differ, so nulls were kept as a separate `'Unknown'` category rather than merged.
- `RemoteWork` nulls (7.5%): assigned `'Unknown'` category.

**Language encoding:** Top 21 of 42 languages (≥5% respondent threshold) converted to binary flags; all languages below threshold captured in a `lang_Other` flag so respondents with only niche skills remain distinguishable from those with no reported languages.

**DevType grouping:** A strict frequency threshold would have excluded `Data scientist`, `AI/ML engineer`, and `Data or business analyst` — roles central to this analysis's intended audience. Final rule: keep categories with ≥100 respondents **or** explicitly named roles of interest; all others (including the survey's own "Other, please specify" response) merged into `Other`. This is a deliberate trade of statistical cleanliness for relevance — results for smaller included groups (e.g., Data or business analyst, n=42) should be read with wider uncertainty than the larger groups.

## SQL Layer

Normalized schema: `respondents` (one row per person) and `respondent_language` (one row per person per language), joined on `respondent_id`.

**Salary by experience band** (window/aggregate query):

| Band | n | Avg Salary | Std Dev |
|---|---|---|---|
| 0-2 | 237 | $91,510 | $49,168 |
| 2-5 | 483 | $114,963 | $63,185 |
| 5-10 | 1,004 | $159,616 | $77,787 |
| 10-20 | 1,468 | $187,041 | $93,860 |
| 20+ | 1,460 | $184,599 | $85,757 |

Salary climbs sharply through the first 10-15 years, then flattens and *slightly reverses* past 20 years — an early signal that experience's relationship with salary is not simply linear, and that raw, uncontrolled averages may overstate its effect once other factors change alongside it (more senior people also tend to shift roles, company sizes, etc.).

**Top-paying languages by role** (window function, ranked within `DevType`, minimum 20 respondents per group): produced role-specific top-3 language rankings. This table is descriptive/directional only — it does not control for confounds like experience, and should not be read as a causal ranking of "valuable" languages per role.

## Statistical Testing

**T-tests** (used to validate merge/grouping decisions during cleaning):
- Remote vs. In-person salary: t=7.477, p≈1.86×10⁻¹³ — strong, highly significant difference.
- Two hybrid RemoteWork variants against each other: t=0.770, p=0.442 — not significantly different (informed the grouping decision, though ultimately not merged in the final categorical variable to preserve granularity for ANOVA).

**One-way ANOVA** (salary across categorical groups):

| Variable | F-statistic | p-value |
|---|---|---|
| OrgSize | 30.394 | <0.001 |
| DevType | 28.251 | <0.001 |
| RemoteWork | 15.393 | <0.001 |
| EdLevel | 12.654 | <0.001 |

All four categorical variables show a statistically significant relationship with salary. Notably, organization size showed the strongest raw (univariate) relationship — stronger than role — pushing back on the common assumption that "what you do" matters more than "who you work for." Formal education showed the weakest relationship of the four, though still significant.

*Caveat: these are independent, univariate tests. Apparent strength differences between variables may partly reflect confounding between them (e.g., larger orgs may also employ more senior staff) — see the regression section for controlled estimates.*

**Tukey HSD post-hoc** (DevType pairwise comparisons): the ANOVA's significant result is driven primarily by a few standout groups — **Engineering managers and Architects earn significantly more** than most individual-contributor roles, and **Data or business analysts earn significantly less** than nearly every other role tested. Most remaining roles are not statistically distinguishable from one another; the significant overall ANOVA result reflects these extremes rather than broad differentiation across all roles.

## Regression

Multiple linear regression, log-transformed salary (to correct right-skew: mean $167,929 vs. median $150,000 pre-transform), predictors: `WorkExp`, `DevType_grouped`, `RemoteWork`, `OrgSize`, `EdLevel`, and six representative language flags.

**Model fit:** Adjusted R² = 0.266 (the model explains ~27% of salary variation — a realistic figure for noisy, self-reported survey data, not a shortcoming to be smoothed over). Overall model significance: p≈1.82×10⁻²⁸² (F=42.14).

**Key findings, holding all other variables constant:**

- **Experience:** `WorkExp` coefficient = 0.0118 (p<0.001) → approximately **1.2% salary increase per year of experience**, controlling for role, org size, education, and skillset. This is meaningfully smaller than the raw SQL band table suggested, confirming that experience's apparent dominance in simple aggregation was partly inflated by confounding with role and company size.
- **Role:** `Data or business analyst` shows the single largest negative effect (coef=-0.446, p<0.001, ≈36% lower salary than baseline) even after controlling for experience — the Tukey finding holds up under a controlled model.
- **Organization size:** Largely monotonic — `10,000+ employees` shows the strongest positive effect (coef=+0.135, p<0.001); very small orgs and freelance/sole-proprietor status show the strongest negative effects.
- **Remote work:** `Remote` positive (coef=+0.103, p<0001), `In-person` negative (coef=-0.109, p<0.001) — a real, controlled ~19-21 percentage-point gap that survives controlling for experience and role.
- **Skillset:** `lang_Go` (+0.158, p<0.001) and `lang_TypeScript` (+0.135, p<0.001) show effects comparable to or larger than a full year of additional experience — genuinely valuable, differentiated skills, not just seniority proxies. `lang_JavaScript` (-0.057) and `lang_SQL` (-0.048) show small but significant *negative* coefficients, plausibly because these are common, widely-held skills that don't differentiate high earners once role and experience are accounted for — not evidence that knowing them reduces pay.

**Diagnostics:**
- VIF analysis showed no meaningful multicollinearity concern among language variables (all VIF < 1.5) — the correlated-looking cluster in the raw correlation heatmap (JavaScript/SQL/TypeScript/HTML-CSS) did not translate into coefficient instability. Elevated VIF (~17-18) appeared for the `RemoteWork`/`OrgSize` "Unknown" categories, consistent with missingness co-occurring across those two survey fields, and for the largest `DevType` category (full-stack, VIF≈16) due to its disproportionate sample size — a structural artifact of one-hot encoding an unevenly distributed variable, not a data error. Coefficients for both remained highly significant despite this, suggesting the core findings are robust to the concern.
- Residual diagnostics showed roughly symmetric errors (skew=0.152) but heavier-than-normal tails (kurtosis=3.809, confirmed via Q-Q plot), indicating some extreme salary outliers remain even after cleaning. Borderline-significant coefficients should be read with extra caution; strongly significant findings (WorkExp, language effects, role effects) are robust given the sample size.

## Conclusion

Based on this analysis, **experience matters, but its effect is smaller and more conditional than commonly assumed once other factors are properly controlled for.** A single year of experience is worth roughly 1.2% in salary — real, but modest, and easily matched or exceeded by having a high-value skill (Go, TypeScript) or working at a large organization. Meanwhile, **role and organization size rival or exceed experience's influence** — the strongest single categorical predictor in this dataset was organization size, not years worked or job title. If this were a real hiring or compensation decision, the business should weigh scarce, differentiated technical skills and organizational context at least as heavily as tenure when setting pay bands, rather than treating years of experience as the primary lever.

## Limitations

- Self-selected survey sample; Stack Overflow respondents likely skew toward more engaged, senior developers and are not representative of the full developer population.
- Self-reported salary and experience, with no independent verification.
- Scoped to US respondents only; findings do not generalize to other countries or currencies.
- Regression coefficients describe statistical association, not causation — particularly for language effects, which may partly reflect unobserved factors (e.g., industry, specific employer) not captured in this dataset.
- Skillset analysis limited to programming languages; database, platform, and framework skills were excluded from this iteration and are a natural extension.
- Some multicollinearity present among missing-data "Unknown" categories and the largest DevType category; interpreted and disclosed above rather than corrected for, since correcting would have required discarding real information (see VIF discussion).

## Repository Structure

```
README.md
/sql/            -- schema.sql, queries.sql
/notebooks/       -- 01_cleaning.ipynb, 02_stats_and_regression.ipynb
/images/           -- correlation_heatmap.png, residual_diagnostics.png
requirements.txt
```
