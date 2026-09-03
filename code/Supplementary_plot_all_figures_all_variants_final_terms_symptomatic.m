%% Supplementary_plot_all_figures_all_variants_final_terms.m
% Integrated supplementary plotting code
% Generates Supplementary Figures S1--S14 and Supplementary Tables S1--S4
% Updated to match main-text figure terminology and visual encoding:
% - Action 1 = high-risk coverage, Action 2 = antigen screening,
%   Action 3 = PCR intensity, Action 4 = testing period.
% - Final-size outcomes are displayed as final size.
% - Differences from no testing are displayed as final-size reduction relative to no testing.
% - Testing modality ratio is displayed as PCR and antigen testing ratios.
% - Scatter-plot hue indicates variant and shade intensity indicates target R0.
% - Heatmaps use a pastel autumn color scale.

clear; clc; close all;

%% =====================================================
% User settings
% ======================================================
RESULT_ROOT = "results";
SUPP_DIR = fullfile("figures", "supplementary");
SUPP_CSV_DIR = fullfile(SUPP_DIR, "csv");
SUPP_TABLE_DIR = fullfile(SUPP_DIR, "tables");

if ~exist(SUPP_DIR, "dir"); mkdir(SUPP_DIR); end
if ~exist(SUPP_CSV_DIR, "dir"); mkdir(SUPP_CSV_DIR); end
if ~exist(SUPP_TABLE_DIR, "dir"); mkdir(SUPP_TABLE_DIR); end

VARIANTS = ["Alpha", "Delta", "Omicron"];
TARGET_R0_VALUES = [2.5, 3.5, 4.5];

% Main-text reward trade-off setting
MAIN_THETA = 0.25;

% Sensitivity settings
THETA_VALUES = [0.25, 0.50, 0.75, 1.00];

% Sensitivity variants. Use all variants for S10--S14.
SENSITIVITY_VARIANTS = VARIANTS;

% Time conversion for step-level files.
% Keep this consistent with the run/save code used to generate n_tests and actions.
DAYS_IN_STEP = 3;

MAX_TEST_INTERVAL = 21;

COST_PCR = 100000.0;
COST_AG  = 55920.0;

CI_LEVEL = 0.95;
CI_ALPHA = 1.0 - CI_LEVEL;
FILL_ALPHA = 0.16;

% Cost-effectiveness ratios are unstable when testing cost is zero or nearly zero.
% Values with cumulative cost below this threshold are left blank in heatmaps.
MIN_COST_FOR_COST_EFFECTIVENESS = 1e7;   % 0.01 billion cost units

SAVE_SUPPLEMENTARY_TABLES = true;

%% =====================================================
% Policies
% ======================================================
POLICIES = ["RL mixed", "PCR only", "Ag only", "Half PCR/Ag", "No testing"];
POLICIES_FOR_COST_EFFECTIVENESS = ["RL mixed", "PCR only", "Ag only", "Half PCR/Ag"];

POLICY_TAGS = containers.Map( ...
    {'RL mixed', 'PCR only', 'Ag only', 'Half PCR/Ag', 'No testing'}, ...
    {'dualpool_costonly', 'PCRonly', 'Agonly', 'HalfPCRAg', 'Notesting'} ...
);

POLICY_MARKERS = containers.Map( ...
    {'RL mixed', 'PCR only', 'Ag only', 'Half PCR/Ag', 'No testing'}, ...
    {'o', 's', '^', 'd', 'x'} ...
);

%% =====================================================
% Column definitions
% ======================================================
STATE_COLS = ["S", "E", "Ip", "Ia", "Is", "Dqs", "Dq", "R"];
NEW_IP_COLS = ["new_Ip"];
N_TEST_COLS = ["n_pcr", "n_ag"];

% The saved action files were generated with the original data-column order:
% coverage, antigen screening, testing period, PCR intensity. To avoid
% mis-reading existing outputs, keep this loading order separate from the
% display order used in figures and tables.
ACTION_DATA_COLS = [
    "high_risk_pool_coverage"
    "ag_screening_intensity"
    "retest_interval_days"
    "pcr_high_risk_intensity"
]';

% Main-text display order:
% Action 1 = high-risk coverage, Action 2 = antigen screening,
% Action 3 = PCR intensity, Action 4 = testing period.
ACTION_PLOT_COLS = [
    "high_risk_pool_coverage"
    "ag_screening_intensity"
    "pcr_high_risk_intensity"
    "retest_interval_days"
]';

% Keep ACTION_COLS as an alias for the data-loading order for backward compatibility.
ACTION_COLS = ACTION_DATA_COLS;

ACTION_LABELS = containers.Map( ...
    {'high_risk_pool_coverage', ...
     'ag_screening_intensity', ...
     'pcr_high_risk_intensity', ...
     'retest_interval_days'}, ...
    {'High-risk coverage', ...
     'Antigen screening', ...
     'PCR intensity', ...
     'Testing period'} ...
);

ACTION_NUMBER_LABELS = containers.Map( ...
    {'high_risk_pool_coverage', ...
     'ag_screening_intensity', ...
     'pcr_high_risk_intensity', ...
     'retest_interval_days'}, ...
    {'Action 1: high-risk coverage', ...
     'Action 2: antigen screening', ...
     'Action 3: PCR intensity', ...
     'Action 4: testing period'} ...
);

TESTING_STEP_COLS = [
    "selected_total", ...
    "selected_infected", ...
    "detected_positive", ...
    "reported_cases", ...
    "detected_E", ...
    "detected_Ip", ...
    "detected_Ia", ...
    "detected_E_ag", ...
    "detected_Ip_ag", ...
    "detected_Ia_ag"
];

%% =====================================================
% Detectability settings for Supplementary Fig. S1
% Adjust these to match the exact parameters used in the model if needed.
% ======================================================
DETECT_T_END = 30;
DETECT_DT = 0.05;
DETECT_EPS = 1e-12;

% Logistic detectability on normalized viral load.
% PCR threshold lower; antigen threshold higher.
PCR_MAX_SENS = 0.95;
AG_MAX_SENS  = 0.80;
PCR_THRESHOLD_NORM = 0.02;
AG_THRESHOLD_NORM  = 0.20;
PCR_STEEPNESS = 18;
AG_STEEPNESS  = 22;

%% =====================================================
% Main execution
% ======================================================
fprintf("========================================\n");
fprintf("Generating Supplementary Figures S1--S14\n");
fprintf("Generating Supplementary Tables S1--S4\n");
fprintf("Output directory: %s\n", SUPP_DIR);
fprintf("Theta values: %s\n", mat2str(THETA_VALUES));
fprintf("Sensitivity variants: %s\n", strjoin(SENSITIVITY_VARIANTS, ", "));
fprintf("========================================\n");

% S1
plot_supp_s1_detectability();

% S2--S3
plot_supp_policy_performance(2.5, "Supp_Figure_S2_policy_performance_R0_2p5");
plot_supp_policy_performance(4.5, "Supp_Figure_S3_policy_performance_R0_4p5");

% S4
plot_supp_s4_alternative_tradeoffs();

% S5--S7
plot_supp_actions_by_r0(2.5, "Supp_Figure_S5_learned_actions_R0_2p5");
plot_supp_actions_by_r0(3.5, "Supp_Figure_S6_learned_actions_R0_3p5");
plot_supp_actions_by_r0(4.5, "Supp_Figure_S7_learned_actions_R0_4p5");

% S8--S9
plot_supp_testing_detection_by_r0(2.5, "Supp_Figure_S8_testing_detection_R0_2p5");
plot_supp_testing_detection_by_r0(4.5, "Supp_Figure_S9_testing_detection_R0_4p5");

% S10--S14: theta sensitivity across all variants
plot_supp_s10_theta_policy_performance_all_variants();
plot_supp_s11_theta_tradeoff_all_variants();
plot_supp_s12_theta_actions_all_variants();
plot_supp_s13_theta_testing_detection_all_variants();
plot_supp_s14_theta_scalar_outcomes_all_variants();

% Tables S1--S4
if SAVE_SUPPLEMENTARY_TABLES
    write_supplementary_tables();
end

fprintf("\nFinished generating supplementary figures and tables.\n");

%% =====================================================
% Supplementary Figure S1
% Full viral kinetics and diagnostic detectability profiles
% ======================================================
function plot_supp_s1_detectability()
    vars = evalin("base", "VARIANTS");
    suppDir = evalin("base", "SUPP_DIR");
    csvDir = evalin("base", "SUPP_CSV_DIR");

    fig = figure("Color", "w", "Position", [70, 70, 1450, 900]);
    tiledlayout(3, numel(vars), "TileSpacing", "compact", "Padding", "compact");

    allRows = table();

    for i = 1:numel(vars)
        variant = vars(i);
        [t, V, Vnorm, pcr, ag, peakTime] = simulate_detectability_profile(variant);

        row = table();
        row.variant = repmat(variant, numel(t), 1);
        row.day = t(:);
        row.viral_load = V(:);
        row.normalized_viral_load = Vnorm(:);
        row.pcr_detectability = pcr(:);
        row.antigen_detectability = ag(:);
        row.peak_time = repmat(peakTime, numel(t), 1);
        allRows = [allRows; row]; %#ok<AGROW>

        ax1 = nexttile(i);
        hold(ax1, "on");
        plot(ax1, t, max(Vnorm, 1e-8), "Color", get_variant_color(variant, 0), "LineWidth", 2.0);
        xline(ax1, peakTime, "--", "Color", darken(get_variant_color(variant, 0), 0.25), "LineWidth", 1.0);
        yline(ax1, evalin("base", "PCR_THRESHOLD_NORM"), ":", "Color", [0.35 0.35 0.35], "LineWidth", 0.8);
        yline(ax1, evalin("base", "AG_THRESHOLD_NORM"), "--", "Color", [0.35 0.35 0.35], "LineWidth", 0.8);
        set(ax1, "YScale", "log");
        ylim(ax1, [1e-6, 1.2]);
        title(ax1, sprintf("%s viral load", variant), "FontWeight", "normal");
        if i == 1; ylabel(ax1, "Normalized viral load"); end
        grid(ax1, "on");
        clean_axis(ax1);

        ax2 = nexttile(numel(vars) + i);
        hold(ax2, "on");
        plot(ax2, t, pcr, "Color", get_variant_color(variant, 0), "LineWidth", 2.0);
        xline(ax2, peakTime, "--", "Color", darken(get_variant_color(variant, 0), 0.25), "LineWidth", 1.0);
        ylim(ax2, [0, 1.02]);
        title(ax2, "PCR detectability", "FontWeight", "normal");
        if i == 1; ylabel(ax2, "Probability"); end
        grid(ax2, "on");
        clean_axis(ax2);

        ax3 = nexttile(2 * numel(vars) + i);
        hold(ax3, "on");
        plot(ax3, t, ag, "Color", get_variant_color(variant, 0), "LineWidth", 2.0);
        xline(ax3, peakTime, "--", "Color", darken(get_variant_color(variant, 0), 0.25), "LineWidth", 1.0);
        ylim(ax3, [0, 1.02]);
        title(ax3, "Antigen detectability", "FontWeight", "normal");
        xlabel(ax3, "Days since infection");
        if i == 1; ylabel(ax3, "Probability"); end
        grid(ax3, "on");
        clean_axis(ax3);
    end

    writetable(allRows, fullfile(csvDir, "Supp_Figure_S1_detectability_profiles.csv"));

    sgtitle("Variant-specific viral-load and diagnostic detectability profiles", ...
        "FontWeight", "normal");

    save_figure(fig, fullfile(suppDir, "Supp_Figure_S1_detectability_profiles"));
end

