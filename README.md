# Adaptive Testing Strategies via Variant-Specific Viral-Kinetics-Informed Learning

This repository contains the analysis code and simulation-output data used to reproduce the main and supplementary results for the manuscript:

> **Adaptive Testing Strategies via Variant-Specific Viral-Kinetics-Informed Learning**  
> Hyosun Lee, Arsen Abdulali, and Sunmi Lee

The study integrates variant-informed within-host viral kinetics, a stochastic contact-network individual-based epidemic model, and reinforcement learning under partial observability to investigate adaptive allocation of polymerase chain reaction (PCR) and rapid antigen (AG) testing.

The repository is organized so that the manuscript figures and numerical summaries can be regenerated from precomputed stochastic rollout outputs.

---

## Overview

The analysis evaluates three SARS-CoV-2 variant-informed scenarios:

- Alpha
- Delta
- Omicron

under three target transmission-intensity settings:

- `R0* = 2.5`
- `R0* = 3.5`
- `R0* = 4.5`

The main testing-policy comparisons include:

- learned adaptive testing policy (`RL mixed` in the analysis code)
- PCR-only testing
- AG-only testing
- fixed mixed PCR--AG testing
- no testing

The main reward setting uses:

```text
theta_cost = 0.25
```

and the supplementary sensitivity analysis additionally evaluates:

```text
theta_cost = 0.50, 0.75, 1.00
```

Each reported evaluation condition is summarized across 100 independent stochastic simulations.

---

## Repository structure

The recommended repository layout is:

```text
TwoScaleABM-RL/
│
├── README.md
│
├── code/
│   ├── Result_plot_final_figures.m
│   └── Supplementary_plot_all_figures_all_variants.m
│
├── results/
│   ├── saved_rollout_<variant>_R0_<R0tag>_<policytag>_100runs/
│   └── saved_rollout_<variant>_R0_<R0tag>_dualpool_costonly_theta_<thetaTag>_100runs/
│
└── source_data/
    ├── main_figures/
    └── supplementary_figures/
```

### Directory roles

- `code/` contains the MATLAB analysis and figure-reproduction scripts.
- `results/` contains rollout-level stochastic simulation outputs used as inputs by the MATLAB scripts.
- `source_data/` contains processed numerical data underlying the manuscript figures and tables.
- `figures/` contains generated figure files and is created automatically when the MATLAB scripts are run.

The `figures/` directory does not need to be included in a fresh clone if the goal is to reproduce the results from the supplied data.

---

# Code

## Main-text analysis

```text
code/Result_plot_final_figures.m
```

This script generates the result summaries and visualizations used for the main-text Figures 3--6.

The script reads rollout-level data from:

```text
results/
```

and writes generated figures and processed CSV files to:

```text
figures/final_results_restructured/
figures/final_results_restructured/csv/
```

The main figures summarize:

- learned testing actions
- realized PCR and AG testing
- hidden-infection detection
- testing-modality ratios
- epidemic trajectories
- cumulative-infection outcomes
- peak hidden infectious burden
- testing-resource use
- control--resource trade-offs
- sensitivity across target transmission intensities

---

## Supplementary analysis

```text
code/Supplementary_plot_all_figures_all_variants.m
```

This script generates:

- Supplementary Figures S1--S14
- Supplementary Tables S1--S4
- processed source-data CSV files for the supplementary analyses

Outputs are written to:

```text
figures/supplementary/
figures/supplementary/csv/
figures/supplementary/tables/
```

Supplementary Figure S1 is generated directly from the within-host viral-kinetic and diagnostic-detectability parameters defined in the MATLAB script.

Supplementary Figures S2--S14 and the supplementary scalar/action tables use rollout-level files stored under `results/`.

---

# Input data

Both MATLAB scripts use:

```matlab
RESULT_ROOT = "results";
```

The scripts should therefore be run from the repository root unless `RESULT_ROOT` is changed manually.

---

## Main-analysis directory naming

For the main policy comparisons, each scenario directory follows:

```text
results/saved_rollout_<variant>_R0_<R0tag>_<policytag>_100runs/
```

where:

### Variant tags

```text
alpha
delta
omicron
```

### Target-R0 tags

```text
2p5
3p5
4p5
```

### Policy tags

| Manuscript description | Directory tag |
| --- | --- |
| Learned adaptive testing policy | `dualpool_costonly` |
| PCR-only testing | `PCRonly` |
| AG-only testing | `Agonly` |
| Fixed mixed PCR--AG testing | `HalfPCRAg` |
| No testing | `Notesting` |

For example:

```text
results/saved_rollout_delta_R0_3p5_dualpool_costonly_100runs/
```

