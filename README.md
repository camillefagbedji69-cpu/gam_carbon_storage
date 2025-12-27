# Eco-GAM: Non-Linear Modeling of Carbon Storage Gradients

## 📌 Context & Overview
Ecological relationships are rarely linear. Threshold effects, saturation points, and complex feedback loops govern how environmental variables influence carbon sequestration. Following the spatial estimation (InVEST) and dimensionality reduction (PCA), this project employs **Generalized Additive Models (GAMs)** to characterize the non-linear response of carbon stocks to multi-dimensional environmental gradients.

## 🎯 Objectives
* **Non-Linear Modeling:** Capturing complex relationships between PCA-derived environmental dimensions and carbon stocks.
* **Variance Quantification:** Measuring the explanatory power of climatic, edaphic, and vegetative gradients.
* **Partial Effect Visualization:** Interpreting how individual ecological dimensions drive carbon gains or losses.

## 🛠️ Methodology & Tech Stack
* **Language:** R 📊
* **Key Library:** `mgcv` (the gold standard for GAMs in R).
* **Statistical Framework:** Gaussian GAM with identity link function, utilizing **Thin Plate Regression Splines**.
* **Formula:** $\log(\text{Carbon}) = \alpha + s(\text{Dim.1}) + s(\text{Dim.2}) + s(\text{Dim.3}) + s(\text{Dim.4}) + s(\text{Dim.5}) + \epsilon$



## 🚀 Key Results
* **Exceptional Fit:** The model achieved an **Adjusted $R^2$ of 0.817**, explaining over 81% of carbon variability.
* **Non-Linear Complexity:**
    * **Dim.1 to Dim.3:** Showed high **EDF (Effective Degrees of Freedom)** values (3.2 to 6.0), confirming significant non-linear interactions within the soil-water-vegetation nexus.
    * **Dim.4:** Displayed a near-linear relationship (EDF ≈ 1).
* **Ecological Insight:** Carbon storage is governed by threshold-based responses to environmental stress. The model successfully isolated these "tipping points" where ecological conditions shift from favoring sequestration to causing carbon loss.

## 🔮 Perspectives for Improvement
* **Spatial Autocorrelation:** Integrating a Gaussian Process (GP) or Markov Random Field (MRF) smooth term to account for spatial dependencies.
* **Interaction Surfaces:** Testing tensor product smooths (e.g., `te(Dim.1, Dim.2)`) to explore joint climate-vegetation effects.
* **Predictive Mapping:** Generating high-resolution probability maps of carbon storage potential to complement deterministic InVEST outputs.