%% =====================================================
% Supplementary Figures S2--S3
% Policy performance at R0 = 2.5 and 4.5
% ======================================================
function plot_supp_policy_performance(r0, saveName)
    vars = evalin("base", "VARIANTS");
    policies = evalin("base", "POLICIES");
    suppDir = evalin("base", "SUPP_DIR");
    csvDir = evalin("base", "SUPP_CSV_DIR");

    lineMetricSpecs = {
        "hidden_EIpIa",       "Hidden infection burden";
        "symptomatic_infectious",  "Symptomatic infectious cases"
    };

    fig = figure("Color", "w", "Position", [80, 80, 1500, 980]);
    tiledlayout(numel(vars), 3, "TileSpacing", "compact", "Padding", "compact");

    csvLineParts = table();
    csvBarParts = table();

    for i = 1:numel(vars)
        variant = vars(i);

        for j = 1:size(lineMetricSpecs, 1)
            ax = nexttile((i - 1) * 3 + j);
            hold(ax, "on");

            metricName = lineMetricSpecs{j, 1};
            metricLabel = lineMetricSpecs{j, 2};
            anyPlotted = false;

            for pp = 1:numel(policies)
                policy = policies(pp);
                result = load_scenario(variant, r0, policy, NaN, false);

                if isempty(result)
                    continue;
                end

                color = get_policy_color(policy);
                lineWidth = 1.4;
                showCI = false;

                if policy == "RL mixed" || policy == "No testing"
                    showCI = true;
                    lineWidth = 2.2;
                end

                [summary, ~] = plot_mean_tci_color( ...
                    ax, result.state, metricName, policy, "day", ...
                    color, lineWidth, showCI ...
                );

                summary = add_plot_metadata(summary, saveName, variant, r0, policy, metricLabel);
                csvLineParts = [csvLineParts; summary]; %#ok<AGROW>
                anyPlotted = true;
            end

            if ~anyPlotted
                mark_missing_panel(ax, metricLabel);
            end

            if i == 1
                title(ax, metricLabel, "FontWeight", "normal");
            end

            if j == 1
                ylabel(ax, sprintf("%s\nCases", variant), ...
                    "Color", get_variant_color(variant, 0), ...
                    "FontWeight", "bold");
            end

            if i == numel(vars)
                xlabel(ax, "Day");
            end

            grid(ax, "on");
            set_y_lower_zero(ax);
            clean_axis(ax);
        end

        axBar = nexttile((i - 1) * 3 + 3);
        hold(axBar, "on");

        barRows = table();

        for pp = 1:numel(policies)
            policy = policies(pp);
            result = load_scenario(variant, r0, policy, NaN, false);

            if isempty(result)
                continue;
            end

            finalCum = final_by_rollout(result.new_ip, "cum_infections");

            row = summarize_policy_bar_row( ...
                variant, r0, policy, ...
                "Final size", ...
                finalCum.cum_infections ...
            );

            barRows = [barRows; row]; %#ok<AGROW>
        end

        if height(barRows) > 0
            plot_policy_final_bar(axBar, barRows, policies);
            csvBarParts = [csvBarParts; barRows]; %#ok<AGROW>
        else
            mark_missing_panel(axBar, "Final size");
        end

        if i == 1
            title(axBar, "Final size", "FontWeight", "normal");
        end

        if i == numel(vars)
            xlabel(axBar, "Policy");
        end

        ylabel(axBar, "Cases");
        grid(axBar, "on");
        set_y_lower_zero(axBar);
        clean_axis(axBar);
    end

    lgdAx = nexttile(1);
    legend(lgdAx, "Location", "northwest", "Box", "off", "FontSize", 8);

    if height(csvLineParts) > 0
        writetable(csvLineParts, fullfile(csvDir, saveName + "_trajectories.csv"));
    end

    if height(csvBarParts) > 0
        writetable(csvBarParts, fullfile(csvDir, saveName + "_final_cumulative_bar.csv"));
    end

    sgtitle(sprintf("Policy performance across testing strategies, target R0 = %.1f", r0), ...
        "FontWeight", "normal");

    save_figure(fig, fullfile(suppDir, saveName));
end

%% =====================================================
% Supplementary Figure S4
% Alternative control-cost trade-offs
% ======================================================
function plot_supp_s4_alternative_tradeoffs()
    vars = evalin("base", "VARIANTS");
    policies = evalin("base", "POLICIES");
    r0s = evalin("base", "TARGET_R0_VALUES");
    suppDir = evalin("base", "SUPP_DIR");
    csvDir = evalin("base", "SUPP_CSV_DIR");

    scalarTable = build_main_scalar_table();
    writetable(scalarTable, fullfile(csvDir, "Supp_Figure_S4_alternative_tradeoff_values.csv"));

    metrics = [
        "peak_hidden_reduction_mean"
        "hidden_burden_reduction_mean"
        "symptomatic_burden_reduction_mean"
        "hidden_burden_reduction_per_1B_mean"
    ];

    metricLabels = [
        "Peak-size reduction"
        "Integrated hidden-burden reduction"
        "Integrated symptomatic-burden reduction"
        "Hidden-burden reduction per 1B cost"
    ];

    fig = figure("Color", "w", "Position", [60, 60, 1550, 950]);
    tiledlayout(2, 2, "TileSpacing", "compact", "Padding", "compact");

    plotPolicies = policies(policies ~= "No testing");

    for m = 1:numel(metrics)
        ax = nexttile(m);
        hold(ax, "on");

        metric = metrics(m);
        anyPlotted = false;

        for vi = 1:numel(vars)
            variant = vars(vi);

            for pp = 1:numel(plotPolicies)
                policy = plotPolicies(pp);
                marker = get_policy_marker(policy);

                for rr = 1:numel(r0s)
                    r0 = r0s(rr);

                    idx = scalarTable.variant == variant & ...
                          scalarTable.policy == policy & ...
                          abs(scalarTable.R0 - r0) < 1e-12;

                    if ~any(idx) || ~ismember(metric, string(scalarTable.Properties.VariableNames))
                        continue;
                    end

                    x = scalarTable.cum_testing_cost_mean(idx) / 1e9;
                    y = scalarTable.(metric)(idx);

                    if ~isfinite(x) || x <= 0 || ~isfinite(y)
                        continue;
                    end

                    c = get_variant_r0_color(variant, r0);
                    h = scatter(ax, x, y, 55);
                    h.Marker = marker;
                    h.MarkerFaceColor = c;
                    h.MarkerEdgeColor = darken(get_variant_color(variant, 0), 0.30);
                    h.LineWidth = 0.8;

                    anyPlotted = true;
                end
            end
        end

        if anyPlotted
            set(ax, "XScale", "log");
            xlabel(ax, "Cumulative testing cost (billion cost units, log scale)");
            ylabel(ax, metricLabels(m));
            yline(ax, 0, "--", "Color", [0.45 0.45 0.45], "LineWidth", 0.8);
            grid(ax, "on");
            set_y_lower_zero(ax);
        else
            mark_missing_panel(ax, metricLabels(m));
        end

        title(ax, metricLabels(m), "FontWeight", "normal");
        clean_axis(ax);

        if m == 1
            add_scatter_legend(ax, vars, plotPolicies, r0s);
        end
    end

    sgtitle("Alternative control-cost trade-offs", ...
        "FontWeight", "normal");

    save_figure(fig, fullfile(suppDir, "Supp_Figure_S4_alternative_tradeoffs"));
end

%% =====================================================
% Supplementary Figures S5--S7
% Expanded learned actions by R0
% ======================================================
function plot_supp_actions_by_r0(r0, saveName)
    vars = evalin("base", "VARIANTS");
    actionCols = evalin("base", "ACTION_PLOT_COLS");
    actionLabels = evalin("base", "ACTION_NUMBER_LABELS");
    maxInterval = evalin("base", "MAX_TEST_INTERVAL");
    suppDir = evalin("base", "SUPP_DIR");
    csvDir = evalin("base", "SUPP_CSV_DIR");

    fig = figure("Color", "w", "Position", [70, 70, 1650, 940]);
    tiledlayout(numel(vars), numel(actionCols), "TileSpacing", "compact", "Padding", "compact");

    csvParts = table();

    for i = 1:numel(vars)
        variant = vars(i);

        result = load_scenario(variant, r0, "RL mixed", NaN, false);

        for j = 1:numel(actionCols)
            actionCol = actionCols(j);
            ax = nexttile((i - 1) * numel(actionCols) + j);
            hold(ax, "on");

            if isempty(result) || isempty(result.actions)
                mark_missing_panel(ax, actionLabels(char(actionCol)));
            else
                color = get_variant_color(variant, 0);

                [summary, ~] = plot_mean_tci_color( ...
                    ax, result.actions, actionCol, variant, "day", ...
                    color, 2.1, true ...
                );

                summary = add_plot_metadata(summary, saveName, variant, r0, "RL mixed", actionCol);
                csvParts = [csvParts; summary]; %#ok<AGROW>
            end

            if i == 1
                title(ax, actionLabels(char(actionCol)), "FontWeight", "normal");
            end

            if j == 1
                ylabel(ax, variant, ...
                    "Color", get_variant_color(variant, 0), ...
                    "FontWeight", "bold");
            end

            if i == numel(vars)
                xlabel(ax, "Day");
            end

            if actionCol == "retest_interval_days"
                ylim(ax, [0, maxInterval + 0.5]);
            else
                ylim(ax, [0, 1.05]);
            end

            grid(ax, "on");
            clean_axis(ax);
        end
    end

    if height(csvParts) > 0
        writetable(csvParts, fullfile(csvDir, saveName + ".csv"));
    end

    sgtitle(sprintf("Learned testing actions, target R0 = %.1f", r0), ...
        "FontWeight", "normal");

    save_figure(fig, fullfile(suppDir, saveName));
end

%% =====================================================
% Supplementary Figures S8--S9
% Expanded realized testing and hidden-case detection
% ======================================================
function plot_supp_testing_detection_by_r0(r0, saveName)
    vars = evalin("base", "VARIANTS");
    suppDir = evalin("base", "SUPP_DIR");
    csvDir = evalin("base", "SUPP_CSV_DIR");

    fig = figure("Color", "w", "Position", [80, 80, 1450, 920]);
    tiledlayout(2, 2, "TileSpacing", "compact", "Padding", "compact");

    barTests = table();
    barDetections = table();
    pcrShareParts = table();
    effParts = table();

    for i = 1:numel(vars)
        variant = vars(i);
        result = load_scenario(variant, r0, "RL mixed", NaN, false);

        if isempty(result)
            continue;
        end

        [bt, bd, ps, ef] = extract_testing_detection_summary(result);
        barTests = [barTests; bt]; %#ok<AGROW>
        barDetections = [barDetections; bd]; %#ok<AGROW>
        pcrShareParts = [pcrShareParts; ps]; %#ok<AGROW>
        effParts = [effParts; ef]; %#ok<AGROW>
    end

    ax1 = nexttile(1);
    if height(barTests) > 0
        plot_grouped_assay_bars(ax1, barTests, "Number of tests");
        set(ax1, "YScale", "log");
    else
        mark_missing_panel(ax1, "Cumulative testing allocation");
    end
    title(ax1, "Cumulative testing allocation", "FontWeight", "normal");
    grid(ax1, "on");
    clean_axis(ax1);

    ax2 = nexttile(2);
    if height(barDetections) > 0
        plot_grouped_assay_bars(ax2, barDetections, "Detected hidden cases");
        set(ax2, "YScale", "log");
    else
        mark_missing_panel(ax2, "Cumulative hidden cases detected");
    end
    title(ax2, "Cumulative hidden cases detected", "FontWeight", "normal");
    grid(ax2, "on");
    clean_axis(ax2);

    ax3 = nexttile(3);
    hold(ax3, "on");
    if height(pcrShareParts) > 0
        ratioModalities = ["PCR", "Antigen"];
        for i = 1:numel(vars)
            variant = vars(i);
            cBase = get_variant_color(variant, 0);
            for mm = 1:numel(ratioModalities)
                modality = ratioModalities(mm);
                sub = pcrShareParts(pcrShareParts.variant == variant & pcrShareParts.modality == modality, :);
                if height(sub) == 0; continue; end
                if modality == "PCR"
                    c = darken(cBase, 0.10);
                    ls = "-";
                else
                    c = lighten(cBase, 0.45);
                    ls = ":";
                end
                plot_summary_ci(ax3, sub, sprintf("%s %s", variant, modality), c, 1.8, true, ls);
            end
        end
        ylim(ax3, [0, 1.05]);
        legend(ax3, "Location", "best", "Box", "off", "FontSize", 7);
    else
        mark_missing_panel(ax3, "Testing modality ratio over time");
    end
    title(ax3, "Testing modality ratio over time", "FontWeight", "normal");
    xlabel(ax3, "Day");
    ylabel(ax3, "Testing modality ratio");
    grid(ax3, "on");
    clean_axis(ax3);

    ax4 = nexttile(4);
    hold(ax4, "on");
    if height(effParts) > 0
        for i = 1:numel(vars)
            variant = vars(i);
            sub = effParts(effParts.variant == variant, :);
            if height(sub) == 0; continue; end
            c = get_variant_color(variant, 0);
            plot_summary_ci(ax4, sub, variant, c, 2.0, true);
        end
        legend(ax4, "Location", "best", "Box", "off", "FontSize", 8);
        set_y_lower_zero(ax4);
    else
        mark_missing_panel(ax4, "Detection efficiency over time");
    end
    title(ax4, "Detection efficiency over time", "FontWeight", "normal");
    xlabel(ax4, "Day");
    ylabel(ax4, "Detected hidden cases per test");
    grid(ax4, "on");
    clean_axis(ax4);

    if height(barTests) > 0
        writetable(barTests, fullfile(csvDir, saveName + "_cumulative_tests.csv"));
    end
    if height(barDetections) > 0
        writetable(barDetections, fullfile(csvDir, saveName + "_hidden_detections.csv"));
    end
    if height(pcrShareParts) > 0
        writetable(pcrShareParts, fullfile(csvDir, saveName + "_testing_modality_ratio.csv"));
    end
    if height(effParts) > 0
        writetable(effParts, fullfile(csvDir, saveName + "_detection_efficiency.csv"));
    end

    sgtitle(sprintf("Realized testing and hidden-case detection, target R0 = %.1f", r0), ...
        "FontWeight", "normal");

    save_figure(fig, fullfile(suppDir, saveName));
end