The complete main policy comparison consists of:

```text
3 variants × 3 target-R0 settings × 5 policies = 45 scenario directories
```

---

## Testing-cost-weight sensitivity directory naming

Supplementary Figures S10--S14 evaluate the learned adaptive policy under additional testing-cost weights.

These directories follow:

```text
results/saved_rollout_<variant>_R0_<R0tag>_dualpool_costonly_theta_<thetaTag>_100runs/
```

Recommended canonical theta tags are:

| theta_cost | Directory tag |
| ---: | --- |
| 0.50 | `0p5` |
| 0.75 | `0p75` |
| 1.00 | `1` |

For example:

```text
results/saved_rollout_delta_R0_2p5_dualpool_costonly_theta_0p5_100runs/
```

The main setting `theta_cost = 0.25` uses the standard learned-policy directory without a theta suffix:

```text
results/saved_rollout_delta_R0_2p5_dualpool_costonly_100runs/
```

The additional sensitivity dataset therefore contains:

```text
3 variants × 3 target-R0 settings × 3 additional theta values = 27 directories
```

---

# Files required within each scenario directory

A typical learned-policy directory is:

```text
saved_rollout_delta_R0_3p5_dualpool_costonly_100runs/
│
├── state_traj_Delta_final.txt
├── new_Ip_Delta_final.txt
├── n_tests_Delta_final.txt
├── testing_step_summary_Delta_final.txt
├── actions_interpreted_Delta_final.txt
└── testing_effort_summary_Delta_final.txt
```

The analysis scripts search for input files using patterns of the form:

```text
<prefix>_<Variant>_*.txt
```

For example:

```text
state_traj_Delta_*.txt
```

For reproducibility, each public scenario directory should preferably contain only one final file corresponding to each prefix.

The suffix does not need to be `_final`; timestamps or run identifiers are acceptable as long as only one intended file is present for each prefix.

---

## 1. Epidemiological state trajectories

Filename pattern:

```text
state_traj_<Variant>_*.txt
```

Column order:

```text
rollout, time, S, E, Ip, Ia, Is, Dqs, Dq, R
```

State definitions:

- `S`: susceptible
- `E`: infected but not yet infectious
- `Ip`: presymptomatic infectious
- `Ia`: asymptomatic infectious
- `Is`: symptomatic infectious
- `Dqs`: symptom-driven quarantine
- `Dq`: test-detected quarantine
- `R`: recovered

The plotting code derives additional quantities such as:

```text
hidden infectious cases = Ip + Ia
hidden infected burden   = E + Ip + Ia
```

---

## 2. Operational cumulative-infection input

Filename pattern:

```text
new_Ip_<Variant>_*.txt
```

Column order:

```text
rollout, time, new_Ip
```

The analysis scripts cumulatively sum `new_Ip` within each rollout to obtain the operational cumulative-infection outcome used in the manuscript.

This outcome corresponds to cumulative transitions into the presymptomatic infectious state and is distinct from the cumulative number of all `S -> E` infection events.

---

## 3. Realized testing

Filename pattern:

```text
n_tests_<Variant>_*.txt
```

Column order:

```text
rollout, time, n_pcr, n_ag
```

where:

- `n_pcr` is the number of PCR tests actually performed
- `n_ag` is the number of AG tests actually performed

These realized test counts are used to calculate:

- cumulative PCR tests
- cumulative AG tests
- testing-modality ratios
- modeled testing cost

---

## 4. Testing and detection summaries

Filename pattern:

```text
testing_step_summary_<Variant>_*.txt
```

Column order:

```text
rollout,
time,
selected_total,
selected_infected,
detected_positive,
reported_cases,
detected_E,
detected_Ip,
detected_Ia,
detected_E_ag,
detected_Ip_ag,
detected_Ia_ag
```

This file is used to derive:

- detected hidden infections
- PCR-detected hidden infections
- AG-detected hidden infections
- cumulative hidden-infection detections
- detection-efficiency summaries

Detected hidden infections correspond to true-positive detections from samples collected while individuals were in `E`, `Ip`, or `Ia`.

---

## 5. Learned testing actions

The preferred action file is:

```text
actions_interpreted_<Variant>_*.txt
```

Column order in the saved data:

```text
rollout,
time,
high_risk_pool_coverage,
ag_screening_intensity,
retest_interval_days,
pcr_high_risk_intensity
```

The saved-data column order is different from the action numbering used in the manuscript.

The manuscript uses:

```text
Action 1 = high-risk coverage
Action 2 = AG screening
Action 3 = PCR intensity
Action 4 = testing period
```

The supplementary plotting script explicitly separates the saved-data column order from the manuscript display order.