%% =====================================================
% Supplementary Figures S10--S14 across all variants
% ======================================================
function plot_supp_s10_theta_policy_performance_all_variants()
    vars = evalin("base", "SENSITIVITY_VARIANTS");
    r0s = evalin("base", "TARGET_R0_VALUES");
    thetas = evalin("base", "THETA_VALUES");
    suppDir = evalin("base", "SUPP_DIR");
    csvDir = evalin("base", "SUPP_CSV_DIR");

    fig = figure("Color", "w", "Position", [40, 40, 1650, 2300]);
    tiledlayout(numel(vars) * numel(r0s), 3, "TileSpacing", "compact", "Padding", "compact");

    csvLineParts = table();
    csvBarParts = table();

    lineMetrics = {
        "hidden_EIpIa",       "Hidden infection burden";
        "symptomatic_infectious",  "Symptomatic infectious cases"
    };

    rowIdx = 0;

    for vv = 1:numel(vars)
        variant = vars(vv);

        for rr = 1:numel(r0s)
            r0 = r0s(rr);
            rowIdx = rowIdx + 1;

            for mm = 1:size(lineMetrics, 1)
                metricName = lineMetrics{mm, 1};
                metricLabel = lineMetrics{mm, 2};

                ax = nexttile((rowIdx - 1) * 3 + mm);
                hold(ax, "on");

                anyPlotted = false;

                for tt = 1:numel(thetas)
                    theta = thetas(tt);
                    result = load_scenario(variant, r0, "RL mixed", theta, false);

                    if isempty(result)
                        continue;
                    end

                    c = get_theta_color(theta, tt, numel(thetas));
                    ls = get_theta_line_style(tt);

                    [summary, ~] = plot_mean_tci_color_style( ...
                        ax, result.state, metricName, theta_label(theta), ...
                        "day", c, 1.8, true, ls ...
                    );

                    summary = add_plot_metadata(summary, "Supp_Figure_S10_all_variants", ...
                        variant, r0, "RL mixed", metricName);
                    summary.theta = repmat(theta, height(summary), 1);
                    csvLineParts = [csvLineParts; summary]; %#ok<AGROW>
                    anyPlotted = true;
                end

                if ~anyPlotted
                    mark_missing_panel(ax, metricLabel);
                end

                if rowIdx == 1
                    title(ax, metricLabel, "FontWeight", "normal");
                end

                if mm == 1
                    ylabel(ax, sprintf("%s\nR0 = %.1f\nCases", variant, r0), ...
                        "Color", get_variant_color(variant, 0), ...
                        "FontWeight", "bold");
                end

                if rowIdx == numel(vars) * numel(r0s)
                    xlabel(ax, "Day");
                end

                grid(ax, "on");
                set_y_lower_zero(ax);
                clean_axis(ax);

                if rowIdx == 1 && mm == 1
                    legend(ax, "Location", "northwest", "Box", "off", "FontSize", 7);
                end
            end

            axBar = nexttile((rowIdx - 1) * 3 + 3);
            hold(axBar, "on");

            barRows = table();

            for tt = 1:numel(thetas)
                theta = thetas(tt);
                result = load_scenario(variant, r0, "RL mixed", theta, false);

                if isempty(result)
                    row = missing_theta_bar_row(variant, r0, theta, "Final size");
                else
                    finalCum = final_by_rollout(result.new_ip, "cum_infections");
                    row = summarize_theta_bar_row(variant, r0, theta, ...
                        "Final size", finalCum.cum_infections);
                end

                barRows = [barRows; row]; %#ok<AGROW>
            end

            plot_theta_bar(axBar, barRows, thetas, "Final size");
            csvBarParts = [csvBarParts; barRows]; %#ok<AGROW>

            if rowIdx == 1
                title(axBar, "Final size", "FontWeight", "normal");
            end

            if rowIdx == numel(vars) * numel(r0s)
                xlabel(axBar, "\theta");
            end

            ylabel(axBar, "Cases");
            grid(axBar, "on");
            set_y_lower_zero(axBar);
            clean_axis(axBar);
        end
    end

    if height(csvLineParts) > 0
        writetable(csvLineParts, fullfile(csvDir, "Supp_Figure_S10_theta_policy_all_variants_trajectories.csv"));
    end

    writetable(csvBarParts, fullfile(csvDir, "Supp_Figure_S10_theta_policy_all_variants_final_cumulative.csv"));

    sgtitle("Epidemic-outcome sensitivity to testing-cost weight", ...
        "FontWeight", "normal");

    save_figure(fig, fullfile(suppDir, "Supp_Figure_S10_theta_policy_performance_all_variants"));
end

function plot_supp_s11_theta_tradeoff_all_variants()
    vars = evalin("base", "SENSITIVITY_VARIANTS");
    r0s = evalin("base", "TARGET_R0_VALUES");
    thetas = evalin("base", "THETA_VALUES");
    suppDir = evalin("base", "SUPP_DIR");
    csvDir = evalin("base", "SUPP_CSV_DIR");

    scalarTable = build_theta_scalar_table_all_variants();
    scalarTable = add_ratio_of_means_effectiveness(scalarTable);

    writetable(scalarTable, fullfile(csvDir, "Supp_Figure_S11_theta_tradeoff_all_variants_values.csv"));

    fig = figure("Color", "w", "Position", [60, 60, 1750, 1000]);
    tiledlayout(2, 2, "TileSpacing", "compact", "Padding", "compact");

    ax1 = nexttile(1);
    hold(ax1, "on");

    anyScatter = false;

    for vv = 1:numel(vars)
        variant = vars(vv);

        for tt = 1:numel(thetas)
            theta = thetas(tt);

            for rr = 1:numel(r0s)
                r0 = r0s(rr);

                idx = scalarTable.variant == variant & ...
                      scalarTable.theta == theta & ...
                      abs(scalarTable.R0 - r0) < 1e-12;

                if ~any(idx)
                    continue;
                end

                x = scalarTable.cum_testing_cost_mean(idx) / 1e9;
                y = scalarTable.infections_averted_mean(idx);

                if ~isfinite(x) || x <= 0 || ~isfinite(y)
                    continue;
                end

                c = get_variant_r0_color(variant, r0);
                h = scatter(ax1, x, y, 65);
                h.Marker = get_theta_marker(theta, tt);
                h.MarkerFaceColor = c;
                h.MarkerEdgeColor = darken(get_variant_color(variant, 0), 0.30);
                h.LineWidth = 0.8;

                anyScatter = true;
            end
        end
    end

    if anyScatter
        set(ax1, "XScale", "log");
        xlabel(ax1, "Cumulative testing cost (billion cost units, log scale)");
        ylabel(ax1, "Final-size reduction");
        yline(ax1, 0, "--", "Color", [0.45 0.45 0.45], "LineWidth", 0.8);
        grid(ax1, "on");
        set_y_lower_zero(ax1);
        add_variant_r0_theta_legend(ax1, vars, r0s, thetas);
    else
        mark_missing_panel(ax1, "Cost vs final-size reduction");
    end

    title(ax1, "Cost vs final-size reduction", "FontWeight", "normal");
    clean_axis(ax1);

    heatMetrics = [
        "cum_testing_cost_mean"
        "infections_averted_mean"
        "infections_averted_per_1B_mean"
    ];

    heatLabels = [
        "Cumulative testing cost (B)"
        "Final-size reduction"
        "Final-size reduction per 1B cost"
    ];

    for mm = 1:3
        ax = nexttile(mm + 1);
        metric = heatMetrics(mm);

        [mat, colLabels] = theta_variant_r0_matrix(scalarTable, metric, thetas, vars, r0s);

        if metric == "cum_testing_cost_mean"
            mat = mat ./ 1e9;
        end

        if all(~isfinite(mat(:)))
            mark_missing_panel(ax, heatLabels(mm));
        else
            hImg = imagesc(ax, mat);
            set(hImg, "AlphaData", isfinite(mat));
            set(ax, "Color", [0.96 0.96 0.96]);
            colormap(ax, make_pastel_autumn_cmap(128));
            colorbar(ax);
            xticks(ax, 1:numel(colLabels));
            xticklabels(ax, colLabels);
            xtickangle(ax, 45);
            yticks(ax, 1:numel(thetas));
            yticklabels(ax, arrayfun(@theta_label, thetas, "UniformOutput", false));
            xlabel(ax, "Variant and target R0");
            ylabel(ax, "\theta");
            add_heatmap_text(ax, mat, metric);
            add_variant_block_separators(ax, numel(r0s), numel(vars));
        end

        title(ax, heatLabels(mm), "FontWeight", "normal");
        clean_heatmap_axis(ax);
    end

    sgtitle("Control-cost sensitivity to testing-cost weight", ...
        "FontWeight", "normal");

    save_figure(fig, fullfile(suppDir, "Supp_Figure_S11_theta_tradeoff_all_variants"));
end

function plot_supp_s12_theta_actions_all_variants()
    vars = evalin("base", "SENSITIVITY_VARIANTS");
    r0s = evalin("base", "TARGET_R0_VALUES");
    thetas = evalin("base", "THETA_VALUES");
    actionCols = evalin("base", "ACTION_PLOT_COLS");
    actionLabels = evalin("base", "ACTION_NUMBER_LABELS");
    maxInterval = evalin("base", "MAX_TEST_INTERVAL");
    suppDir = evalin("base", "SUPP_DIR");
    csvDir = evalin("base", "SUPP_CSV_DIR");

    nRows = numel(vars) * numel(r0s);

    fig = figure("Color", "w", "Position", [40, 40, 1850, 2400]);
    tiledlayout(nRows, numel(actionCols), "TileSpacing", "compact", "Padding", "compact");

    csvParts = table();

    rowIdx = 0;

    for vv = 1:numel(vars)
        variant = vars(vv);

        for rr = 1:numel(r0s)
            r0 = r0s(rr);
            rowIdx = rowIdx + 1;

            for aa = 1:numel(actionCols)
                actionCol = actionCols(aa);
                ax = nexttile((rowIdx - 1) * numel(actionCols) + aa);
                hold(ax, "on");

                anyPlotted = false;

                for tt = 1:numel(thetas)
                    theta = thetas(tt);
                    result = load_scenario(variant, r0, "RL mixed", theta, false);

                    if isempty(result) || isempty(result.actions)
                        continue;
                    end

                    c = get_theta_color(theta, tt, numel(thetas));
                    ls = get_theta_line_style(tt);

                    [summary, ~] = plot_mean_tci_color_style( ...
                        ax, result.actions, actionCol, theta_label(theta), ...
                        "day", c, 1.8, true, ls ...
                    );

                    summary = add_plot_metadata(summary, "Supp_Figure_S12_all_variants", ...
                        variant, r0, "RL mixed", actionCol);
                    summary.theta = repmat(theta, height(summary), 1);
                    csvParts = [csvParts; summary]; %#ok<AGROW>
                    anyPlotted = true;
                end

                if ~anyPlotted
                    mark_missing_panel(ax, actionLabels(char(actionCol)));
                end

                if rowIdx == 1
                    title(ax, actionLabels(char(actionCol)), "FontWeight", "normal");
                end

                if aa == 1
                    ylabel(ax, sprintf("%s\nR0 = %.1f", variant, r0), ...
                        "Color", get_variant_color(variant, 0), ...
                        "FontWeight", "bold");
                end

                if rowIdx == nRows
                    xlabel(ax, "Day");
                end

                if actionCol == "retest_interval_days"
                    ylim(ax, [0, maxInterval + 0.5]);
                else
                    ylim(ax, [0, 1.05]);
                end

                grid(ax, "on");
                clean_axis(ax);

                if rowIdx == 1 && aa == 1
                    legend(ax, "Location", "northwest", "Box", "off", "FontSize", 7);
                end
            end
        end
    end

    if height(csvParts) > 0
        writetable(csvParts, fullfile(csvDir, "Supp_Figure_S12_theta_actions_all_variants.csv"));
    end

    sgtitle("Testing-action sensitivity to testing-cost weight", ...
        "FontWeight", "normal");

    save_figure(fig, fullfile(suppDir, "Supp_Figure_S12_theta_actions_all_variants"));
end

function plot_supp_s13_theta_testing_detection_all_variants()
    vars = evalin("base", "SENSITIVITY_VARIANTS");
    r0s = evalin("base", "TARGET_R0_VALUES");
    thetas = evalin("base", "THETA_VALUES");
    suppDir = evalin("base", "SUPP_DIR");
    csvDir = evalin("base", "SUPP_CSV_DIR");

    nRows = numel(vars) * numel(r0s);

    fig = figure("Color", "w", "Position", [40, 40, 1850, 2400]);
    tiledlayout(nRows, 4, "TileSpacing", "compact", "Padding", "compact");

    csvBarTests = table();
    csvBarDetect = table();
    csvShare = table();
    csvEff = table();

    rowIdx = 0;

    for vv = 1:numel(vars)
        variant = vars(vv);

        for rr = 1:numel(r0s)
            r0 = r0s(rr);
            rowIdx = rowIdx + 1;

            barTests = table();
            barDetections = table();
            pcrShareParts = table();
            effParts = table();

            for tt = 1:numel(thetas)
                theta = thetas(tt);
                result = load_scenario(variant, r0, "RL mixed", theta, false);

                if isempty(result)
                    barTests = [barTests; missing_theta_assay_rows(variant, r0, theta, "tests")]; %#ok<AGROW>
                    barDetections = [barDetections; missing_theta_assay_rows(variant, r0, theta, "detections")]; %#ok<AGROW>
                    continue;
                end

                [bt, bd, ps, ef] = extract_testing_detection_summary(result);

                bt.theta = repmat(theta, height(bt), 1);
                bt.metric = repmat("tests", height(bt), 1);

                bd.theta = repmat(theta, height(bd), 1);
                bd.metric = repmat("detections", height(bd), 1);

                ps.theta = repmat(theta, height(ps), 1);
                ef.theta = repmat(theta, height(ef), 1);

                barTests = [barTests; bt]; %#ok<AGROW>
                barDetections = [barDetections; bd]; %#ok<AGROW>
                pcrShareParts = [pcrShareParts; ps]; %#ok<AGROW>
                effParts = [effParts; ef]; %#ok<AGROW>
            end

            csvBarTests = [csvBarTests; barTests]; %#ok<AGROW>
            csvBarDetect = [csvBarDetect; barDetections]; %#ok<AGROW>
            csvShare = [csvShare; pcrShareParts]; %#ok<AGROW>
            csvEff = [csvEff; effParts]; %#ok<AGROW>

            ax1 = nexttile((rowIdx - 1) * 4 + 1);
            plot_theta_assay_bars(ax1, barTests, thetas, "Number of tests");
            if rowIdx == 1
                title(ax1, "Cumulative tests", "FontWeight", "normal");
            end
            ylabel(ax1, sprintf("%s\nR0 = %.1f", variant, r0), ...
                "Color", get_variant_color(variant, 0), ...
                "FontWeight", "bold");
            set(ax1, "YScale", "log");
            grid(ax1, "on");
            clean_axis(ax1);

            ax2 = nexttile((rowIdx - 1) * 4 + 2);
            plot_theta_assay_bars(ax2, barDetections, thetas, "Detected hidden cases");
            if rowIdx == 1
                title(ax2, "Detected hidden cases", "FontWeight", "normal");
            end
            set(ax2, "YScale", "log");
            grid(ax2, "on");
            clean_axis(ax2);

            ax3 = nexttile((rowIdx - 1) * 4 + 3);
            hold(ax3, "on");
            anyShare = false;

            ratioModalities = ["PCR", "Antigen"];
            for tt = 1:numel(thetas)
                theta = thetas(tt);
                for mm = 1:numel(ratioModalities)
                    modality = ratioModalities(mm);
                    sub = pcrShareParts(pcrShareParts.theta == theta & pcrShareParts.modality == modality, :);
                    if height(sub) == 0
                        continue;
                    end

                    base = get_theta_color(theta, tt, numel(thetas));
                    if modality == "PCR"
                        c = darken(base, 0.10);
                        ls = "-";
                    else
                        c = lighten(base, 0.45);
                        ls = ":";
                    end
                    plot_summary_ci(ax3, sub, sprintf("%s %s", theta_label(theta), modality), c, 1.4, true, ls);
                    anyShare = true;
                end
            end

            if ~anyShare
                mark_missing_panel(ax3, "Testing modality ratio");
            end

            ylim(ax3, [0, 1.05]);
            if rowIdx == 1
                title(ax3, "Testing modality ratio", "FontWeight", "normal");
            end
            if rowIdx == nRows
                xlabel(ax3, "Day");
            end
            ylabel(ax3, "Testing modality ratio");
            grid(ax3, "on");
            clean_axis(ax3);

            if rowIdx == 1
                legend(ax3, "Location", "best", "Box", "off", "FontSize", 7);
            end

            ax4 = nexttile((rowIdx - 1) * 4 + 4);
            hold(ax4, "on");
            anyEff = false;

            for tt = 1:numel(thetas)
                theta = thetas(tt);
                sub = effParts(effParts.theta == theta, :);
                if height(sub) == 0
                    continue;
                end

                c = get_theta_color(theta, tt, numel(thetas));
                plot_summary_ci(ax4, sub, theta_label(theta), c, 1.6, true);
                anyEff = true;
            end

            if ~anyEff
                mark_missing_panel(ax4, "Detection efficiency");
            end

            if rowIdx == 1
                title(ax4, "Detection efficiency", "FontWeight", "normal");
            end
            if rowIdx == nRows
                xlabel(ax4, "Day");
            end
            ylabel(ax4, "Detected hidden cases per test");
            grid(ax4, "on");
            set_y_lower_zero(ax4);
            clean_axis(ax4);
        end
    end

    writetable(csvBarTests, fullfile(csvDir, "Supp_Figure_S13_theta_testing_all_variants_tests.csv"));
    writetable(csvBarDetect, fullfile(csvDir, "Supp_Figure_S13_theta_testing_all_variants_detections.csv"));
    writetable(csvShare, fullfile(csvDir, "Supp_Figure_S13_theta_testing_all_variants_testing_modality_ratio.csv"));
    writetable(csvEff, fullfile(csvDir, "Supp_Figure_S13_theta_testing_all_variants_efficiency.csv"));

    sgtitle("Realized-testing and hidden-case-detection sensitivity to testing-cost weight", ...
        "FontWeight", "normal");

    save_figure(fig, fullfile(suppDir, "Supp_Figure_S13_theta_testing_detection_all_variants"));
end

function plot_supp_s14_theta_scalar_outcomes_all_variants()
    vars = evalin("base", "SENSITIVITY_VARIANTS");
    r0s = evalin("base", "TARGET_R0_VALUES");
    thetas = evalin("base", "THETA_VALUES");
    suppDir = evalin("base", "SUPP_DIR");
    csvDir = evalin("base", "SUPP_CSV_DIR");

    scalarTable = build_theta_scalar_table_all_variants();
    scalarTable = add_ratio_of_means_effectiveness(scalarTable);

    writetable(scalarTable, fullfile(csvDir, "Supp_Figure_S14_theta_scalar_all_variants_values.csv"));

    metrics = [
        "final_cumulative_infections_mean"
        "infections_averted_mean"
        "cum_testing_cost_mean"
        "cum_pcr_tests_mean"
        "cum_ag_tests_mean"
        "detected_hidden_cases_mean"
        "detection_efficiency_mean"
        "infections_averted_per_1B_mean"
    ];

    labels = [
        "Final size"
        "Final-size reduction"
        "Testing cost"
        "Cumulative PCR tests"
        "Cumulative antigen tests"
        "Detected hidden cases"
        "Detection efficiency"
        "Final-size reduction per 1B cost"
    ];

    fig = figure("Color", "w", "Position", [40, 40, 1900, 1100]);
    tiledlayout(2, 4, "TileSpacing", "compact", "Padding", "compact");

    for mm = 1:numel(metrics)
        ax = nexttile(mm);
        metric = metrics(mm);

        [mat, colLabels] = theta_variant_r0_matrix(scalarTable, metric, thetas, vars, r0s);

        if metric == "cum_testing_cost_mean"
            mat = mat ./ 1e9;
        end

        if all(~isfinite(mat(:)))
            mark_missing_panel(ax, labels(mm));
        else
            hImg = imagesc(ax, mat);
            set(hImg, "AlphaData", isfinite(mat));
            set(ax, "Color", [0.96 0.96 0.96]);
            colormap(ax, make_pastel_autumn_cmap(128));
            colorbar(ax);
            xticks(ax, 1:numel(colLabels));
            xticklabels(ax, colLabels);
            xtickangle(ax, 45);
            yticks(ax, 1:numel(thetas));
            yticklabels(ax, arrayfun(@theta_label, thetas, "UniformOutput", false));
            xlabel(ax, "Variant and target R0");
            ylabel(ax, "\theta");
            add_heatmap_text(ax, mat, metric);
            add_variant_block_separators(ax, numel(r0s), numel(vars));
        end

        title(ax, labels(mm), "FontWeight", "normal");
        clean_heatmap_axis(ax);
    end

    sgtitle("Scalar-outcome sensitivity to testing-cost weight", ...
        "FontWeight", "normal");

    save_figure(fig, fullfile(suppDir, "Supp_Figure_S14_theta_scalar_outcomes_all_variants"));
end

%% =====================================================
% Supplementary tables
% ======================================================
function write_supplementary_tables()
    tableDir = evalin("base", "SUPP_TABLE_DIR");
    variants = evalin("base", "VARIANTS");
    sensVariants = evalin("base", "SENSITIVITY_VARIANTS");
    r0s = evalin("base", "TARGET_R0_VALUES");
    thetas = evalin("base", "THETA_VALUES");
    policies = evalin("base", "POLICIES");
    mainTheta = evalin("base", "MAIN_THETA");

    % Table S1. Sensitivity analysis conditions
    S1 = table();

    for vv = 1:numel(variants)
        for rr = 1:numel(r0s)
            for pp = 1:numel(policies)
                row = table();
                row.analysis = "Main evaluation";
                row.variant = variants(vv);
                row.R0 = r0s(rr);
                row.theta = mainTheta;
                row.policy = policies(pp);
                row.n_rollouts = 100;
                row.purpose = "Main policy comparison";
                S1 = [S1; row]; %#ok<AGROW>
            end
        end
    end

    for vv = 1:numel(sensVariants)
        for rr = 1:numel(r0s)
            for tt = 1:numel(thetas)
                row = table();
                row.analysis = "Theta sensitivity";
                row.variant = sensVariants(vv);
                row.R0 = r0s(rr);
                row.theta = thetas(tt);
                row.policy = "RL mixed";
                row.n_rollouts = 100;
                row.purpose = "Sensitivity to reward trade-off constant";
                S1 = [S1; row]; %#ok<AGROW>
            end
        end
    end

    writetable(S1, fullfile(tableDir, "Supplementary_Table_S1_sensitivity_conditions.csv"));

    % Table S2. Full scalar outcomes for main policy comparisons
    S2 = build_main_scalar_table();
    writetable(S2, fullfile(tableDir, "Supplementary_Table_S2_main_scalar_outcomes.csv"));

    % Table S3. Scalar outcomes for theta sensitivity
    S3 = table();
    for vv = 1:numel(sensVariants)
        tmp = build_theta_scalar_table_for_variant(sensVariants(vv));
        S3 = [S3; tmp]; %#ok<AGROW>
    end
    S3 = add_ratio_of_means_effectiveness(S3);
    writetable(S3, fullfile(tableDir, "Supplementary_Table_S3_theta_scalar_outcomes.csv"));

    % Table S4. Phase-averaged learned actions
    S4 = build_phase_averaged_action_table();
    writetable(S4, fullfile(tableDir, "Supplementary_Table_S4_phase_averaged_actions.csv"));
end

%% =====================================================
% Data loading
% ======================================================
function result = load_scenario(variant, r0, policy, theta, verbose)
    if nargin < 5
        verbose = false;
    end

    stateCols = evalin("base", "STATE_COLS");
    newIpCols = evalin("base", "NEW_IP_COLS");
    nTestCols = evalin("base", "N_TEST_COLS");
    testingStepCols = evalin("base", "TESTING_STEP_COLS");
    daysInStep = evalin("base", "DAYS_IN_STEP");

    [outDir, existsFlag] = build_result_dir(variant, r0, policy, theta);

    if ~existsFlag
        if verbose
            fprintf("[Missing] %s, R0=%.1f, policy=%s, theta=%s\n", ...
                variant, r0, policy, theta_to_string(theta));
        end
        result = [];
        return;
    end

    try
        stateArr = load_txt(outDir, "state_traj", variant, true);
        newIpArr = load_txt(outDir, "new_Ip", variant, true);
        nTestsArr = load_txt(outDir, "n_tests", variant, true);

        if isempty(stateArr) || isempty(newIpArr) || isempty(nTestsArr)
            result = [];
            return;
        end

        state = txt_to_table(stateArr, stateCols, 1);
        state = prepare_state_metrics(state);

        newIp = txt_to_table(newIpArr, newIpCols, 1);
        newIp = prepare_incidence_metrics(newIp);

        nTests = txt_to_table(nTestsArr, nTestCols, daysInStep);
        nTests = prepare_testing_cost_metrics(nTests);

        testingStep = [];
        testingStepArr = load_txt(outDir, "testing_step_summary", variant, false);

        if ~isempty(testingStepArr)
            testingStep = txt_to_table(testingStepArr, testingStepCols, daysInStep);
            testingStep = prepare_detection_metrics(testingStep);
        end

        actions = [];
        try
            actions = load_actions(outDir, variant);
        catch
            actions = [];
        end

        result = struct();
        result.variant = variant;
        result.R0 = r0;
        result.policy = policy;
        result.theta = theta;
        result.dir = outDir;
        result.state = state;
        result.new_ip = newIp;
        result.n_tests = nTests;
        result.testing_step = testingStep;
        result.actions = actions;

    catch ME
        if verbose
            fprintf("[Load failed] %s, R0=%.1f, policy=%s, theta=%s: %s\n", ...
                variant, r0, policy, theta_to_string(theta), ME.message);
        end
        result = [];
    end
end

function [outDir, existsFlag] = build_result_dir(variant, r0, policy, theta)
    resultRoot = evalin("base", "RESULT_ROOT");
    policyTags = evalin("base", "POLICY_TAGS");
    mainTheta = evalin("base", "MAIN_THETA");

    variantLower = variant_tag(variant);
    r0String = r0_tag(r0);
    policyTag = policyTags(char(policy));

    baseNoTheta = fullfile(resultRoot, ...
        sprintf("saved_rollout_%s_R0_%s_%s_100runs", ...
        variantLower, r0String, policyTag));

    candidates = strings(0);

    if policy == "RL mixed" && isfinite(theta)
        thetaTags = theta_tag_candidates(theta);
        thetaDirs = strings(0);

        for k = 1:numel(thetaTags)
            thetaDirs(end + 1) = fullfile(resultRoot, ...
                sprintf("saved_rollout_%s_R0_%s_%s_theta_%s_100runs", ...
                variantLower, r0String, policyTag, thetaTags(k))); %#ok<AGROW>
        end

        if abs(theta - mainTheta) < 1e-12
            candidates = [baseNoTheta, thetaDirs];
        else
            candidates = thetaDirs;
        end
    else
        candidates = baseNoTheta;
    end

    outDir = candidates(1);
    existsFlag = false;

    for i = 1:numel(candidates)
        if exist(candidates(i), "dir")
            outDir = candidates(i);
            existsFlag = true;
            return;
        end
    end
end

function arr = load_txt(outDir, prefix, variant, required)
    path = latest_file(outDir, prefix, variant);

    if strlength(path) == 0
        arr = [];
        return;
    end

    arr = readmatrix(path);

    if isvector(arr)
        arr = reshape(arr, 1, []);
    end