If an interpreted-action file is unavailable, the scripts can instead read:

```text
actions_raw_<Variant>_*.txt
```

The raw normalized action values are then transformed to their interpreted ranges within the MATLAB script.

For public release, providing `actions_interpreted` is recommended because the operational meaning of each action can be inspected directly.

---

## 6. Optional testing-effort summary

Filename pattern:

```text
testing_effort_summary_<Variant>_*.txt
```

Column order:

```text
rollout,
time,
selected_total,
selected_pcr,
selected_ag,
actual_total,
actual_pcr,
actual_ag
```

This file distinguishes policy-selected candidates from tests that were actually performed after daily re-evaluation of testing eligibility.

It is optional for the currently reported figures but can be included for transparency and future analysis.

---

# Example input directories

## Main learned-policy analysis

```text
results/
└── saved_rollout_delta_R0_3p5_dualpool_costonly_100runs/
    ├── state_traj_Delta_final.txt
    ├── new_Ip_Delta_final.txt
    ├── n_tests_Delta_final.txt
    ├── testing_step_summary_Delta_final.txt
    ├── actions_interpreted_Delta_final.txt
    └── testing_effort_summary_Delta_final.txt
```

## Reward-weight sensitivity

```text
results/
└── saved_rollout_delta_R0_2p5_dualpool_costonly_theta_0p5_100runs/
    ├── state_traj_Delta_final.txt
    ├── new_Ip_Delta_final.txt
    ├── n_tests_Delta_final.txt
    ├── testing_step_summary_Delta_final.txt
    └── actions_interpreted_Delta_final.txt
```

---

# Source data

Processed numerical source data underlying the manuscript figures should be stored separately from the rollout-level simulation outputs.

Recommended structure:

```text
source_data/
│
├── main_figures/
│   ├── Figure3_actions_R0_3p5.csv
│   ├── Figure3_realized_testing_R0_3p5.csv
│   ├── Figure3_hidden_detections_R0_3p5.csv
│   ├── Figure3_efficiency_modality_ratio_R0_3p5.csv
│   ├── Figure4_hidden_infectious_composition_R0_3p5.csv
│   ├── Figure4_symptomatic_infectious_R0_3p5.csv
│   ├── Figure4_final_epidemic_summary_R0_3p5.csv
│   ├── Figure5_tradeoff_summary.csv
│   └── Figure6_R0_sensitivity_pathway_summary.csv
│
└── supplementary_figures/
    ├── Supp_Figure_S1_detectability_profiles.csv
    ├── Supp_Figure_S2_policy_performance_R0_2p5_trajectories.csv
    ├── Supp_Figure_S2_policy_performance_R0_2p5_final_cumulative_bar.csv
    ├── Supp_Figure_S3_policy_performance_R0_4p5_trajectories.csv
    ├── Supp_Figure_S3_policy_performance_R0_4p5_final_cumulative_bar.csv
    ├── Supp_Figure_S4_alternative_tradeoff_values.csv
    ├── Supp_Figure_S5_learned_actions_R0_2p5.csv
    ├── Supp_Figure_S6_learned_actions_R0_3p5.csv
    ├── Supp_Figure_S7_learned_actions_R0_4p5.csv
    ├── Supp_Figure_S8_testing_detection_R0_2p5_cumulative_tests.csv
    ├── Supp_Figure_S8_testing_detection_R0_2p5_hidden_detections.csv
    ├── Supp_Figure_S8_testing_detection_R0_2p5_testing_modality_ratio.csv
    ├── Supp_Figure_S8_testing_detection_R0_2p5_detection_efficiency.csv
    ├── Supp_Figure_S9_testing_detection_R0_4p5_cumulative_tests.csv
    ├── Supp_Figure_S9_testing_detection_R0_4p5_hidden_detections.csv
    ├── Supp_Figure_S9_testing_detection_R0_4p5_testing_modality_ratio.csv
    ├── Supp_Figure_S9_testing_detection_R0_4p5_detection_efficiency.csv
    ├── Supp_Figure_S10_theta_policy_all_variants_trajectories.csv
    ├── Supp_Figure_S10_theta_policy_all_variants_final_cumulative.csv
    ├── Supp_Figure_S11_theta_tradeoff_all_variants_values.csv
    ├── Supp_Figure_S12_theta_actions_all_variants.csv
    ├── Supp_Figure_S13_theta_testing_all_variants_tests.csv
    ├── Supp_Figure_S13_theta_testing_all_variants_detections.csv
    ├── Supp_Figure_S13_theta_testing_all_variants_testing_modality_ratio.csv
    ├── Supp_Figure_S13_theta_testing_all_variants_efficiency.csv
    └── Supp_Figure_S14_theta_scalar_all_variants_values.csv
```