end

function path = latest_file(outDir, prefix, variant)
    pattern = fullfile(outDir, sprintf("%s_%s_*.txt", prefix, variant));
    files = dir(pattern);

    if isempty(files)
        path = "";
        return;
    end

    [~, idx] = max([files.datenum]);
    path = fullfile(files(idx).folder, files(idx).name);
end

function T = txt_to_table(arr, valueCols, daysInStep)
    expectedCols = 2 + numel(valueCols);

    if size(arr, 2) < expectedCols
        error("Expected at least %d columns, got %d", expectedCols, size(arr, 2));
    end

    arr = arr(:, 1:expectedCols);
    names = ["rollout", "time", valueCols];

    T = array2table(arr, "VariableNames", cellstr(names));
    T.rollout = round(T.rollout);
    T.time = round(T.time);
    T.day = T.time .* daysInStep;
end

%% =====================================================
% Metric preparation
% ======================================================
function T = prepare_state_metrics(T)
    T.hidden_EIpIa = T.E + T.Ip + T.Ia;
    T.hidden_IpIa = T.Ip + T.Ia;
    T.symptomatic_infectious = T.Is;
    T.isolated_total = T.Dqs + T.Dq;
end

function T = prepare_incidence_metrics(T)
    T = sortrows(T, ["rollout", "time"]);
    T.cum_infections = zeros(height(T), 1);
    rollouts = unique(T.rollout);

    for i = 1:numel(rollouts)
        idx = T.rollout == rollouts(i);
        T.cum_infections(idx) = cumsum(T.new_Ip(idx));
    end
end

function T = prepare_testing_cost_metrics(T)
    costPcr = evalin("base", "COST_PCR");
    costAg = evalin("base", "COST_AG");

    T = sortrows(T, ["rollout", "time"]);
    T.total_tests = T.n_pcr + T.n_ag;
    T.testing_cost = costPcr .* T.n_pcr + costAg .* T.n_ag;
    T.cum_testing_cost = zeros(height(T), 1);
    T.cum_pcr = zeros(height(T), 1);
    T.cum_ag = zeros(height(T), 1);

    rollouts = unique(T.rollout);

    for i = 1:numel(rollouts)
        idx = T.rollout == rollouts(i);
        T.cum_testing_cost(idx) = cumsum(T.testing_cost(idx));
        T.cum_pcr(idx) = cumsum(T.n_pcr(idx));
        T.cum_ag(idx) = cumsum(T.n_ag(idx));
    end

    T.pcr_fraction = T.n_pcr ./ max(T.total_tests, 1e-12);
end

function T = prepare_detection_metrics(T)
    T = sortrows(T, ["rollout", "time"]);
    T.detected_hidden = T.detected_E + T.detected_Ip + T.detected_Ia;
    T.detected_hidden_ag = T.detected_E_ag + T.detected_Ip_ag + T.detected_Ia_ag;
    T.detected_hidden_pcr = T.detected_hidden - T.detected_hidden_ag;
    T.cum_detected_hidden = zeros(height(T), 1);
    T.cum_detected_hidden_pcr = zeros(height(T), 1);
    T.cum_detected_hidden_ag = zeros(height(T), 1);

    rollouts = unique(T.rollout);

    for i = 1:numel(rollouts)
        idx = T.rollout == rollouts(i);
        T.cum_detected_hidden(idx) = cumsum(T.detected_hidden(idx));
        T.cum_detected_hidden_pcr(idx) = cumsum(T.detected_hidden_pcr(idx));
        T.cum_detected_hidden_ag(idx) = cumsum(T.detected_hidden_ag(idx));
    end
end

%% =====================================================
% Actions
% ======================================================
function actions = load_actions(outDir, variant)
    actionCols = evalin("base", "ACTION_DATA_COLS");
    daysInStep = evalin("base", "DAYS_IN_STEP");
    maxInterval = evalin("base", "MAX_TEST_INTERVAL");

    arrInterp = load_txt(outDir, "actions_interpreted", variant, false);

    if ~isempty(arrInterp)
        actions = txt_to_table(arrInterp, actionCols, daysInStep);
        return;
    end

    arrRaw = load_txt(outDir, "actions_raw", variant, true);

    if isempty(arrRaw)
        actions = [];
        return;
    end

    rollout = arrRaw(:, 1);
    time = arrRaw(:, 2);
    raw = arrRaw(:, 3:6);
    interp = convert_raw_action_to_interpreted(raw, maxInterval);
    arr = [rollout, time, interp];
    actions = txt_to_table(arr, actionCols, daysInStep);
end

function out = convert_raw_action_to_interpreted(actionsRaw, maxTestInterval)
    out = zeros(size(actionsRaw, 1), 4);
    out(:, 1) = min(max((actionsRaw(:, 1) + 1.0) ./ 2.0, 0.0), 1.0);
    out(:, 2) = min(max((actionsRaw(:, 2) + 1.0) ./ 2.0, 0.0), 1.0);
    out(:, 3) = maxTestInterval .* min(max((actionsRaw(:, 3) + 1.0) ./ 2.0, 0.0), 1.0);
    out(:, 4) = min(max((actionsRaw(:, 4) + 1.0) ./ 2.0, 0.0), 1.0);
end

%% =====================================================
% Scalar tables
% ======================================================
function scalarTable = build_main_scalar_table()
    vars = evalin("base", "VARIANTS");
    r0s = evalin("base", "TARGET_R0_VALUES");
    policies = evalin("base", "POLICIES");
    scalarTable = table();

    for vv = 1:numel(vars)
        variant = vars(vv);

        for rr = 1:numel(r0s)
            r0 = r0s(rr);
            baseline = load_scenario(variant, r0, "No testing", NaN, false);

            for pp = 1:numel(policies)
                policy = policies(pp);
                result = load_scenario(variant, r0, policy, NaN, false);
                row = scalar_row_from_result(result, baseline, variant, r0, policy, NaN);
                scalarTable = [scalarTable; row]; %#ok<AGROW>
            end
        end
    end
end

function scalarTable = build_theta_scalar_table_for_variant(variant)
    r0s = evalin("base", "TARGET_R0_VALUES");
    thetas = evalin("base", "THETA_VALUES");
    scalarTable = table();

    for rr = 1:numel(r0s)
        r0 = r0s(rr);
        baseline = load_scenario(variant, r0, "No testing", NaN, false);

        for tt = 1:numel(thetas)
            theta = thetas(tt);
            result = load_scenario(variant, r0, "RL mixed", theta, false);
            row = scalar_row_from_result(result, baseline, variant, r0, "RL mixed", theta);
            scalarTable = [scalarTable; row]; %#ok<AGROW>
        end
    end
end

function scalarTable = build_theta_scalar_table_all_variants()
    vars = evalin("base", "SENSITIVITY_VARIANTS");
    scalarTable = table();

    for vv = 1:numel(vars)
        tmp = build_theta_scalar_table_for_variant(vars(vv));
        scalarTable = [scalarTable; tmp]; %#ok<AGROW>
    end
end

function row = scalar_row_from_result(result, baseline, variant, r0, policy, theta)
    row = table();
    row.variant = variant;
    row.R0 = r0;
    row.policy = policy;
    row.theta = theta;
    row.available = ~isempty(result);

    metricNames = [
        "final_cumulative_infections"
        "peak_hidden"
        "hidden_burden"
        "symptomatic_burden"
        "cum_testing_cost"
        "cum_pcr_tests"
        "cum_ag_tests"
        "detected_hidden_cases"
        "detection_efficiency"
        "infections_averted"
        "infections_averted_per_1B"
        "hidden_burden_reduction"
        "peak_hidden_reduction"
        "symptomatic_burden_reduction"
        "hidden_burden_reduction_per_1B"
    ];

    for i = 1:numel(metricNames)
        row.(metricNames(i) + "_mean") = NaN;
        row.(metricNames(i) + "_low") = NaN;
        row.(metricNames(i) + "_high") = NaN;
        row.(metricNames(i) + "_n") = 0;
    end

    if isempty(result)
        return;
    end

    finalInf = final_by_rollout(result.new_ip, "cum_infections");
    peakHidden = max_by_rollout(result.state, "hidden_IpIa", "peak_hidden");
    hiddenBurden = sum_by_rollout(result.state, "hidden_EIpIa", "hidden_burden");
    symptomaticBurden = sum_by_rollout(result.state, "symptomatic_infectious", "symptomatic_burden");
    finalCost = final_by_rollout(result.n_tests, "cum_testing_cost");
    finalPcr = final_by_rollout(result.n_tests, "cum_pcr");
    finalAg = final_by_rollout(result.n_tests, "cum_ag");

    detectedVals = nan(height(finalInf), 1);
    if ~isempty(result.testing_step)
        det = final_by_rollout(result.testing_step, "cum_detected_hidden");
        [~, ia, ib] = intersect(finalInf.rollout, det.rollout);
        detectedVals(ia) = det.cum_detected_hidden(ib);
    end

    totalTestsVals = finalPcr.cum_pcr + finalAg.cum_ag;
    detectionEffVals = detectedVals ./ max(totalTestsVals, 1e-12);

    baselineFinal = [];
    baselineHiddenBurden = [];
    baselinePeakHidden = [];
    baselineSymptomaticBurden = [];

    if ~isempty(baseline)
        baselineFinal = final_by_rollout(baseline.new_ip, "cum_infections");
        baselineHiddenBurden = sum_by_rollout(baseline.state, "hidden_EIpIa", "hidden_burden");
        baselinePeakHidden = max_by_rollout(baseline.state, "hidden_IpIa", "peak_hidden");
        baselineSymptomaticBurden = sum_by_rollout(baseline.state, "symptomatic_infectious", "symptomatic_burden");
    end

    infectionsAvertedVals = matched_difference(baselineFinal, "cum_infections", finalInf, "cum_infections");
    hiddenReductionVals = matched_difference(baselineHiddenBurden, "hidden_burden", hiddenBurden, "hidden_burden");
    peakHiddenReductionVals = matched_difference(baselinePeakHidden, "peak_hidden", peakHidden, "peak_hidden");
    symptomaticReductionVals = matched_difference(baselineSymptomaticBurden, "symptomatic_burden", symptomaticBurden, "symptomatic_burden");

    infPer1B = infectionsAvertedVals ./ max(finalCost.cum_testing_cost, 1e-12) .* 1e9;
    hiddenPer1B = hiddenReductionVals ./ max(finalCost.cum_testing_cost, 1e-12) .* 1e9;

    row = fill_metric_summary(row, "final_cumulative_infections", finalInf.cum_infections);
    row = fill_metric_summary(row, "peak_hidden", peakHidden.peak_hidden);
    row = fill_metric_summary(row, "hidden_burden", hiddenBurden.hidden_burden);
    row = fill_metric_summary(row, "symptomatic_burden", symptomaticBurden.symptomatic_burden);
    row = fill_metric_summary(row, "cum_testing_cost", finalCost.cum_testing_cost);
    row = fill_metric_summary(row, "cum_pcr_tests", finalPcr.cum_pcr);
    row = fill_metric_summary(row, "cum_ag_tests", finalAg.cum_ag);
    row = fill_metric_summary(row, "detected_hidden_cases", detectedVals);
    row = fill_metric_summary(row, "detection_efficiency", detectionEffVals);
    row = fill_metric_summary(row, "infections_averted", infectionsAvertedVals);
    row = fill_metric_summary(row, "infections_averted_per_1B", infPer1B);
    row = fill_metric_summary(row, "hidden_burden_reduction", hiddenReductionVals);
    row = fill_metric_summary(row, "peak_hidden_reduction", peakHiddenReductionVals);
    row = fill_metric_summary(row, "symptomatic_burden_reduction", symptomaticReductionVals);
    row = fill_metric_summary(row, "hidden_burden_reduction_per_1B", hiddenPer1B);
end

function T = add_ratio_of_means_effectiveness(T)
    if height(T) == 0
        return;
    end

    minCost = evalin("base", "MIN_COST_FOR_COST_EFFECTIVENESS");

    if ismember("infections_averted_mean", string(T.Properties.VariableNames)) && ...
       ismember("cum_testing_cost_mean", string(T.Properties.VariableNames))

        T.infections_averted_per_1B_mean = nan(height(T), 1);

        valid = isfinite(T.infections_averted_mean) & ...
                isfinite(T.cum_testing_cost_mean) & ...
                T.cum_testing_cost_mean >= minCost;

        T.infections_averted_per_1B_mean(valid) = ...
            T.infections_averted_mean(valid) ./ T.cum_testing_cost_mean(valid) .* 1e9;
    end

    if ismember("hidden_burden_reduction_mean", string(T.Properties.VariableNames)) && ...
       ismember("cum_testing_cost_mean", string(T.Properties.VariableNames))

        T.hidden_burden_reduction_per_1B_mean = nan(height(T), 1);

        valid = isfinite(T.hidden_burden_reduction_mean) & ...
                isfinite(T.cum_testing_cost_mean) & ...
                T.cum_testing_cost_mean >= minCost;

        T.hidden_burden_reduction_per_1B_mean(valid) = ...
            T.hidden_burden_reduction_mean(valid) ./ T.cum_testing_cost_mean(valid) .* 1e9;
    end
end
function row = fill_metric_summary(row, metricName, vals)
    [m, lo, hi, n] = t_based_mean_ci_n(vals);
    row.(metricName + "_mean") = m;
    row.(metricName + "_low") = lo;
    row.(metricName + "_high") = hi;
    row.(metricName + "_n") = n;
end

function vals = matched_difference(baseT, baseCol, compT, compCol)
    if isempty(compT)
        vals = NaN;
        return;
    end

    if isempty(baseT)
        vals = nan(height(compT), 1);
        return;
    end

    vals = nan(height(compT), 1);
    [~, ia, ib] = intersect(compT.rollout, baseT.rollout);
    vals(ia) = baseT.(baseCol)(ib) - compT.(compCol)(ia);

    missing = isnan(vals);
    if any(missing)
        vals(missing) = mean(baseT.(baseCol), "omitnan") - compT.(compCol)(missing);
    end
end

function Tsum = sum_by_rollout(T, valueCol, outCol)
    rollouts = unique(T.rollout);
    Tsum = table();
    Tsum.rollout = rollouts;
    Tsum.(outCol) = nan(numel(rollouts), 1);

    for i = 1:numel(rollouts)
        idx = T.rollout == rollouts(i);
        Tsum.(outCol)(i) = sum(T.(valueCol)(idx), "omitnan");
    end
end

function Tmax = max_by_rollout(T, valueCol, outCol)
    rollouts = unique(T.rollout);
    Tmax = table();
    Tmax.rollout = rollouts;
    Tmax.(outCol) = nan(numel(rollouts), 1);

    for i = 1:numel(rollouts)
        idx = T.rollout == rollouts(i);
        vals = T.(valueCol)(idx);
        vals = vals(isfinite(vals));
        if isempty(vals)
            Tmax.(outCol)(i) = NaN;
        else
            Tmax.(outCol)(i) = max(vals);
        end
    end
end

function mat = theta_heatmap_matrix(T, metric, thetas, r0s)
    mat = nan(numel(thetas), numel(r0s));
    if ~ismember(metric, string(T.Properties.VariableNames))
        return;
    end

    for tt = 1:numel(thetas)
        for rr = 1:numel(r0s)
            idx = T.theta == thetas(tt) & abs(T.R0 - r0s(rr)) < 1e-12;
            if any(idx)
                mat(tt, rr) = T.(metric)(find(idx, 1, "first"));
            end
        end
    end
end

function [mat, colLabels] = theta_variant_r0_matrix(T, metric, thetas, vars, r0s)
    nCols = numel(vars) * numel(r0s);
    mat = nan(numel(thetas), nCols);
    colLabels = strings(1, nCols);

    if ~ismember(metric, string(T.Properties.VariableNames))
        return;
    end

    col = 0;

    for vv = 1:numel(vars)
        variant = vars(vv);

        for rr = 1:numel(r0s)
            r0 = r0s(rr);
            col = col + 1;
            colLabels(col) = sprintf("%s %.1f", short_variant_label(variant), r0);

            for tt = 1:numel(thetas)
                theta = thetas(tt);
                idx = T.variant == variant & T.theta == theta & abs(T.R0 - r0) < 1e-12;

                if any(idx)
                    mat(tt, col) = T.(metric)(find(idx, 1, "first"));
                end
            end
        end
    end
end

function S4 = build_phase_averaged_action_table()
    sensVariants = evalin("base", "SENSITIVITY_VARIANTS");
    r0s = evalin("base", "TARGET_R0_VALUES");
    thetas = evalin("base", "THETA_VALUES");
    actionCols = evalin("base", "ACTION_PLOT_COLS");

    phaseNames = ["Early", "Middle", "Late"];
    phaseStarts = [0, 50, 100];
    phaseEnds = [50, 100, inf];
    S4 = table();

    for vv = 1:numel(sensVariants)
        variant = sensVariants(vv);

        for rr = 1:numel(r0s)
            r0 = r0s(rr);

            for tt = 1:numel(thetas)
                theta = thetas(tt);
                result = load_scenario(variant, r0, "RL mixed", theta, false);

                for pp = 1:numel(phaseNames)
                    row = table();
                    row.variant = variant;
                    row.R0 = r0;
                    row.theta = theta;
                    row.phase = phaseNames(pp);
                    row.available = ~isempty(result) && ~isempty(result.actions);

                    for aa = 1:numel(actionCols)
                        col = actionCols(aa);
                        row.(col + "_mean") = NaN;
                        row.(col + "_low") = NaN;
                        row.(col + "_high") = NaN;
                    end

                    if ~isempty(result) && ~isempty(result.actions)
                        idx = result.actions.day >= phaseStarts(pp) & result.actions.day < phaseEnds(pp);

                        for aa = 1:numel(actionCols)
                            col = actionCols(aa);
                            [m, lo, hi] = t_based_mean_ci(result.actions.(col)(idx));
                            row.(col + "_mean") = m;
                            row.(col + "_low") = lo;
                            row.(col + "_high") = hi;
                        end
                    end

                    S4 = [S4; row]; %#ok<AGROW>
                end
            end
        end
    end
end

%% =====================================================
% Testing/detection summaries
% ======================================================
function [barTests, barDetections, pcrShareParts, effParts] = extract_testing_detection_summary(result)
    variant = result.variant;
    r0 = result.R0;
    nTests = result.n_tests;
    testingStep = result.testing_step;

    barTests = table();
    barDetections = table();
    pcrShareParts = table();
    effParts = table();

    finalPcr = final_by_rollout(nTests, "cum_pcr");
    finalAg  = final_by_rollout(nTests, "cum_ag");

    row = summarize_assay_bar_row(variant, r0, "PCR", finalPcr.cum_pcr);
    barTests = [barTests; row]; %#ok<AGROW>
    row = summarize_assay_bar_row(variant, r0, "Antigen", finalAg.cum_ag);
    barTests = [barTests; row]; %#ok<AGROW>

    if ~isempty(testingStep)
        finalDetPcr = final_by_rollout(testingStep, "cum_detected_hidden_pcr");
        finalDetAg  = final_by_rollout(testingStep, "cum_detected_hidden_ag");

        row = summarize_assay_bar_row(variant, r0, "PCR", finalDetPcr.cum_detected_hidden_pcr);
        barDetections = [barDetections; row]; %#ok<AGROW>
        row = summarize_assay_bar_row(variant, r0, "Antigen", finalDetAg.cum_detected_hidden_ag);
        barDetections = [barDetections; row]; %#ok<AGROW>
    end

    tmpRatio = nTests;
    tmpRatio.total_tests = tmpRatio.n_pcr + tmpRatio.n_ag;
    tmpRatio.pcr_testing_ratio = tmpRatio.n_pcr ./ max(tmpRatio.total_tests, 1e-12);
    tmpRatio.antigen_testing_ratio = tmpRatio.n_ag ./ max(tmpRatio.total_tests, 1e-12);

    sPcrRatio = summarize_by_time_tci(tmpRatio, "pcr_testing_ratio", "day");
    sPcrRatio.variant = repmat(variant, height(sPcrRatio), 1);
    sPcrRatio.R0 = repmat(r0, height(sPcrRatio), 1);
    sPcrRatio.modality = repmat("PCR", height(sPcrRatio), 1);
    sPcrRatio.metric = repmat("pcr_testing_ratio", height(sPcrRatio), 1);

    sAgRatio = summarize_by_time_tci(tmpRatio, "antigen_testing_ratio", "day");
    sAgRatio.variant = repmat(variant, height(sAgRatio), 1);
    sAgRatio.R0 = repmat(r0, height(sAgRatio), 1);
    sAgRatio.modality = repmat("Antigen", height(sAgRatio), 1);
    sAgRatio.metric = repmat("antigen_testing_ratio", height(sAgRatio), 1);

    pcrShareParts = [pcrShareParts; sPcrRatio; sAgRatio]; %#ok<AGROW>

    if ~isempty(testingStep)
        eff = testingStep;
        totalTestsByStep = nTests(:, ["rollout", "time", "day", "n_pcr", "n_ag"]);
        totalTestsByStep.actual_total_tests = totalTestsByStep.n_pcr + totalTestsByStep.n_ag;

        eff = outerjoin(eff, totalTestsByStep(:, ["rollout", "time", "actual_total_tests"]), ...
            "Keys", ["rollout", "time"], ...
            "MergeKeys", true, ...
            "Type", "left");

        eff.detected_per_test = eff.detected_hidden ./ max(eff.actual_total_tests, 1e-12);
        sEff = summarize_by_time_tci(eff, "detected_per_test", "day");
        sEff.variant = repmat(variant, height(sEff), 1);
        sEff.R0 = repmat(r0, height(sEff), 1);
        effParts = [effParts; sEff]; %#ok<AGROW>
    end
end

function row = summarize_assay_bar_row(variant, r0, assay, values)
    [m, lo, hi, n] = t_based_mean_ci_n(values);
    row = table();
    row.variant = variant;
    row.R0 = r0;
    row.assay = assay;
    row.mean = m;
    row.low = lo;
    row.high = hi;
    row.n = n;
end

%% =====================================================
% Plot helpers
% ======================================================
function [summary, h] = plot_mean_tci_color(ax, T, valueCol, labelText, xCol, color, lineWidth, showCI)
    [summary, h] = plot_mean_tci_color_style(ax, T, valueCol, labelText, xCol, ...
        color, lineWidth, showCI, "-");
end

function [summary, h] = plot_mean_tci_color_style(ax, T, valueCol, labelText, xCol, color, lineWidth, showCI, lineStyle)
    fillAlpha = evalin("base", "FILL_ALPHA");
    summary = summarize_by_time_tci(T, valueCol, xCol);
    x = summary.(xCol);
    y = summary.mean;
    lo = summary.low;
    hi = summary.high;

    if showCI
        fill(ax, [x; flipud(x)], [lo; flipud(hi)], color, ...
            "FaceAlpha", fillAlpha, ...
            "EdgeColor", "none", ...
            "HandleVisibility", "off");
    end

    h = plot(ax, x, y, ...
        "Color", color, ...
        "LineWidth", lineWidth, ...
        "LineStyle", lineStyle, ...
        "DisplayName", labelText);
end

function h = plot_summary_ci(ax, summary, labelText, color, lineWidth, showCI, lineStyle)
    if nargin < 7
        lineStyle = "-";
    end

    fillAlpha = evalin("base", "FILL_ALPHA");
    x = summary.day;
    y = summary.mean;
    lo = summary.low;
    hi = summary.high;

    if showCI
        fill(ax, [x; flipud(x)], [lo; flipud(hi)], color, ...
            "FaceAlpha", fillAlpha, ...
            "EdgeColor", "none", ...
            "HandleVisibility", "off");
    end

    h = plot(ax, x, y, ...
        "Color", color, ...
        "LineWidth", lineWidth, ...
        "LineStyle", lineStyle, ...
        "DisplayName", labelText);
end

function plot_policy_final_bar(ax, T, policies)
    x = 1:numel(policies);
    means = nan(numel(policies), 1);
    lows = nan(numel(policies), 1);
    highs = nan(numel(policies), 1);

    for i = 1:numel(policies)
        policy = policies(i);
        idx = T.policy == policy;
        if any(idx)
            row = T(idx, :);
            means(i) = row.mean(1);
            lows(i) = row.low(1);
            highs(i) = row.high(1);
        end
    end

    b = bar(ax, x, means, 0.68, ...
        "FaceColor", "flat", ...
        "EdgeColor", [0.25 0.25 0.25], ...
        "LineWidth", 0.6);

    for i = 1:numel(policies)
        b.CData(i, :) = get_policy_color(policies(i));
    end

    lowerErr = means - lows;
    upperErr = highs - means;
    lowerErr(~isfinite(lowerErr)) = 0;
    upperErr(~isfinite(upperErr)) = 0;

    errorbar(ax, x, means, lowerErr, upperErr, ...
        "Color", [0.20 0.20 0.20], ...
        "LineStyle", "none", ...
        "LineWidth", 0.8, ...
        "CapSize", 5);

    xticks(ax, x);
    xticklabels(ax, arrayfun(@policy_short_label, policies, "UniformOutput", false));
    xtickangle(ax, 25);
end

function plot_grouped_assay_bars(ax, T, yLabelText)
    vars = evalin("base", "VARIANTS");
    assays = ["PCR", "Antigen"];
    offsets = [-0.18, 0.18];
    barWidth = 0.32;
    hold(ax, "on");
    positiveValues = [];

    for i = 1:numel(vars)
        variant = vars(i);
        for a = 1:numel(assays)
            assay = assays(a);
            idx = T.variant == variant & T.assay == assay;
            if ~any(idx); continue; end
            row = T(idx, :);
            meanVal = row.mean(1);
            lowVal = row.low(1);
            highVal = row.high(1);

            if ~isfinite(meanVal) || meanVal <= 0
                continue;
            end

            positiveValues = [positiveValues; meanVal]; %#ok<AGROW>
            color = get_assay_color(variant, assay);
            edgeColor = darken(color, 0.25);
            x = i + offsets(a);
            bar(ax, x, meanVal, barWidth, ...
                "FaceColor", color, ...
                "EdgeColor", edgeColor, ...
                "LineWidth", 0.7);

            plotLow = max(lowVal, max(meanVal * 0.05, 1e-9));
            lowerErr = max(0, meanVal - plotLow);
            upperErr = max(0, highVal - meanVal);
            errorbar(ax, x, meanVal, lowerErr, upperErr, ...
                "Color", [0.25 0.25 0.25], ...
                "LineStyle", "none", ...
                "LineWidth", 0.8, ...
                "CapSize", 5);
        end
    end

    xticks(ax, 1:numel(vars));
    xticklabels(ax, cellstr(vars));
    xtickangle(ax, 0);
    ylabel(ax, yLabelText);

    if ~isempty(positiveValues)
        ymin = max(min(positiveValues) * 0.45, 1e-3);
        ymax = max(positiveValues) * 2.2;
        if ymax <= ymin; ymax = ymin * 10; end
        ylim(ax, [ymin, ymax]);
    end

    dummyPCR = bar(ax, nan, nan, "FaceColor", [0.55 0.55 0.55], ...
        "EdgeColor", [0.25 0.25 0.25], "LineWidth", 0.7);
    dummyAg = bar(ax, nan, nan, "FaceColor", [0.85 0.85 0.85], ...
        "EdgeColor", [0.45 0.45 0.45], "LineWidth", 0.7);
    legend(ax, [dummyPCR, dummyAg], ["PCR", "Antigen"], ...
        "Location", "northwest", "Box", "off", "FontSize", 8);