The source-data CSV files are processed outputs and are provided to facilitate inspection and verification of the reported figures.

They are distinct from the rollout-level `.txt` files in `results/`, which are the primary inputs required by the MATLAB scripts.

---

# Running the analysis

## Requirements

The code is written in MATLAB.

The scripts use functionality including:

- `table`
- `groupsummary`
- `tiledlayout`
- `readmatrix`
- `outerjoin`
- `exportgraphics`
- `tinv`

Because `tinv` is used to calculate Student-t confidence intervals, the **Statistics and Machine Learning Toolbox** is required.

A recent MATLAB release supporting `tiledlayout` and `exportgraphics` is recommended.

---

## Run from the repository root

Start MATLAB with the current working directory set to the repository root.

### Main-text figures

```matlab
run("code/Result_plot_final_figures_3_6_restructured_v7_figure5_variant_hue_R0_shade.m")
```

Generated files are written to:

```text
figures/final_results_restructured/
figures/final_results_restructured/csv/
```

### Supplementary figures and tables

```matlab
run("code/Supplementary_plot_all_figures_all_variants_final_terms_symptomatic.m")
```

Generated files are written to:

```text
figures/supplementary/
figures/supplementary/csv/
figures/supplementary/tables/
```

The required output directories are created automatically if they do not already exist.

---

# Statistical summaries

Unless otherwise stated, reported outcomes are summarized across 100 independent stochastic simulations per condition.

Time-resolved trajectories are summarized using the mean and Student-t-based 95% confidence interval across rollouts.

For non-negative quantities, lower confidence limits may be truncated at zero for visualization.

Testing-resource trade-offs are summarized using:

- cumulative testing cost
- reduction in the operational cumulative-infection outcome
- reduction in peak hidden infectious burden
- related burden-reduction-per-cost summaries

Per-cost quantities are descriptive control--resource summaries and should not be interpreted as formal health-economic cost-effectiveness estimates.

---

# Terminology used in the code and manuscript

The following definitions are used throughout the analysis.

### Hidden infectious cases

```text
Ip + Ia
```

These are presymptomatic and asymptomatic infectious individuals who remain hidden from routine surveillance unless detected through testing.

### Hidden infected burden

```text
E + Ip + Ia
```

This broader quantity includes infected individuals in the exposed state.

### Detected hidden infections

True-positive detections from samples collected while an individual was in:

```text
E, Ip, or Ia
```

### Operational cumulative-infection outcome

The manuscript's cumulative-infection outcome is calculated from cumulative:

```text
E -> Ip
```

transitions over the simulation horizon.

It is therefore distinct from the cumulative number of all infection events entering `E`.

### Learned adaptive testing policy

The learned adaptive policy is labeled:

```text
RL mixed
```

internally in the MATLAB plotting code for backward compatibility.

### Fixed mixed PCR--AG strategy

The fixed mixed strategy is labeled:

```text
Half PCR/Ag
```

internally in some analysis files and is represented by the directory tag:

```text
HalfPCRAg
```

---

# Reproducibility scope

The two MATLAB scripts included in this repository reproduce the manuscript figures, tables, and numerical summaries from **precomputed stochastic rollout outputs**.

They do not by themselves:

- generate the original contact network
- run the full stochastic individual-based epidemic model
- train the PPO policies
- generate the rollout data from scratch

Accordingly, these scripts should be described as **analysis and figure-reproduction code** unless the full simulation and reinforcement-learning implementation is also deposited.

For complete end-to-end reproducibility, a full release should additionally include:

- contact-network generation code
- individual-based epidemic simulation environment
- within-host viral-kinetics implementation
- viral-load-dependent infectiousness mapping
- PCR and AG detectability implementation
- testing-eligibility logic
- operational risk-ranking code
- PCR/AG allocation logic
- PPO training code
- PPO evaluation code
- model configuration files
- parameter files
- random-seed settings
- scripts used to save the rollout-level outputs contained in `results/`

---

# Large data files

The rollout-level `results/` directory may be too large for convenient storage directly in GitHub.

A recommended publication workflow is:

```text
GitHub
├── README.md
├── LICENSE
├── code/
└── source_data/
```

with the full rollout-level data archived separately in a versioned repository such as Zenodo.

For example:

```text
Full rollout-level data:
https://doi.org/XX.XXXX/zenodo.XXXXXXX
```

After downloading the archived data, extract the `results/` directory into the repository root:

```text
TwoScaleABM-RL/
├── code/
├── source_data/
└── results/
```

No changes to the MATLAB scripts are required if this directory structure is preserved.

---