end

function plot_theta_bar(ax, T, thetas, yLabelText)
    x = 1:numel(thetas);
    means = nan(numel(thetas), 1);
    lows = nan(numel(thetas), 1);
    highs = nan(numel(thetas), 1);

    for i = 1:numel(thetas)
        idx = T.theta == thetas(i);
        if any(idx)
            row = T(idx, :);
            means(i) = row.mean(1);
            lows(i) = row.low(1);
            highs(i) = row.high(1);
        end
    end

    b = bar(ax, x, means, 0.68, ...
        "FaceColor", "flat", ...
        "EdgeColor", [0.25 0.25 0.25], ...
        "LineWidth", 0.6);

    for i = 1:numel(thetas)
        b.CData(i, :) = get_theta_color(thetas(i), i, numel(thetas));
    end

    lowerErr = means - lows;
    upperErr = highs - means;
    lowerErr(~isfinite(lowerErr)) = 0;
    upperErr(~isfinite(upperErr)) = 0;

    errorbar(ax, x, means, lowerErr, upperErr, ...
        "Color", [0.20 0.20 0.20], ...
        "LineStyle", "none", ...
        "LineWidth", 0.8, ...
        "CapSize", 5);

    xticks(ax, x);
    xticklabels(ax, arrayfun(@theta_label, thetas, "UniformOutput", false));
    xtickangle(ax, 25);
    ylabel(ax, yLabelText);
end

function plot_theta_assay_bars(ax, T, thetas, yLabelText)
    assays = ["PCR", "Antigen"];
    offsets = [-0.17, 0.17];
    barWidth = 0.30;

    hold(ax, "on");

    if height(T) == 0 || ~ismember("mean", string(T.Properties.VariableNames))
        displayFloor = 1e-3;
        yMin = 5e-4;
        yMax = 1;
    else
        finitePositive = T.mean(isfinite(T.mean) & T.mean > 0);

        if isempty(finitePositive)
            displayFloor = 1e-3;
            yMin = 5e-4;
            yMax = 1;
        else
            displayFloor = max(min(finitePositive) * 0.03, 1e-3);
            yMin = displayFloor * 0.45;
            yMax = max(finitePositive) * 2.2;
            if yMax <= yMin
                yMax = yMin * 10;
            end
        end
    end

    for tt = 1:numel(thetas)
        theta = thetas(tt);

        for aa = 1:numel(assays)
            assay = assays(aa);

            idx = T.theta == theta & T.assay == assay;
            if ~any(idx)
                continue;
            end

            row = T(idx, :);
            meanVal = row.mean(1);
            lowVal = row.low(1);
            highVal = row.high(1);

            if ~isfinite(meanVal)
                continue;
            end

            base = get_theta_color(theta, tt, numel(thetas));

            if assay == "PCR"
                color = darken(base, 0.10);
            else
                color = lighten(base, 0.45);
            end

            x = tt + offsets(aa);

            if meanVal > 0
                bar(ax, x, meanVal, barWidth, ...
                    "FaceColor", color, ...
                    "EdgeColor", darken(color, 0.25), ...
                    "LineWidth", 0.7);

                plotLow = max(lowVal, max(meanVal * 0.05, displayFloor));
                lowerErr = max(0, meanVal - plotLow);
                upperErr = max(0, highVal - meanVal);

                errorbar(ax, x, meanVal, lowerErr, upperErr, ...
                    "Color", [0.25 0.25 0.25], ...
                    "LineStyle", "none", ...
                    "LineWidth", 0.7, ...
                    "CapSize", 4);
            else
                % Zero values cannot be drawn as bars on a log-scale axis.
                % Draw a small baseline marker and label it as zero.
                plot(ax, [x - barWidth/2, x + barWidth/2], ...
                    [displayFloor, displayFloor], ...
                    "Color", darken(color, 0.35), ...
                    "LineWidth", 1.2, ...
                    "HandleVisibility", "off");

                text(ax, x, displayFloor * 1.25, "0", ...
                    "HorizontalAlignment", "center", ...
                    "VerticalAlignment", "bottom", ...
                    "FontSize", 6.5, ...
                    "Color", [0.25 0.25 0.25], ...
                    "HandleVisibility", "off");
            end
        end
    end

    xticks(ax, 1:numel(thetas));
    xticklabels(ax, arrayfun(@theta_label, thetas, "UniformOutput", false));
    xtickangle(ax, 25);
    ylabel(ax, yLabelText);

    ylim(ax, [yMin, yMax]);
end
function add_heatmap_text(ax, mat, metric)
    for ii = 1:size(mat, 1)
        for jj = 1:size(mat, 2)
            value = mat(ii, jj);
            if ~isfinite(value); continue; end
            text(ax, jj, ii, format_heatmap_value(value, metric), ...
                "HorizontalAlignment", "center", ...
                "VerticalAlignment", "middle", ...
                "FontSize", 7.5, ...
                "Color", [0.12 0.12 0.12]);
        end
    end
end

function mark_missing_panel(ax, titleText)
    cla(ax);
    axis(ax, "off");
    text(ax, 0.5, 0.55, "Not available", ...
        "Units", "normalized", ...
        "HorizontalAlignment", "center", ...
        "VerticalAlignment", "middle", ...
        "FontSize", 11, ...
        "Color", [0.45 0.45 0.45], ...
        "FontWeight", "bold");
    text(ax, 0.5, 0.40, titleText, ...
        "Units", "normalized", ...
        "HorizontalAlignment", "center", ...
        "VerticalAlignment", "middle", ...
        "FontSize", 8, ...
        "Color", [0.55 0.55 0.55]);
end

%% =====================================================
% CI and summary helpers
% ======================================================
function [meanVal, lowVal, highVal] = t_based_mean_ci(vals)
    [meanVal, lowVal, highVal, ~] = t_based_mean_ci_n(vals);
end

function [meanVal, lowVal, highVal, n] = t_based_mean_ci_n(vals)
    vals = double(vals(:));
    vals = vals(isfinite(vals));
    n = numel(vals);

    if n == 0
        meanVal = NaN;
        lowVal = NaN;
        highVal = NaN;
        return;
    end

    meanVal = mean(vals, "omitnan");

    if n <= 1
        lowVal = meanVal;
        highVal = meanVal;
        return;
    end

    stdVal = std(vals, 0, "omitnan");
    semVal = stdVal / sqrt(n);
    ciAlpha = evalin("base", "CI_ALPHA");
    ci = tinv([ciAlpha / 2.0, 1.0 - ciAlpha / 2.0], n - 1);
    lowVal = meanVal + ci(1) * semVal;
    highVal = meanVal + ci(2) * semVal;
end

function summary = summarize_by_time_tci(T, valueCol, xCol)
    xVals = unique(T.(xCol));
    xVals = sort(xVals);
    summary = table();
    summary.(xCol) = xVals;
    summary.mean = nan(numel(xVals), 1);
    summary.low = nan(numel(xVals), 1);
    summary.high = nan(numel(xVals), 1);
    summary.n = nan(numel(xVals), 1);

    for i = 1:numel(xVals)
        idx = T.(xCol) == xVals(i);
        vals = T.(valueCol)(idx);
        [m, lo, hi, n] = t_based_mean_ci_n(vals);
        summary.mean(i) = m;
        summary.low(i) = lo;
        summary.high(i) = hi;
        summary.n(i) = n;
    end
end

function Tfinal = final_by_rollout(T, valueCol)
    rollouts = unique(T.rollout);
    Tfinal = table();
    Tfinal.rollout = rollouts;
    Tfinal.(valueCol) = nan(numel(rollouts), 1);

    for i = 1:numel(rollouts)
        idx = find(T.rollout == rollouts(i));
        [~, j] = max(T.time(idx));
        rowIdx = idx(j);
        Tfinal.(valueCol)(i) = T.(valueCol)(rowIdx);
    end
end

function T = add_plot_metadata(T, figName, variant, r0, policy, metric)
    T.figure = repmat(figName, height(T), 1);
    T.variant = repmat(variant, height(T), 1);
    T.R0 = repmat(r0, height(T), 1);
    T.policy = repmat(policy, height(T), 1);
    T.metric = repmat(metric, height(T), 1);
end

function row = summarize_policy_bar_row(variant, r0, policy, metricName, values)
    [m, lo, hi, n] = t_based_mean_ci_n(values);
    row = table();
    row.figure = "Supplementary";
    row.variant = variant;
    row.R0 = r0;
    row.policy = policy;
    row.metric = metricName;
    row.mean = m;
    row.low = lo;
    row.high = hi;
    row.n = n;
end

function row = summarize_theta_bar_row(variant, r0, theta, metricName, values)
    [m, lo, hi, n] = t_based_mean_ci_n(values);
    row = table();
    row.figure = "Supplementary";
    row.variant = variant;
    row.R0 = r0;
    row.theta = theta;
    row.metric = metricName;
    row.mean = m;
    row.low = lo;
    row.high = hi;
    row.n = n;
    row.available = true;
end

function row = missing_theta_bar_row(variant, r0, theta, metricName)
    row = table();
    row.figure = "Supplementary";
    row.variant = variant;
    row.R0 = r0;
    row.theta = theta;
    row.metric = metricName;
    row.mean = NaN;
    row.low = NaN;
    row.high = NaN;
    row.n = 0;
    row.available = false;
end

function T = missing_theta_assay_rows(variant, r0, theta, metricName)
    assays = ["PCR", "Antigen"];
    T = table();
    for i = 1:numel(assays)
        row = table();
        row.variant = variant;
        row.R0 = r0;
        row.assay = assays(i);
        row.mean = NaN;
        row.low = NaN;
        row.high = NaN;
        row.n = 0;
        row.theta = theta;
        row.metric = metricName;
        T = [T; row]; %#ok<AGROW>
    end
end

%% =====================================================
% Detectability helper
% ======================================================
function [t, V, Vnorm, pcr, ag, peakTime] = simulate_detectability_profile(variant)
    tEnd = evalin("base", "DETECT_T_END");
    dt = evalin("base", "DETECT_DT");
    epsVal = evalin("base", "DETECT_EPS");
    params = within_host_params(variant);

    t = (0:dt:tEnd)';
    f = zeros(size(t));
    V = zeros(size(t));
    f(1) = 1.0;
    V(1) = params.V0;

    for k = 1:(numel(t) - 1)
        y = [f(k); V(k)];
        h = dt;
        k1 = within_host_rhs(y, params);
        k2 = within_host_rhs(y + 0.5 * h * k1, params);
        k3 = within_host_rhs(y + 0.5 * h * k2, params);
        k4 = within_host_rhs(y + h * k3, params);
        yNext = y + h / 6.0 * (k1 + 2*k2 + 2*k3 + k4);
        f(k + 1) = max(yNext(1), 0);
        V(k + 1) = max(yNext(2), epsVal);
    end

    Vmax = max(V);
    Vnorm = V ./ max(Vmax, epsVal);
    [~, idxMax] = max(Vnorm);
    peakTime = t(idxMax);
    pcr = viral_load_to_detectability(Vnorm, "PCR");
    ag  = viral_load_to_detectability(Vnorm, "Antigen");
end

function dy = within_host_rhs(y, p)
    f = y(1);
    V = y(2);
    df = -p.b * f * V;
    dV = p.gamma * f * V - p.delta * V;
    dy = [df; dV];
end

function p = within_host_params(variant)
    variant = string(variant);
    switch variant
        case "Alpha"
            p.b = 1.78e-07;
            p.gamma = 2.53;
            p.delta = 1.52;
            p.V0 = 46.83;
        case "Delta"
            p.b = 1.57e-05;
            p.gamma = 1.46;
            p.delta = 0.88;
            p.V0 = 123.90;
        case "Omicron"
            p.b = 2.41e-07;
            p.gamma = 9.05;
            p.delta = 8.02;
            p.V0 = 628.01;
        otherwise
            error("Unknown variant: %s", variant);
    end
end

function prob = viral_load_to_detectability(Vnorm, assay)
    assay = string(assay);
    if assay == "PCR"
        maxSens = evalin("base", "PCR_MAX_SENS");
        threshold = evalin("base", "PCR_THRESHOLD_NORM");
        steepness = evalin("base", "PCR_STEEPNESS");
    else
        maxSens = evalin("base", "AG_MAX_SENS");
        threshold = evalin("base", "AG_THRESHOLD_NORM");
        steepness = evalin("base", "AG_STEEPNESS");
    end
    x = log10(max(Vnorm, 1e-12));
    x0 = log10(threshold);
    prob = maxSens ./ (1.0 + exp(-steepness .* (x - x0)));
    prob = min(max(prob, 0), 1);
end

%% =====================================================
% Color and style helpers
% ======================================================
function c = get_variant_color(variant, shade)
    variant = string(variant);
    switch variant
        case "Alpha"
            base = [0.42, 0.62, 0.84];
        case "Delta"
            base = [0.88, 0.48, 0.45];
        case "Omicron"
            base = [0.93, 0.76, 0.30];
        otherwise
            base = [0.65, 0.65, 0.65];
    end
    if shade > 0
        c = lighten(base, shade);
    elseif shade < 0
        c = darken(base, abs(shade));
    else
        c = base;
    end
end

function c = get_theta_color(theta, idx, nTheta)
    palette = [
        0.42, 0.62, 0.84
        0.88, 0.48, 0.45
        0.93, 0.76, 0.30
        0.68, 0.55, 0.80
        0.55, 0.72, 0.50
        0.50, 0.50, 0.50
        0.40, 0.70, 0.74
        0.82, 0.58, 0.38
    ];
    if idx <= size(palette, 1)
        c = palette(idx, :);
    else
        a = (idx - 1) / max(nTheta - 1, 1);
        c = [0.35 + 0.45*a, 0.55 - 0.20*a, 0.75 - 0.35*a];
        c = min(max(c, 0), 1);
    end
end

function ls = get_theta_line_style(idx)
    styles = ["-", "--", "-.", ":", "-", "--"];
    ls = styles(mod(idx - 1, numel(styles)) + 1);
end

function marker = get_r0_marker(r0)
    if abs(r0 - 2.5) < 1e-12
        marker = "o";
    elseif abs(r0 - 3.5) < 1e-12
        marker = "s";
    else
        marker = "^";
    end
end

function c = get_assay_color(variant, assay)
    base = get_variant_color(variant, 0);
    assay = string(assay);
    switch assay
        case "PCR"
            c = darken(base, 0.12);
        case "Antigen"
            c = lighten(base, 0.48);
        otherwise
            c = base;
    end
end

function c = get_policy_color(policy)
    policy = string(policy);
    switch policy
        case "RL mixed"
            c = [0.42, 0.62, 0.84];
        case "PCR only"
            c = [0.88, 0.48, 0.45];
        case "Ag only"
            c = [0.93, 0.76, 0.30];
        case "Half PCR/Ag"
            c = [0.68, 0.55, 0.80];
        case "No testing"
            c = [0.55, 0.72, 0.50];
        otherwise
            c = [0.55, 0.55, 0.55];
    end
end

function marker = get_policy_marker(policy)
    markers = evalin("base", "POLICY_MARKERS");
    marker = markers(char(policy));
end

function c = lighten(c, amount)
    c = c + (1 - c) .* amount;
    c = min(max(c, 0), 1);
end

function c = darken(c, amount)
    c = c .* (1 - amount);
    c = min(max(c, 0), 1);
end

function cmap = make_pastel_cmap(baseColor, n)
    low = lighten(baseColor, 0.82);
    high = darken(baseColor, 0.10);
    cmap = zeros(n, 3);
    for i = 1:n
        a = (i - 1) / max(n - 1, 1);
        cmap(i, :) = (1 - a) .* low + a .* high;
    end
end


function c = get_variant_r0_color(variant, r0)
    base = get_variant_color(variant, 0);
    if abs(r0 - 2.5) < 1e-12
        c = lighten(base, 0.38);
    elseif abs(r0 - 3.5) < 1e-12
        c = base;
    elseif abs(r0 - 4.5) < 1e-12
        c = darken(base, 0.24);
    else
        c = base;
    end
end

function c = get_r0_shade_reference_color(r0)
    base = [0.55, 0.55, 0.55];
    if abs(r0 - 2.5) < 1e-12
        c = lighten(base, 0.38);
    elseif abs(r0 - 3.5) < 1e-12
        c = base;
    elseif abs(r0 - 4.5) < 1e-12
        c = darken(base, 0.24);
    else
        c = base;
    end
end

function cmap = make_pastel_autumn_cmap(n)
    raw = autumn(n);
    pastelStrength = 0.58;
    cmap = (1 - pastelStrength) .* raw + pastelStrength .* ones(size(raw));
    cmap = min(max(cmap, 0), 1);
end

function marker = get_theta_marker(theta, idx)
    markers = ["o", "s", "^", "d", "v", ">", "<"];
    if nargin < 2 || ~isfinite(idx)
        idx = 1;
    end
    marker = markers(mod(idx - 1, numel(markers)) + 1);
end

%% =====================================================
% Labels and formatting
% ======================================================

function label = policy_display_label(policy)
    policy = string(policy);
    switch policy
        case "RL mixed"
            label = "RL mixed";
        case "PCR only"
            label = "PCR only";
        case "Ag only"
            label = "Antigen only";
        case "Half PCR/Ag"
            label = "Half PCR/antigen";
        case "No testing"
            label = "No testing";
        otherwise
            label = char(policy);
    end
end

function label = policy_short_label(policy)
    policy = string(policy);
    switch policy
        case "RL mixed"
            label = "RL";
        case "PCR only"
            label = "PCR";
        case "Ag only"
            label = "Antigen";
        case "Half PCR/Ag"
            label = "Half";
        case "No testing"
            label = "None";
        otherwise
            label = char(policy);
    end
end

function label = theta_label(theta)
    label = sprintf("\\theta=%.2g", theta);
end

function s = theta_to_string(theta)
    if ~isfinite(theta)
        s = "main";
    else
        s = sprintf("%.2f", theta);
    end
end

function label = format_heatmap_value(value, metric)
    if ~isfinite(value)
        label = "";
        return;
    end
    metric = string(metric);
    if contains(metric, "cost")
        if abs(value) >= 1000
            label = sprintf("%.1fK", value / 1000);
        elseif abs(value) >= 10
            label = sprintf("%.1f", value);
        else
            label = sprintf("%.2f", value);
        end
    elseif contains(metric, "efficiency")
        label = sprintf("%.3f", value);
    else
        if abs(value) >= 1000
            label = sprintf("%.1fK", value / 1000);
        elseif abs(value) >= 100
            label = sprintf("%.0f", value);
        elseif abs(value) >= 10
            label = sprintf("%.1f", value);
        else
            label = sprintf("%.2f", value);
        end
    end
end

function add_scatter_legend(ax, vars, policies, r0s)
    if nargin < 4
        r0s = [];
    end

    hold(ax, "on");
    h = gobjects(0);
    labels = strings(0);

    for i = 1:numel(vars)
        c = get_variant_color(vars(i), 0);
        hh = scatter(ax, nan, nan, 60);
        hh.Marker = 'o';
        hh.MarkerFaceColor = c;
        hh.MarkerEdgeColor = darken(c, 0.2);
        h(end + 1) = hh; %#ok<AGROW>
        labels(end + 1) = vars(i); %#ok<AGROW>
    end

    for i = 1:numel(policies)
        marker = get_policy_marker(policies(i));
        hh = scatter(ax, nan, nan, 55);
        hh.Marker = marker;
        hh.MarkerFaceColor = [0.82 0.82 0.82];
        hh.MarkerEdgeColor = [0.25 0.25 0.25];
        h(end + 1) = hh; %#ok<AGROW>
        labels(end + 1) = policy_display_label(policies(i)); %#ok<AGROW>
    end

    for rr = 1:numel(r0s)
        c = get_r0_shade_reference_color(r0s(rr));
        hh = scatter(ax, nan, nan, 55);
        hh.Marker = 'o';
        hh.MarkerFaceColor = c;
        hh.MarkerEdgeColor = darken(c, 0.25);
        h(end + 1) = hh; %#ok<AGROW>
        labels(end + 1) = sprintf("Target R0 %.1f", r0s(rr)); %#ok<AGROW>
    end

    legend(ax, h, labels, "Location", "eastoutside", "Box", "off", "FontSize", 7);
end


function add_variant_r0_theta_legend(ax, vars, r0s, thetas)
    hold(ax, "on");
    h = gobjects(0);
    labels = strings(0);

    for vv = 1:numel(vars)
        c = get_variant_color(vars(vv), 0);
        hh = scatter(ax, nan, nan, 60);
        hh.Marker = 'o';
        hh.MarkerFaceColor = c;
        hh.MarkerEdgeColor = darken(c, 0.25);
        h(end + 1) = hh; %#ok<AGROW>
        labels(end + 1) = vars(vv); %#ok<AGROW>
    end

    for rr = 1:numel(r0s)
        c = get_r0_shade_reference_color(r0s(rr));
        hh = scatter(ax, nan, nan, 55);
        hh.Marker = 'o';
        hh.MarkerFaceColor = c;
        hh.MarkerEdgeColor = darken(c, 0.25);
        h(end + 1) = hh; %#ok<AGROW>
        labels(end + 1) = sprintf("Target R0 %.1f", r0s(rr)); %#ok<AGROW>
    end

    for tt = 1:numel(thetas)
        hh = scatter(ax, nan, nan, 55);
        hh.Marker = get_theta_marker(thetas(tt), tt);
        hh.MarkerFaceColor = [0.82 0.82 0.82];
        hh.MarkerEdgeColor = [0.25 0.25 0.25];
        h(end + 1) = hh; %#ok<AGROW>
        labels(end + 1) = theta_label(thetas(tt)); %#ok<AGROW>
    end

    legend(ax, h, labels, "Location", "eastoutside", "Box", "off", "FontSize", 7);
end

function add_variant_r0_legend(ax, vars, r0s)
    hold(ax, "on");
    h = gobjects(0);
    labels = strings(0);
    for vv = 1:numel(vars)
        c = get_variant_color(vars(vv), 0);
        hh = scatter(ax, nan, nan, 60);
        hh.Marker = 'o';
        hh.MarkerFaceColor = c;
        hh.MarkerEdgeColor = darken(c, 0.25);
        h(end + 1) = hh; %#ok<AGROW>
        labels(end + 1) = vars(vv); %#ok<AGROW>
    end
    for rr = 1:numel(r0s)
        hh = scatter(ax, nan, nan, 55);
        hh.Marker = get_r0_marker(r0s(rr));
        hh.MarkerFaceColor = [0.82 0.82 0.82];
        hh.MarkerEdgeColor = [0.25 0.25 0.25];
        h(end + 1) = hh; %#ok<AGROW>
        labels(end + 1) = sprintf("R0=%.1f", r0s(rr)); %#ok<AGROW>
    end
    legend(ax, h, labels, "Location", "eastoutside", "Box", "off", "FontSize", 7);
end

function label = short_variant_label(variant)
    variant = string(variant);
    switch variant
        case "Alpha"
            label = "A";
        case "Delta"
            label = "D";
        case "Omicron"
            label = "O";
        otherwise
            label = char(variant);
    end
end

function add_variant_block_separators(ax, nR0, nVariants)
    hold(ax, "on");
    for vv = 1:(nVariants - 1)
        x = vv * nR0 + 0.5;
        xline(ax, x, "-", "Color", [0.25 0.25 0.25], ...
            "LineWidth", 0.8, "HandleVisibility", "off");
    end
end

%% =====================================================
% File, tag, and save helpers
% ======================================================
function tag = variant_tag(variant)
    tag = lower(char(variant));
end

function tag = r0_tag(r0)
    tag = strrep(sprintf("%.1f", r0), ".", "p");
end

function tags = theta_tag_candidates(theta)
    % Return possible folder tags for theta values.
    % Supports both conventions:
    % 0.50 -> 0p5 and 0p50
    % 1.00 -> 1 and 1p00
    % 1.50 -> 1p5 and 1p50
    tags = strings(0);
    compact = value_to_tag_compact(theta);
    tags(end + 1) = compact;
    fixed2 = strrep(sprintf("%.2f", theta), ".", "p");
    tags(end + 1) = fixed2;
    fixed1 = strrep(sprintf("%.1f", theta), ".", "p");
    tags(end + 1) = fixed1;
    tags = unique(tags, "stable");
end

function tag = value_to_tag_compact(value)
    if abs(value - round(value)) < 1e-12
        tag = sprintf("%d", round(value));
        return;
    end
    s = sprintf("%.2f", value);
    while endsWith(s, "0")
        s = extractBefore(s, strlength(s));
    end
    if endsWith(s, ".")
        s = extractBefore(s, strlength(s));
    end
    tag = strrep(s, ".", "p");
end

function tag = theta_tag(theta)
    tags = theta_tag_candidates(theta);
    tag = tags(1);
end

function save_figure(fig, pathWithoutExt)
    savefig(fig, pathWithoutExt + ".fig");
    exportgraphics(fig, pathWithoutExt + ".png", "Resolution", 300);
    exportgraphics(fig, pathWithoutExt + ".pdf", "ContentType", "vector");
    try
        exportgraphics(fig, pathWithoutExt + ".svg", "ContentType", "vector");
    catch
        warning("SVG export failed for %s", pathWithoutExt);
    end
    fprintf("[Saved] %s.fig/png/pdf/svg\n", pathWithoutExt);
    close(fig);
end

%% =====================================================
% Axis helpers
% ======================================================
function clean_axis(ax)
    ax.Box = "off";
    ax.TickDir = "out";
    ax.LineWidth = 0.8;
    ax.FontSize = 8.5;
end

function clean_heatmap_axis(ax)
    ax.Box = "off";
    ax.TickDir = "out";
    ax.LineWidth = 0.8;
    ax.FontSize = 8;
end

function set_y_lower_zero(ax)
    yl = ylim(ax);
    if ~all(isfinite(yl))
        return;
    end
    upperVal = yl(2);
    if upperVal <= 0
        upperVal = 1;
    end
    ylim(ax, [0, upperVal]);
end
