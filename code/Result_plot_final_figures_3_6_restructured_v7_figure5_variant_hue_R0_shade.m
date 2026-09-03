%% Result_plot_final_figures_3_6_restructured_v5_fixed_visuals.m
% Final Results Figures 3--6, restructured for action -> testing -> epidemic -> cost logic
%
% Figure 3. Testing actions and hidden-case detection under the learned policy
% Figure 4. Epidemic dynamics under adaptive testing
% Figure 5. Control-cost trade-off under testing policies
%          Scatter hue encodes variant; shade intensity encodes target R0.
% Figure 6. Testing actions and outcomes across transmission intensities
%
% Notes:
% - Main figures use R0 = 3.5 unless otherwise noted.
% - Action 3 is retained as the original retest interval in days and plotted
%   on the right y-axis in Figure 3A.
% - Hidden infectious composition in Figure 4 is shown as overlapping Ip and Ia bars plus an Ip+Ia total line.
% - All plotted source summaries are exported as CSV files.

clear; clc; close all;

%% =====================================================
% User settings
% ======================================================
RESULT_ROOT = "results";
FIG_DIR = fullfile("figures", "final_results_restructured");
CSV_DIR = fullfile(FIG_DIR, "csv");

if ~exist(FIG_DIR, "dir"); mkdir(FIG_DIR); end
if ~exist(CSV_DIR, "dir"); mkdir(CSV_DIR); end

VARIANTS = ["Alpha", "Delta", "Omicron"];
TARGET_R0_VALUES = [2.5, 3.5, 4.5];

MAIN_R0 = 3.5;
DAYS_IN_STEP = 3;
MAX_TEST_INTERVAL = 21;

COST_PCR = 100000.0;
COST_AG  = 55920.0;

CI_LEVEL = 0.95;
CI_ALPHA = 1.0 - CI_LEVEL;
FILL_ALPHA = 0.16;

% Cost-effectiveness ratios can be unstable when cost is zero or nearly zero.
MIN_COST_FOR_COST_EFFECTIVENESS = 1e7;  % 0.01 billion cost units

SAVE_SUPPLEMENT_R0_POLICY_PERFORMANCE = true;

%% =====================================================
% Policy settings
% ======================================================
POLICIES = ["RL mixed", "PCR only", "Ag only", "Half PCR/Ag", "No testing"];
POLICIES_FOR_TRADEOFF = ["RL mixed", "PCR only", "Ag only", "Half PCR/Ag"];

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

ACTION_COLS = [
    "high_risk_pool_coverage"
    "ag_screening_intensity"
    "retest_interval_days"
    "pcr_high_risk_intensity"
]';

ACTION_LABELS = containers.Map( ...
    {'high_risk_pool_coverage', ...
     'ag_screening_intensity', ...
     'retest_interval_days', ...
     'pcr_high_risk_intensity'}, ...
    {'High-risk coverage', ...
     'Antigen screening', ...
     'Testing period', ...
     'PCR intensity'} ...
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

TESTING_EFFORT_COLS = [
    "selected_total", ...
    "selected_pcr", ...
    "selected_ag", ...
    "actual_total", ...
    "actual_pcr", ...
    "actual_ag"
];

%% =====================================================
% Main
% ======================================================
fprintf("========================================\n");
fprintf("Plotting restructured Results Figures 3--6 with ratio labels and updated encodings\n");
fprintf("Main R0: %.1f\n", MAIN_R0);
fprintf("Figure directory: %s\n", FIG_DIR);
fprintf("CSV directory: %s\n", CSV_DIR);
fprintf("========================================\n");

plot_final_figure3_action_testing_pathway(MAIN_R0);
plot_final_figure4_epidemic_dynamics(MAIN_R0);
plot_final_figure5_control_cost_landscape();
plot_final_figure6_r0_sensitivity_pathway();

if SAVE_SUPPLEMENT_R0_POLICY_PERFORMANCE
    for r0 = TARGET_R0_VALUES
        if abs(r0 - MAIN_R0) > 1e-12
            plot_supplement_policy_performance_reference(r0);
        end
    end
end

fprintf("\nFinished plotting restructured Results Figures 3--6.\n");

%% =====================================================
% Figure 3. Testing actions and hidden-case detection under the learned policy
% ======================================================
function plot_final_figure3_action_testing_pathway(r0)
    vars = evalin("base", "VARIANTS");
    figDir = evalin("base", "FIG_DIR");
    csvDir = evalin("base", "CSV_DIR");

    fig = figure("Color", "w", "Position", [40, 60, 1800, 980]);
    tlo = tiledlayout(numel(vars), 4, "TileSpacing", "compact", "Padding", "compact");

    actionsCsv = table();
    testsCsv = table();
    detectionsCsv = table();
    efficiencyCsv = table();

    for i = 1:numel(vars)
        variant = vars(i);
        result = load_scenario(variant, r0, "RL mixed", false);

        if isempty(result)
            continue;
        end

        %% A. Learned actions with action 3 on right y-axis
        axA = nexttile(tlo, (i - 1) * 4 + 1);
        [actionSummary] = plot_learned_actions_dual_axis(axA, result.actions, variant, r0);
        actionsCsv = [actionsCsv; actionSummary]; %#ok<AGROW>

        if i == 1
            title(axA, "Testing actions", "FontWeight", "normal");
        end
        ylabel(axA, sprintf("%s\nAction value", variant), ...
            "Color", get_variant_color(variant, 0), "FontWeight", "bold");
        if i == numel(vars)
            xlabel(axA, "Day");
        end

        %% B. Number of tests
        axB = nexttile(tlo, (i - 1) * 4 + 2);
        [testingSummary] = plot_realized_testing_dual_axis(axB, result.n_tests, variant, r0);
        testsCsv = [testsCsv; testingSummary]; %#ok<AGROW>

        if i == 1
            title(axB, "Number of tests", "FontWeight", "normal");
        end
        if i == numel(vars)
            xlabel(axB, "Day");
        end

        %% C. Detected hidden cases by assay
        axC = nexttile(tlo, (i - 1) * 4 + 3);
        [detSummary] = plot_cumulative_hidden_detections(axC, result.testing_step, variant, r0);
        detectionsCsv = [detectionsCsv; detSummary]; %#ok<AGROW>

        if i == 1
            title(axC, "Detected hidden cases", "FontWeight", "normal");
        end
        if i == numel(vars)
            xlabel(axC, "Day");
        end

        %% D. Detection efficiency and PCR share
        axD = nexttile(tlo, (i - 1) * 4 + 4);
        [effSummary] = plot_detection_efficiency_and_modality_ratio(axD, result.n_tests, result.testing_step, variant, r0);
        efficiencyCsv = [efficiencyCsv; effSummary]; %#ok<AGROW>

        if i == 1
            title(axD, "Detection efficiency and testing modality ratio", "FontWeight", "normal");
        end
        if i == numel(vars)
            xlabel(axD, "Day");
        end
    end

    if height(actionsCsv) > 0
        writetable(actionsCsv, fullfile(csvDir, sprintf("Figure3_actions_R0_%s.csv", r0_tag(r0))));
    end
    if height(testsCsv) > 0
        writetable(testsCsv, fullfile(csvDir, sprintf("Figure3_realized_testing_R0_%s.csv", r0_tag(r0))));
    end
    if height(detectionsCsv) > 0
        writetable(detectionsCsv, fullfile(csvDir, sprintf("Figure3_hidden_detections_R0_%s.csv", r0_tag(r0))));
    end
    if height(efficiencyCsv) > 0
        writetable(efficiencyCsv, fullfile(csvDir, sprintf("Figure3_efficiency_modality_ratio_R0_%s.csv", r0_tag(r0))));
    end

    sgtitle(sprintf("Testing actions and detection outcomes under PPO, target R0 = %.1f", r0), ...
        "FontWeight", "normal");

    save_figure(fig, fullfile(figDir, sprintf("Figure3_action_testing_pathway_R0_%s", r0_tag(r0))));
end

function actionSummary = plot_learned_actions_dual_axis(ax, actions, variant, r0)
    maxInterval = evalin("base", "MAX_TEST_INTERVAL");

    actionSummary = table();

    if isempty(actions)
        clean_axis(ax);
        return;
    end

    hold(ax, "on");

    yyaxis(ax, "left");
    h1 = plot_action_mean(ax, actions, "high_risk_pool_coverage", "Action 1: high-risk coverage", get_action_color("coverage"), "-", 1.8);
    h2 = plot_action_mean(ax, actions, "pcr_high_risk_intensity", "Action 4: PCR intensity", get_action_color("pcr"), "--", 1.8);
    h3 = plot_action_mean(ax, actions, "ag_screening_intensity", "Action 2: antigen screening", get_action_color("ag"), ":", 2.0);
    ylim(ax, [0, 1.05]);
    ylabel(ax, "Action value");

    yyaxis(ax, "right");
    h4 = plot_action_mean(ax, actions, "retest_interval_days", "Action 3: testing period", get_action_color("retest"), "-.", 1.6);
    ylim(ax, [0, maxInterval + 0.5]);
    ylabel(ax, "Testing period (days)");

    actionCols = ["high_risk_pool_coverage", "pcr_high_risk_intensity", "ag_screening_intensity", "retest_interval_days"];
    for c = 1:numel(actionCols)
        metric = actionCols(c);
        s = summarize_by_time_tci(actions, metric, "day");
        s.figure = repmat("Figure3", height(s), 1);
        s.variant = repmat(variant, height(s), 1);
        s.R0 = repmat(r0, height(s), 1);
        s.policy = repmat("RL mixed", height(s), 1);
        s.metric = repmat(metric, height(s), 1);
        actionSummary = [actionSummary; s]; %#ok<AGROW>
    end

    grid(ax, "on");
    clean_axis(ax);

    if string(variant) == "Alpha"
        legend(ax, [h1, h3, h4, h2], ...
            ["Action 1: high-risk coverage", "Action 2: antigen screening", ...
             "Action 3: testing period", "Action 4: PCR intensity"], ...
            "Location", "northwest", "Box", "off", "FontSize", 7);
    end
end

function h = plot_action_mean(ax, T, valueCol, labelText, color, lineStyle, lineWidth)
    s = summarize_by_time_tci(T, valueCol, "day");
    h = plot(ax, s.day, s.mean, ...
        "Color", color, ...
        "LineStyle", lineStyle, ...
        "LineWidth", lineWidth, ...
        "DisplayName", labelText);
end

function testingSummary = plot_realized_testing_dual_axis(ax, nTests, variant, r0)
    testingSummary = table();

    if isempty(nTests)
        clean_axis(ax);
        return;
    end

    hold(ax, "on");
    pcr = summarize_by_time_tci_nonnegative(nTests, "n_pcr", "day");
    ag = summarize_by_time_tci_nonnegative(nTests, "n_ag", "day");

    yyaxis(ax, "left");
    cPcr = darken(get_variant_color(variant, 0), 0.10);
    b1 = bar(ax, pcr.day, pcr.mean, 1.0, ...
        "FaceColor", cPcr, ...
        "EdgeColor", "none", ...
        "FaceAlpha", 0.30, ...
        "DisplayName", "PCR tests");
    ylabel(ax, "PCR tests");
    set_y_lower_zero(ax);

    yyaxis(ax, "right");
    cAg = [0.92 0.60 0.10];
    hAg = stairs(ax, ag.day, ag.mean, ...
        "Color", cAg, ...
        "LineWidth", 1.8, ...
        "LineStyle", "-", ...
        "DisplayName", "Antigen tests");
    plot(ax, ag.day, ag.mean, "o", ...
        "Color", darken(cAg, 0.15), ...
        "MarkerFaceColor", lighten(cAg, 0.25), ...
        "MarkerSize", 3.0, ...
        "LineStyle", "none", ...
        "HandleVisibility", "off");
    ylabel(ax, "Antigen tests");
    set_y_lower_zero(ax);

    % Keep true zero antigen results visible rather than allowing the axis to collapse.
    if all(~isfinite(ag.mean) | ag.mean == 0)
        ylim(ax, [0, 1]);
        text(ax, max(pcr.day) * 0.98, 0.08, "Antigen = 0", ...
            "HorizontalAlignment", "right", ...
            "FontSize", 7, ...
            "Color", [0.35 0.35 0.35]);
    else
        finiteAg = ag.high(isfinite(ag.high));
        if ~isempty(finiteAg)
            ylim(ax, [0, max(1, max(finiteAg) * 1.20)]);
        end
    end

    pcr.figure = repmat("Figure3", height(pcr), 1);
    pcr.variant = repmat(variant, height(pcr), 1);
    pcr.R0 = repmat(r0, height(pcr), 1);
    pcr.policy = repmat("RL mixed", height(pcr), 1);
    pcr.assay = repmat("PCR", height(pcr), 1);
    pcr.metric = repmat("number_of_tests", height(pcr), 1);

    ag.figure = repmat("Figure3", height(ag), 1);
    ag.variant = repmat(variant, height(ag), 1);
    ag.R0 = repmat(r0, height(ag), 1);
    ag.policy = repmat("RL mixed", height(ag), 1);
    ag.assay = repmat("Antigen", height(ag), 1);
    ag.metric = repmat("number_of_tests", height(ag), 1);

    testingSummary = [pcr; ag];

    grid(ax, "on");
    clean_axis(ax);

    if string(variant) == "Alpha"
        legend(ax, [b1, hAg], ["PCR tests", "Antigen tests"], ...
            "Location", "northwest", "Box", "off", "FontSize", 7);
    end
end

function detSummary = plot_cumulative_hidden_detections(ax, testingStep, variant, r0)
    detSummary = table();

    if isempty(testingStep)
        clean_axis(ax);
        return;
    end

    hold(ax, "on");

    % Use the same rollout-level, t-based 95% CI logic used in the previous
    % testing/detection summaries. Because these are non-negative counts, the
    % lower CI bound is truncated at zero to avoid visually inflated ribbons,
    % especially when antigen detections are sparse.
    pcr = summarize_by_time_tci_nonnegative(testingStep, "cum_detected_hidden_pcr", "day");
    ag = summarize_by_time_tci_nonnegative(testingStep, "cum_detected_hidden_ag", "day");

    yyaxis(ax, "left");
    cPcr = darken(get_variant_color(variant, 0), 0.12);
    h1 = plot_summary_line_ci(ax, pcr, "PCR detection", cPcr, 2.0, true, "-");
    ylabel(ax, "PCR detection");
    set_y_lower_zero(ax);

    yyaxis(ax, "right");
    cAg = [0.92 0.60 0.10];
    % Antigen detections are sparse, so t-based CI ribbons can look visually
    % inflated relative to the small mean trajectory. The mean trajectory is
    % shown without a CI ribbon, while PCR keeps the 95% CI ribbon.
    h2 = plot_summary_line_ci(ax, ag, "Antigen detection", cAg, 2.0, false, "--");
    plot(ax, ag.day, ag.mean, "o", ...
        "Color", darken(cAg, 0.15), ...
        "MarkerFaceColor", lighten(cAg, 0.25), ...
        "MarkerSize", 3.0, ...
        "LineStyle", "none", ...
        "HandleVisibility", "off");
    ylabel(ax, "Antigen detection");
    set_y_lower_zero(ax);

    if all(~isfinite(ag.mean) | ag.mean == 0)
        ylim(ax, [0, 1]);
        text(ax, max(pcr.day) * 0.98, 0.08, "Antigen = 0", ...
            "HorizontalAlignment", "right", "FontSize", 7, "Color", [0.35 0.35 0.35]);
    else
        finiteAgMean = ag.mean(isfinite(ag.mean));
        if ~isempty(finiteAgMean)
            ylim(ax, [0, max(1, max(finiteAgMean) * 1.35)]);
        end
    end

    pcr.figure = repmat("Figure3", height(pcr), 1);
    pcr.variant = repmat(variant, height(pcr), 1);
    pcr.R0 = repmat(r0, height(pcr), 1);
    pcr.policy = repmat("RL mixed", height(pcr), 1);
    pcr.assay = repmat("PCR", height(pcr), 1);
    pcr.metric = repmat("detected_hidden_cases", height(pcr), 1);

    ag.figure = repmat("Figure3", height(ag), 1);
    ag.variant = repmat(variant, height(ag), 1);
    ag.R0 = repmat(r0, height(ag), 1);
    ag.policy = repmat("RL mixed", height(ag), 1);
    ag.assay = repmat("Antigen", height(ag), 1);
    ag.metric = repmat("detected_hidden_cases", height(ag), 1);

    detSummary = [pcr; ag];

    grid(ax, "on");
    clean_axis(ax);

    if string(variant) == "Alpha"
        legend(ax, [h1, h2], ["PCR detection", "Antigen detection"], ...
            "Location", "northwest", "Box", "off", "FontSize", 7);
    end
end

function effSummary = plot_detection_efficiency_and_modality_ratio(ax, nTests, testingStep, variant, r0)
    effSummary = table();

    if isempty(nTests) || isempty(testingStep)
        clean_axis(ax);
        return;
    end

    eff = build_efficiency_share_table(nTests, testingStep);

    effS = summarize_by_time_tci(eff, "detected_per_test", "day");
    pcrRatioS = summarize_by_time_tci(eff, "pcr_share", "day");
    agRatioS = summarize_by_time_tci(eff, "ag_share", "day");

    hold(ax, "on");

    yyaxis(ax, "left");
    cEff = darken(get_variant_color(variant, 0), 0.18);
    h1 = plot_summary_line_ci(ax, effS, "Detection efficiency", cEff, 2.0, true, "-");
    ylabel(ax, "Detection efficiency");
    set_y_lower_zero(ax);

    yyaxis(ax, "right");
    cPcrRatio = [0.25 0.25 0.25];
    cAgRatio = [0.92 0.60 0.10];
    h2 = plot(ax, pcrRatioS.day, pcrRatioS.mean, ...
        "Color", cPcrRatio, ...
        "LineStyle", "--", ...
        "LineWidth", 1.6, ...
        "DisplayName", "PCR testing ratio");
    h3 = plot(ax, agRatioS.day, agRatioS.mean, ...
        "Color", cAgRatio, ...
        "LineStyle", ":", ...
        "LineWidth", 2.3, ...
        "Marker", "o", ...
        "MarkerSize", 3.0, ...
        "MarkerFaceColor", lighten(cAgRatio, 0.18), ...
        "DisplayName", "Antigen testing ratio");
    ylabel(ax, "Testing modality ratio");
    ylim(ax, [0, 1.05]);

    effS.figure = repmat("Figure3", height(effS), 1);
    effS.variant = repmat(variant, height(effS), 1);
    effS.R0 = repmat(r0, height(effS), 1);
    effS.policy = repmat("RL mixed", height(effS), 1);
    effS.metric = repmat("detection_efficiency", height(effS), 1);

    pcrRatioS.figure = repmat("Figure3", height(pcrRatioS), 1);
    pcrRatioS.variant = repmat(variant, height(pcrRatioS), 1);
    pcrRatioS.R0 = repmat(r0, height(pcrRatioS), 1);
    pcrRatioS.policy = repmat("RL mixed", height(pcrRatioS), 1);
    pcrRatioS.metric = repmat("pcr_testing_ratio", height(pcrRatioS), 1);

    agRatioS.figure = repmat("Figure3", height(agRatioS), 1);
    agRatioS.variant = repmat(variant, height(agRatioS), 1);
    agRatioS.R0 = repmat(r0, height(agRatioS), 1);
    agRatioS.policy = repmat("RL mixed", height(agRatioS), 1);
    agRatioS.metric = repmat("antigen_testing_ratio", height(agRatioS), 1);

    effSummary = [effS; pcrRatioS; agRatioS];

    grid(ax, "on");
    clean_axis(ax);

    % The antigen testing ratio can be much smaller than the PCR testing ratio.
    % A compact inset displays the antigen trajectory on a percent scale so it
    % remains visible without rescaling the main modality-ratio axis.
    add_antigen_ratio_inset(ax, agRatioS, cAgRatio);

    if string(variant) == "Alpha"
        legend(ax, [h1, h2, h3], ...
            ["Detection efficiency", "PCR testing ratio", "Antigen testing ratio"], ...
            "Location", "northwest", "Box", "off", "FontSize", 7);
    end
end

function add_antigen_ratio_inset(parentAx, agRatioS, cAgRatio)
    finiteVals = agRatioS.mean(isfinite(agRatioS.mean));
    if isempty(finiteVals)
        return;
    end

    drawnow;
    axPos = parentAx.Position;
    insetW = axPos(3) * 0.42;
    insetH = axPos(4) * 0.34;
    insetX = axPos(1) + axPos(3) * 0.53;
    insetY = axPos(2) + axPos(4) * 0.10;

    fig = ancestor(parentAx, "figure");
    axInset = axes("Parent", fig, "Position", [insetX, insetY, insetW, insetH]);
    hold(axInset, "on");

    yPct = 100 .* agRatioS.mean;
    plot(axInset, agRatioS.day, yPct, ...
        "Color", cAgRatio, ...
        "LineWidth", 1.4, ...
        "Marker", "o", ...
        "MarkerSize", 2.2, ...
        "MarkerFaceColor", lighten(cAgRatio, 0.18));

    finitePct = yPct(isfinite(yPct));
    if isempty(finitePct) || all(finitePct == 0)
        ylim(axInset, [0, 1]);
        text(axInset, 0.98, 0.82, "Antigen = 0", ...
            "Units", "normalized", ...
            "HorizontalAlignment", "right", ...
            "FontSize", 5.8, ...
            "Color", [0.35 0.35 0.35]);
    else
        ymax = max(finitePct);
        ylim(axInset, [0, max(0.5, ymax * 1.30)]);
    end

    xlim(axInset, [min(agRatioS.day), max(agRatioS.day)]);
    title(axInset, "Antigen ratio (%)", "FontWeight", "normal", "FontSize", 6.2);
    axInset.Box = "on";
    axInset.TickDir = "out";
    axInset.FontSize = 5.8;
    axInset.LineWidth = 0.55;
    axInset.XTickLabel = [];
    grid(axInset, "on");

    axes(parentAx);
end


%% =====================================================
% Figure 4. Epidemic dynamics under adaptive testing
% ======================================================
function plot_final_figure4_epidemic_dynamics(r0)
    vars = evalin("base", "VARIANTS");
    policies = evalin("base", "POLICIES");
    figDir = evalin("base", "FIG_DIR");
    csvDir = evalin("base", "CSV_DIR");

    fig = figure("Color", "w", "Position", [40, 60, 1750, 980]);
    tlo = tiledlayout(numel(vars), 3, "TileSpacing", "compact", "Padding", "compact");

    hiddenCsv = table();
    activeCsv = table();
    finalCsv = table();

    for i = 1:numel(vars)
        variant = vars(i);
        resultRL = load_scenario(variant, r0, "RL mixed", false);
        resultNo = load_scenario(variant, r0, "No testing", false);

        if isempty(resultRL)
            continue;
        end

        %% A. Hidden infectious composition: Ip + Ia
        axA = nexttile(tlo, (i - 1) * 3 + 1);
        [hiddenSummary] = plot_hidden_infectious_composition(axA, resultRL, resultNo, variant, r0);
        hiddenCsv = [hiddenCsv; hiddenSummary]; %#ok<AGROW>

        if i == 1
            title(axA, "Hidden infectious composition", "FontWeight", "normal");
        end
        ylabel(axA, sprintf("%s\nNumber of individuals", variant), ...
            "Color", get_variant_color(variant, 0), "FontWeight", "bold");
        if i == numel(vars)
            xlabel(axA, "Day");
        end

        %% B. Active infectious burden
        axB = nexttile(tlo, (i - 1) * 3 + 2);
        [activeSummary] = plot_active_infectious_burden(axB, resultRL, resultNo, variant, r0);
        activeCsv = [activeCsv; activeSummary]; %#ok<AGROW>

        if i == 1
            title(axB, "Active infectious cases", "FontWeight", "normal");
        end
        if i == numel(vars)
            xlabel(axB, "Day");
        end

        %% C. Final epidemic summary
        axC = nexttile(tlo, (i - 1) * 3 + 3);
        [finalSummary] = plot_final_epidemic_summary(axC, variant, r0, policies);
        finalCsv = [finalCsv; finalSummary]; %#ok<AGROW>

        if i == 1
            title(axC, "Final epidemic size", "FontWeight", "normal");
        end
        if i == numel(vars)
            xlabel(axC, "Policy");
        end
    end

    if height(hiddenCsv) > 0
        writetable(hiddenCsv, fullfile(csvDir, sprintf("Figure4_hidden_infectious_composition_R0_%s.csv", r0_tag(r0))));
    end
    if height(activeCsv) > 0
        writetable(activeCsv, fullfile(csvDir, sprintf("Figure4_active_infectious_R0_%s.csv", r0_tag(r0))));
    end
    if height(finalCsv) > 0
        writetable(finalCsv, fullfile(csvDir, sprintf("Figure4_final_epidemic_summary_R0_%s.csv", r0_tag(r0))));
    end

    sgtitle(sprintf("Epidemic dynamics under adaptive testing, target R0 = %.1f", r0), ...
        "FontWeight", "normal");

    save_figure(fig, fullfile(figDir, sprintf("Figure4_epidemic_dynamics_R0_%s", r0_tag(r0))));
end

function outCsv = plot_hidden_infectious_composition(ax, resultRL, resultNo, variant, r0)
    outCsv = table();
    stateRL = resultRL.state;

    sIp = summarize_by_time_tci(stateRL, "Ip", "day");
    sIa = summarize_by_time_tci(stateRL, "Ia", "day");
    sHidden = summarize_hidden_infectious_total_from_components(stateRL);

    hold(ax, "on");

    cBase = get_variant_color(variant, 0);
    cIp = darken(cBase, 0.16);
    cIa = lighten(cBase, 0.24);
    cTotal = [0.12 0.12 0.12];

    % Draw component burdens as overlapping, shadow-like bars rather than a
    % stacked bar. Ip is drawn first as the lower/background layer, and Ia is
    % drawn second as the upper/front layer. The total trajectory is then
    % plotted separately as Ip + Ia, so it does not visually follow only Ia.
    hIp = bar(ax, sIp.day, sIp.mean, 1.00, ...
        "FaceColor", cIp, ...
        "EdgeColor", "none", ...
        "FaceAlpha", 0.22, ...
        "DisplayName", "Pre-symptomatic infectious (I_p)");

    hIa = bar(ax, sIa.day, sIa.mean, 0.62, ...
        "FaceColor", cIa, ...
        "EdgeColor", "none", ...
        "FaceAlpha", 0.42, ...
        "DisplayName", "Asymptomatic infectious (I_a)");

    hTotal = plot_summary_line_ci(ax, sHidden, "Total hidden infectious cases", cTotal, 2.35, false, "-");

    if ~isempty(resultNo)
        sNo = summarize_hidden_infectious_total_from_components(resultNo.state);
        hNo = plot_summary_line_ci(ax, sNo, "No testing", [0.40 0.40 0.40], 1.75, false, "-.");
    else
        hNo = gobjects(1);
    end

    grid(ax, "on");
    set_y_lower_zero(ax);
    clean_axis(ax);

    if string(variant) == "Alpha" && isgraphics(hNo)
        legend(ax, [hIp, hIa, hTotal, hNo], ...
            ["Pre-symptomatic infectious (I_p)", "Asymptomatic infectious (I_a)", ...
             "Total hidden infectious cases", "No testing"], ...
            "Location", "northwest", "Box", "off", "FontSize", 7);
    end

    sIp = add_plot_metadata(sIp, "Figure4", variant, r0, "RL mixed", "Ip");
    sIa = add_plot_metadata(sIa, "Figure4", variant, r0, "RL mixed", "Ia");
    sHidden = add_plot_metadata(sHidden, "Figure4", variant, r0, "RL mixed", "hidden_IpIa");
    outCsv = [outCsv; sIp; sIa; sHidden];

    if ~isempty(resultNo)
        sNo = add_plot_metadata(sNo, "Figure4", variant, r0, "No testing", "hidden_IpIa");
        outCsv = [outCsv; sNo];
    end
end

function sHidden = summarize_hidden_infectious_total_from_components(stateT)
    % The plotted total hidden infectious cases is explicitly calculated from
    % the two component trajectories, Ip + Ia, so the mean line represents the
    % component sum shown in the panel.
    sIp = summarize_by_time_tci(stateT, "Ip", "day");
    sIa = summarize_by_time_tci(stateT, "Ia", "day");
    sHidden = summarize_by_time_tci(stateT, "hidden_IpIa", "day");
    sHidden.mean = sIp.mean + sIa.mean;
    sHidden.low = max(0, sHidden.low);
    sHidden.high = max(sHidden.high, sHidden.mean);
end

function outCsv = plot_active_infectious_burden(ax, resultRL, resultNo, variant, r0)
    outCsv = table();
    hold(ax, "on");

    cBase = get_variant_color(variant, 0);
    sRL = summarize_by_time_tci(resultRL.state, "active_infectious", "day");
    h1 = plot_summary_line_ci(ax, sRL, "RL mixed", darken(cBase, 0.12), 2.2, true, "-");

    if ~isempty(resultNo)
        sNo = summarize_by_time_tci(resultNo.state, "active_infectious", "day");
        h2 = plot_summary_line_ci(ax, sNo, "No testing", [0.25 0.25 0.25], 1.8, true, "--");
    else
        h2 = gobjects(1);
    end

    ylabel(ax, "Number of individuals");
    grid(ax, "on");
    set_y_lower_zero(ax);
    clean_axis(ax);

    if string(variant) == "Alpha" && isgraphics(h2)
        legend(ax, [h1, h2], ["RL mixed", "No testing"], ...
            "Location", "northwest", "Box", "off", "FontSize", 7);
    end

    sRL = add_plot_metadata(sRL, "Figure4", variant, r0, "RL mixed", "active_infectious");
    outCsv = [outCsv; sRL];

    if ~isempty(resultNo)
        sNo = add_plot_metadata(sNo, "Figure4", variant, r0, "No testing", "active_infectious");
        outCsv = [outCsv; sNo];
    end
end

function finalSummary = plot_final_epidemic_summary(ax, variant, r0, policies)
    finalSummary = table();

    for pp = 1:numel(policies)
        policy = policies(pp);
        result = load_scenario(variant, r0, policy, false);
        if isempty(result)
            continue;
        end

        finalCum = final_by_rollout(result.new_ip, "cum_infections");
        peakHidden = groupsummary(result.state, "rollout", "max", "hidden_IpIa");
        peakHidden = peakHidden(:, ["rollout", "max_hidden_IpIa"]);
        peakHidden = renamevars(peakHidden, "max_hidden_IpIa", "peak_hidden_infectious");

        [mFinal, loFinal, hiFinal] = t_based_mean_ci(finalCum.cum_infections);
        [mPeak, loPeak, hiPeak] = t_based_mean_ci(peakHidden.peak_hidden_infectious);

        row = table();
        row.figure = "Figure4";
        row.variant = variant;
        row.R0 = r0;
        row.policy = policy;
        row.final_cumulative_infections_mean = mFinal;
        row.final_cumulative_infections_low = loFinal;
        row.final_cumulative_infections_high = hiFinal;
        row.peak_hidden_infectious_mean = mPeak;
        row.peak_hidden_infectious_low = loPeak;
        row.peak_hidden_infectious_high = hiPeak;
        row.n_rollouts = sum(isfinite(finalCum.cum_infections));

        finalSummary = [finalSummary; row]; %#ok<AGROW>
    end

    if height(finalSummary) == 0
        clean_axis(ax);
        return;
    end

    hold(ax, "on");
    x = 1:numel(policies);

    means = nan(numel(policies), 1);
    lows = nan(numel(policies), 1);
    highs = nan(numel(policies), 1);
    peakMeans = nan(numel(policies), 1);

    for i = 1:numel(policies)
        idx = finalSummary.policy == policies(i);
        if any(idx)
            row = finalSummary(idx, :);
            means(i) = row.final_cumulative_infections_mean(1);
            lows(i) = row.final_cumulative_infections_low(1);
            highs(i) = row.final_cumulative_infections_high(1);
            peakMeans(i) = row.peak_hidden_infectious_mean(1);
        end
    end

    yyaxis(ax, "left");
    b = bar(ax, x, means, 0.65, ...
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
    ylabel(ax, "Final cumulative infections");
    yMax = max(means + upperErr, [], "omitnan");
    if isempty(yMax) || ~isfinite(yMax) || yMax <= 0
        yMax = max(means, [], "omitnan");
    end
    if isempty(yMax) || ~isfinite(yMax) || yMax <= 0
        yMax = 1;
    end
    ylim(ax, [0, yMax * 1.18]);
    add_bar_value_labels(ax, x, means);

    yyaxis(ax, "right");
    h = scatter(ax, x, peakMeans, 38, ...
        "Marker", "v", ...
        "MarkerFaceColor", [0.15 0.15 0.15], ...
        "MarkerEdgeColor", "w", ...
        "LineWidth", 0.6, ...
        "DisplayName", "Peak hidden infectious cases");
    ylabel(ax, "Peak hidden infectious cases");
    set_y_lower_zero(ax);

    xticks(ax, x);
    xticklabels(ax, arrayfun(@policy_short_label, policies, "UniformOutput", false));
    xtickangle(ax, 25);
    grid(ax, "on");
    clean_axis(ax);

    if string(variant) == "Alpha"
        legend(ax, [b, h], ["Final cumulative infections", "Peak hidden infectious cases"], ...
            "Location", "northwest", "Box", "off", "FontSize", 7);
    end
end

%% =====================================================
% Figure 5. Control-cost trade-off under testing policies
% ======================================================
function plot_final_figure5_control_cost_landscape()
    vars = evalin("base", "VARIANTS");
    r0s = evalin("base", "TARGET_R0_VALUES");
    policies = evalin("base", "POLICIES_FOR_TRADEOFF");
    figDir = evalin("base", "FIG_DIR");
    csvDir = evalin("base", "CSV_DIR");

    rolloutDf = build_rollout_metric_table_all_policies();
    comparisonDf = add_no_testing_comparison_metrics(rolloutDf);
    summary = summarize_tradeoff_values(comparisonDf);
    summary = add_cost_effectiveness_summary(summary);

    writetable(rolloutDf, fullfile(csvDir, "Figure5_rollout_metrics_raw.csv"));
    writetable(comparisonDf, fullfile(csvDir, "Figure5_rollout_metrics_vs_notesting.csv"));
    writetable(summary, fullfile(csvDir, "Figure5_tradeoff_summary.csv"));

    fig = figure("Color", "w", "Position", [60, 70, 1650, 920]);
    tlo = tiledlayout(2, 2, "TileSpacing", "compact", "Padding", "compact");

    %% A. Cost vs infections averted
    axA = nexttile(tlo, 1);
    plot_tradeoff_scatter(axA, summary, "infections_averted_mean", ...
        "Infections averted", "Infections averted", true);

    %% B. Cost vs peak hidden reduction
    axB = nexttile(tlo, 2);
    plot_tradeoff_scatter(axB, summary, "peak_hidden_infectious_reduction_mean", ...
        "Peak hidden reduction", "Peak hidden reduction", false);

    %% C. Cumulative testing cost heatmap
    axC = nexttile(tlo, 3);
    plot_rl_heatmap(axC, summary, "cum_testing_cost_B", ...
        "Cumulative testing cost", "%.2f");

    %% D. Cost-effectiveness summary heatmap
    axD = nexttile(tlo, 4);
    plot_rl_heatmap(axD, summary, "infections_averted_per_1B_mean", ...
        "Cost-effectiveness summary", "%.0f");

    sgtitle("Control-cost trade-off under testing policies", ...
        "FontWeight", "normal");

    save_figure(fig, fullfile(figDir, "Figure5_control_cost_landscape"));
end

function plot_tradeoff_scatter(ax, summary, yMetric, yLabelText, titleText, addLegendFlag)
    vars = evalin("base", "VARIANTS");
    r0s = evalin("base", "TARGET_R0_VALUES");
    policies = evalin("base", "POLICIES_FOR_TRADEOFF");

    hold(ax, "on");

    for vi = 1:numel(vars)
        variant = vars(vi);

        for rr = 1:numel(r0s)
            r0 = r0s(rr);

            % Color hue encodes variant, and color intensity encodes target R0.
            % Alpha remains blue, Delta remains red, and Omicron remains yellow.
            % Lower R0 is shown as a lighter shade and higher R0 as a darker shade.
            pointColor = get_variant_r0_color(variant, r0);
            edgeColor = darken(pointColor, 0.30);

            for pp = 1:numel(policies)
                policy = policies(pp);
                idx = summary.variant == variant & abs(summary.R0 - r0) < 1e-12 & summary.policy == policy;
                if ~any(idx)
                    continue;
                end

                s = summary(idx, :);
                xCostB = s.cum_testing_cost_mean(1) / 1e9;
                yVal = s.(yMetric)(1);

                if ~isfinite(xCostB) || xCostB <= 0 || ~isfinite(yVal)
                    continue;
                end

                marker = get_policy_marker(policy);

                if policy == "RL mixed"
                    sz = 96;
                    lw = 1.45;
                else
                    sz = 56;
                    lw = 0.85;
                end

                scatter(ax, xCostB, yVal, sz, ...
                    "Marker", marker, ...
                    "MarkerFaceColor", pointColor, ...
                    "MarkerEdgeColor", edgeColor, ...
                    "LineWidth", lw);

                text(ax, xCostB * 1.035, yVal, sprintf("%.1f", r0), ...
                    "FontSize", 6.2, ...
                    "Color", [0.22 0.22 0.22]);
            end
        end
    end

    yline(ax, 0, "--", "Color", [0.45 0.45 0.45], "LineWidth", 0.9);
    set(ax, "XScale", "log");
    xlabel(ax, "Cumulative testing cost (billion cost units, log scale)");
    ylabel(ax, yLabelText);
    title(ax, titleText, "FontWeight", "normal");
    grid(ax, "on");
    clean_axis(ax);

    if addLegendFlag
        add_scatter_legend(ax, vars, policies, r0s);
    end
end


function plot_rl_heatmap(ax, summary, metric, titleText, fmt)
    vars = evalin("base", "VARIANTS");
    r0s = evalin("base", "TARGET_R0_VALUES");

    mat = nan(numel(vars), numel(r0s));

    for i = 1:numel(vars)
        for j = 1:numel(r0s)
            idx = summary.variant == vars(i) & abs(summary.R0 - r0s(j)) < 1e-12 & summary.policy == "RL mixed";
            if ~any(idx)
                continue;
            end
            s = summary(idx, :);

            if metric == "cum_testing_cost_B"
                mat(i, j) = s.cum_testing_cost_mean(1) / 1e9;
            else
                mat(i, j) = s.(metric)(1);
            end
        end
    end

    hImg = imagesc(ax, mat);
    set(hImg, "AlphaData", isfinite(mat));
    set(ax, "Color", [0.96 0.96 0.96]);
    colormap(ax, make_pastel_autumn_cmap(128));

    finiteVals = mat(isfinite(mat));
    if ~isempty(finiteVals)
        caxis(ax, [min(finiteVals), max(finiteVals) + 1e-12]);
    end

    xticks(ax, 1:numel(r0s));
    xticklabels(ax, arrayfun(@(x) sprintf("%.1f", x), r0s, "UniformOutput", false));
    yticks(ax, 1:numel(vars));
    yticklabels(ax, vars);
    xlabel(ax, "Target R0");
    title(ax, titleText, "FontWeight", "normal");

    for i = 1:numel(vars)
        for j = 1:numel(r0s)
            if isfinite(mat(i, j))
                text(ax, j, i, sprintf(fmt, mat(i, j)), ...
                    "HorizontalAlignment", "center", ...
                    "VerticalAlignment", "middle", ...
                    "FontSize", 8, ...
                    "Color", [0.12 0.12 0.12]);
            else
                text(ax, j, i, "--", ...
                    "HorizontalAlignment", "center", ...
                    "VerticalAlignment", "middle", ...
                    "FontSize", 8, ...
                    "Color", [0.45 0.45 0.45]);
            end
        end
    end

    cb = colorbar(ax);
    cb.FontSize = 7;
    set(ax, "TickLength", [0, 0]);
    clean_heatmap_axis(ax);
end

%% =====================================================
% Figure 6. Testing actions and outcomes across transmission intensities
% ======================================================
function plot_final_figure6_r0_sensitivity_pathway()
    figDir = evalin("base", "FIG_DIR");
    csvDir = evalin("base", "CSV_DIR");

    summary = build_rl_pathway_summary();
    writetable(summary, fullfile(csvDir, "Figure6_R0_sensitivity_pathway_summary.csv"));

    fig = figure("Color", "w", "Position", [50, 60, 1650, 950]);
    tlo = tiledlayout(2, 2, "TileSpacing", "compact", "Padding", "compact");

    axA = nexttile(tlo, 1);
    plot_action_sensitivity_dual_axis(axA, summary);
    title(axA, "Action summary", "FontWeight", "normal");

    axB = nexttile(tlo, 2);
    plot_testing_sensitivity_dual_axis(axB, summary);
    title(axB, "Testing summary", "FontWeight", "normal");

    axC = nexttile(tlo, 3);
    plot_epidemic_sensitivity_dual_axis(axC, summary);
    title(axC, "Epidemic summary", "FontWeight", "normal");

    axD = nexttile(tlo, 4);
    plot_rl_cost_outcome_paths(axD, summary);
    title(axD, "Cost summary", "FontWeight", "normal");

    sgtitle("Testing actions and outcomes across transmission intensities", ...
        "FontWeight", "normal");

    save_figure(fig, fullfile(figDir, "Figure6_R0_sensitivity_pathway"));
end

function summary = build_rl_pathway_summary()
    vars = evalin("base", "VARIANTS");
    r0s = evalin("base", "TARGET_R0_VALUES");

    summary = table();

    for vi = 1:numel(vars)
        variant = vars(vi);
        for rr = 1:numel(r0s)
            r0 = r0s(rr);

            result = load_scenario(variant, r0, "RL mixed", false);
            baseline = load_scenario(variant, r0, "No testing", false);

            if isempty(result)
                continue;
            end

            actionStats = summarize_action_profile(result.actions);
            testingStats = summarize_testing_profile(result.n_tests, result.testing_step);
            epidemicStats = summarize_epidemic_profile(result, baseline);

            row = table();
            row.figure = "Figure6";
            row.variant = variant;
            row.R0 = r0;
            row.policy = "RL mixed";

            row.max_high_risk_coverage = actionStats.max_high_risk_coverage;
            row.day_max_high_risk_coverage = actionStats.day_max_high_risk_coverage;
            row.max_ag_screening = actionStats.max_ag_screening;
            row.day_max_ag_screening = actionStats.day_max_ag_screening;
            row.min_retest_interval_days = actionStats.min_retest_interval_days;
            row.day_min_retest_interval_days = actionStats.day_min_retest_interval_days;
            row.max_pcr_intensity = actionStats.max_pcr_intensity;
            row.day_max_pcr_intensity = actionStats.day_max_pcr_intensity;

            row.cum_pcr_tests_mean = testingStats.cum_pcr_tests_mean;
            row.cum_ag_tests_mean = testingStats.cum_ag_tests_mean;
            row.cum_detected_hidden_mean = testingStats.cum_detected_hidden_mean;
            row.detection_efficiency_mean = testingStats.detection_efficiency_mean;
            row.pcr_fraction_total_mean = testingStats.pcr_fraction_total_mean;

            row.final_cumulative_infections_mean = epidemicStats.final_cumulative_infections_mean;
            row.peak_hidden_infectious_mean = epidemicStats.peak_hidden_infectious_mean;
            row.peak_active_infectious_mean = epidemicStats.peak_active_infectious_mean;
            row.cum_testing_cost_mean = epidemicStats.cum_testing_cost_mean;
            row.infections_averted_mean = epidemicStats.infections_averted_mean;
            row.peak_hidden_infectious_reduction_mean = epidemicStats.peak_hidden_infectious_reduction_mean;
            row.infections_averted_per_1B_mean = epidemicStats.infections_averted_per_1B_mean;

            summary = [summary; row]; %#ok<AGROW>
        end
    end
end

function stats = summarize_action_profile(actions)
    stats = struct();
    fields = {"max_high_risk_coverage", "day_max_high_risk_coverage", ...
              "max_ag_screening", "day_max_ag_screening", ...
              "min_retest_interval_days", "day_min_retest_interval_days", ...
              "max_pcr_intensity", "day_max_pcr_intensity"};
    for i = 1:numel(fields)
        stats.(fields{i}) = NaN;
    end

    if isempty(actions)
        return;
    end

    h = summarize_by_time_tci(actions, "high_risk_pool_coverage", "day");
    g = summarize_by_time_tci(actions, "ag_screening_intensity", "day");
    L = summarize_by_time_tci(actions, "retest_interval_days", "day");
    p = summarize_by_time_tci(actions, "pcr_high_risk_intensity", "day");

    [stats.max_high_risk_coverage, idx] = max(h.mean, [], "omitnan");
    if ~isempty(idx) && isfinite(stats.max_high_risk_coverage); stats.day_max_high_risk_coverage = h.day(idx); end

    [stats.max_ag_screening, idx] = max(g.mean, [], "omitnan");
    if ~isempty(idx) && isfinite(stats.max_ag_screening); stats.day_max_ag_screening = g.day(idx); end

    [stats.min_retest_interval_days, idx] = min(L.mean, [], "omitnan");
    if ~isempty(idx) && isfinite(stats.min_retest_interval_days); stats.day_min_retest_interval_days = L.day(idx); end

    [stats.max_pcr_intensity, idx] = max(p.mean, [], "omitnan");
    if ~isempty(idx) && isfinite(stats.max_pcr_intensity); stats.day_max_pcr_intensity = p.day(idx); end
end

function stats = summarize_testing_profile(nTests, testingStep)
    stats = struct();
    stats.cum_pcr_tests_mean = NaN;
    stats.cum_ag_tests_mean = NaN;
    stats.cum_detected_hidden_mean = NaN;
    stats.detection_efficiency_mean = NaN;
    stats.pcr_fraction_total_mean = NaN;

    if isempty(nTests)
        return;
    end

    pcr = final_by_rollout(nTests, "cum_pcr");
    ag = final_by_rollout(nTests, "cum_ag");
    stats.cum_pcr_tests_mean = mean(pcr.cum_pcr, "omitnan");
    stats.cum_ag_tests_mean = mean(ag.cum_ag, "omitnan");

    totalTests = pcr.cum_pcr + ag.cum_ag;
    stats.pcr_fraction_total_mean = mean(pcr.cum_pcr ./ max(totalTests, 1e-12), "omitnan");

    if ~isempty(testingStep)
        det = final_by_rollout(testingStep, "cum_detected_hidden");
        stats.cum_detected_hidden_mean = mean(det.cum_detected_hidden, "omitnan");
        stats.detection_efficiency_mean = mean(det.cum_detected_hidden ./ max(totalTests, 1e-12), "omitnan");
    end
end

function stats = summarize_epidemic_profile(result, baseline)
    minCost = evalin("base", "MIN_COST_FOR_COST_EFFECTIVENESS");

    stats = struct();
    stats.final_cumulative_infections_mean = NaN;
    stats.peak_hidden_infectious_mean = NaN;
    stats.peak_active_infectious_mean = NaN;
    stats.cum_testing_cost_mean = NaN;
    stats.infections_averted_mean = NaN;
    stats.peak_hidden_infectious_reduction_mean = NaN;
    stats.infections_averted_per_1B_mean = NaN;

    finalInf = final_by_rollout(result.new_ip, "cum_infections");
    finalCost = final_by_rollout(result.n_tests, "cum_testing_cost");

    peakHidden = groupsummary(result.state, "rollout", "max", "hidden_IpIa");
    peakHidden = peakHidden(:, ["rollout", "max_hidden_IpIa"]);
    peakHidden = renamevars(peakHidden, "max_hidden_IpIa", "peak_hidden_infectious");

    peakActive = groupsummary(result.state, "rollout", "max", "active_infectious");
    peakActive = peakActive(:, ["rollout", "max_active_infectious"]);
    peakActive = renamevars(peakActive, "max_active_infectious", "peak_active_infectious");

    stats.final_cumulative_infections_mean = mean(finalInf.cum_infections, "omitnan");
    stats.peak_hidden_infectious_mean = mean(peakHidden.peak_hidden_infectious, "omitnan");
    stats.peak_active_infectious_mean = mean(peakActive.peak_active_infectious, "omitnan");
    stats.cum_testing_cost_mean = mean(finalCost.cum_testing_cost, "omitnan");

    if ~isempty(baseline)
        baseFinal = final_by_rollout(baseline.new_ip, "cum_infections");
        basePeakHidden = groupsummary(baseline.state, "rollout", "max", "hidden_IpIa");
        basePeakHidden = basePeakHidden(:, ["rollout", "max_hidden_IpIa"]);
        basePeakHidden = renamevars(basePeakHidden, "max_hidden_IpIa", "baseline_peak_hidden_infectious");

        policyFinal = finalInf;
        policyFinal = renamevars(policyFinal, "cum_infections", "policy_cum_infections");
        baseFinal = renamevars(baseFinal, "cum_infections", "baseline_cum_infections");
        mergedFinal = innerjoin(policyFinal, baseFinal, "Keys", "rollout");

        infAverted = mergedFinal.baseline_cum_infections - mergedFinal.policy_cum_infections;
        stats.infections_averted_mean = mean(infAverted, "omitnan");

        mergedPeak = innerjoin(peakHidden, basePeakHidden, "Keys", "rollout");
        phRed = mergedPeak.baseline_peak_hidden_infectious - mergedPeak.peak_hidden_infectious;
        stats.peak_hidden_infectious_reduction_mean = mean(phRed, "omitnan");

        if isfinite(stats.cum_testing_cost_mean) && stats.cum_testing_cost_mean >= minCost
            stats.infections_averted_per_1B_mean = stats.infections_averted_mean ./ stats.cum_testing_cost_mean .* 1e9;
        end
    end
end

function plot_action_sensitivity_dual_axis(ax, summary)
    cats = make_variant_r0_categories(summary);
    x = 1:height(summary);

    hold(ax, "on");

    yyaxis(ax, "left");
    Y = [summary.max_high_risk_coverage, summary.max_ag_screening, summary.max_pcr_intensity];
    b = bar(ax, x, Y, 0.78, "grouped");
    b(1).FaceColor = get_action_color("coverage");
    b(2).FaceColor = get_action_color("ag");
    b(3).FaceColor = get_action_color("pcr");
    ylabel(ax, "Action value");
    ylim(ax, [0, 1.05]);

    yyaxis(ax, "right");
    h = plot(ax, x, summary.min_retest_interval_days, ...
        "Color", get_action_color("retest"), ...
        "LineStyle", "-.", ...
        "LineWidth", 1.8, ...
        "Marker", "o", ...
        "MarkerSize", 4, ...
        "DisplayName", "Min testing period");
    ylabel(ax, "Minimum testing period (days)");
    ylim(ax, [0, evalin("base", "MAX_TEST_INTERVAL") + 0.5]);

    xticks(ax, x);
    xticklabels(ax, cats);
    xtickangle(ax, 35);
    grid(ax, "on");
    clean_axis(ax);

    legend(ax, [b(1), b(2), b(3), h], ...
        ["Maximum high-risk coverage", "Maximum antigen screening", "Maximum PCR intensity", "Minimum testing period"], ...
        "Location", "northwest", "Box", "off", "FontSize", 7);
end

function plot_testing_sensitivity_dual_axis(ax, summary)
    cats = make_variant_r0_categories(summary);
    x = 1:height(summary);

    hold(ax, "on");

    yyaxis(ax, "left");
    b1 = bar(ax, x - 0.12, summary.cum_pcr_tests_mean, 0.24, ...
        "FaceColor", [0.35 0.35 0.35], ...
        "EdgeColor", "none", ...
        "FaceAlpha", 0.50, ...
        "DisplayName", "PCR tests");
    ylabel(ax, "PCR tests");
    set_y_lower_zero(ax);

    yyaxis(ax, "right");
    b2 = bar(ax, x + 0.12, summary.cum_ag_tests_mean, 0.24, ...
        "FaceColor", [0.85 0.75 0.35], ...
        "EdgeColor", [0.45 0.38 0.12], ...
        "FaceAlpha", 0.70, ...
        "DisplayName", "Antigen tests");
    ylabel(ax, "Antigen tests");
    set_y_lower_zero(ax);

    if all(~isfinite(summary.cum_ag_tests_mean) | summary.cum_ag_tests_mean == 0)
        ylim(ax, [0, 1]);
    end

    xticks(ax, x);
    xticklabels(ax, cats);
    xtickangle(ax, 35);
    grid(ax, "on");
    clean_axis(ax);

    legend(ax, [b1, b2], ["PCR tests", "Antigen tests"], ...
        "Location", "northwest", "Box", "off", "FontSize", 7);
end

function plot_epidemic_sensitivity_dual_axis(ax, summary)
    cats = make_variant_r0_categories(summary);
    x = 1:height(summary);

    hold(ax, "on");

    yyaxis(ax, "left");
    b = bar(ax, x, summary.final_cumulative_infections_mean, 0.60, ...
        "FaceColor", [0.55 0.62 0.76], ...
        "EdgeColor", [0.25 0.25 0.25], ...
        "FaceAlpha", 0.65, ...
        "DisplayName", "Final cumulative infections");
    ylabel(ax, "Final cumulative infections");
    set_y_lower_zero(ax);

    yyaxis(ax, "right");
    h = plot(ax, x, summary.peak_hidden_infectious_mean, ...
        "Color", [0.15 0.15 0.15], ...
        "LineWidth", 1.8, ...
        "Marker", "v", ...
        "MarkerSize", 5, ...
        "DisplayName", "Peak hidden infectious cases");
    ylabel(ax, "Peak hidden infectious cases");
    set_y_lower_zero(ax);

    xticks(ax, x);
    xticklabels(ax, cats);
    xtickangle(ax, 35);
    grid(ax, "on");
    clean_axis(ax);

    legend(ax, [b, h], ["Final cumulative infections", "Peak hidden infectious cases"], ...
        "Location", "northwest", "Box", "off", "FontSize", 7);
end

function plot_rl_cost_outcome_paths(ax, summary)
    vars = evalin("base", "VARIANTS");

    hold(ax, "on");

    for i = 1:numel(vars)
        variant = vars(i);
        sub = summary(summary.variant == variant, :);
        sub = sortrows(sub, "R0");

        if height(sub) == 0
            continue;
        end

        xCostB = sub.cum_testing_cost_mean ./ 1e9;
        yAvert = sub.infections_averted_mean;

        c = get_variant_color(variant, 0);
        plot(ax, xCostB, yAvert, ...
            "Color", c, ...
            "LineWidth", 1.8, ...
            "Marker", "o", ...
            "MarkerFaceColor", c, ...
            "MarkerEdgeColor", darken(c, 0.25), ...
            "DisplayName", variant);

        for j = 1:height(sub)
            if isfinite(xCostB(j)) && isfinite(yAvert(j))
                text(ax, xCostB(j) * 1.02, yAvert(j), sprintf("%.1f", sub.R0(j)), ...
                    "FontSize", 7, "Color", [0.25 0.25 0.25]);
            end
        end
    end

    xlabel(ax, "Cumulative testing cost (billion cost units)");
    ylabel(ax, "Infections averted");
    grid(ax, "on");
    clean_axis(ax);
    legend(ax, "Location", "best", "Box", "off", "FontSize", 7);
end

function cats = make_variant_r0_categories(T)
    cats = strings(height(T), 1);
    for i = 1:height(T)
        cats(i) = sprintf("%s %.1f", short_variant_label(T.variant(i)), T.R0(i));
    end
end

%% =====================================================
% Supplementary reference policy performance for non-main R0
% ======================================================
function plot_supplement_policy_performance_reference(r0)
    vars = evalin("base", "VARIANTS");
    policies = evalin("base", "POLICIES");
    figDir = evalin("base", "FIG_DIR");
    csvDir = evalin("base", "CSV_DIR");

    lineMetricSpecs = {
        "hidden_EIpIa",       "Hidden infections";
        "active_infectious",  "Active infectious cases"
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

            for pp = 1:numel(policies)
                policy = policies(pp);
                result = load_scenario(variant, r0, policy, false);

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

                [summary, ~] = plot_mean_tci_color(ax, result.state, metricName, policy, "day", ...
                    color, lineWidth, showCI);

                summary = add_plot_metadata(summary, "SupplementPolicyPerformance", variant, r0, policy, metricLabel);
                csvLineParts = [csvLineParts; summary]; %#ok<AGROW>
            end

            if i == 1
                title(ax, metricLabel, "FontWeight", "normal");
            end
            if j == 1
                ylabel(ax, sprintf("%s\nNumber of cases", variant), ...
                    "Color", get_variant_color(variant, 0), "FontWeight", "bold");
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
            result = load_scenario(variant, r0, policy, false);
            if isempty(result)
                continue;
            end
            finalCum = final_by_rollout(result.new_ip, "cum_infections");
            row = summarize_policy_bar_row(variant, r0, policy, "Final cumulative infections", finalCum.cum_infections);
            barRows = [barRows; row]; %#ok<AGROW>
        end

        if height(barRows) > 0
            plot_policy_final_bar(axBar, barRows, policies);
            csvBarParts = [csvBarParts; barRows]; %#ok<AGROW>
        end

        if i == 1
            title(axBar, "Final cumulative infections", "FontWeight", "normal");
        end
        if i == numel(vars)
            xlabel(axBar, "Policy");
        end
        ylabel(axBar, "Number of cases");
        grid(axBar, "on");
        set_y_lower_zero(axBar);
        clean_axis(axBar);
    end

    lgdAx = nexttile(1);
    legend(lgdAx, "Location", "northwest", "Box", "off", "FontSize", 8);

    if height(csvLineParts) > 0
        writetable(csvLineParts, fullfile(csvDir, sprintf("Supplement_policy_performance_R0_%s_trajectories.csv", r0_tag(r0))));
    end
    if height(csvBarParts) > 0
        writetable(csvBarParts, fullfile(csvDir, sprintf("Supplement_policy_performance_R0_%s_final_cumulative.csv", r0_tag(r0))));
    end

    sgtitle(sprintf("Policy performance across variants, target R0 = %.1f", r0), "FontWeight", "normal");
    save_figure(fig, fullfile(figDir, sprintf("Supplement_policy_performance_R0_%s", r0_tag(r0))));
end

%% =====================================================
% Scenario loader
% ======================================================
function result = load_scenario(variant, r0, policy, required)
    if nargin < 4
        required = false;
    end

    stateCols = evalin("base", "STATE_COLS");
    newIpCols = evalin("base", "NEW_IP_COLS");
    nTestCols = evalin("base", "N_TEST_COLS");
    testingStepCols = evalin("base", "TESTING_STEP_COLS");
    testingEffortCols = evalin("base", "TESTING_EFFORT_COLS");
    daysInStep = evalin("base", "DAYS_IN_STEP");

    outDir = build_result_dir(variant, r0, policy);

    if ~exist(outDir, "dir")
        msg = sprintf("[Skipped] Missing directory: %s", outDir);
        if required
            error(msg);
        else
            fprintf("%s\n", msg);
            result = [];
            return;
        end
    end

    try
        stateArr = load_txt(outDir, "state_traj", variant, true);
        newIpArr = load_txt(outDir, "new_Ip", variant, true);
        nTestsArr = load_txt(outDir, "n_tests", variant, true);

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

        testingEffort = [];
        testingEffortArr = load_txt(outDir, "testing_effort_summary", variant, false);
        if ~isempty(testingEffortArr)
            testingEffort = txt_to_table(testingEffortArr, testingEffortCols, daysInStep);
        end

        actions = [];
        try
            actions = load_actions(outDir, variant);
        catch MEa
            fprintf("[Warning] Actions not loaded for %s, R0=%.1f, policy=%s: %s\n", ...
                variant, r0, policy, MEa.message);
            actions = [];
        end

        result = struct();
        result.variant = variant;
        result.R0 = r0;
        result.policy = policy;
        result.dir = outDir;
        result.state = state;
        result.new_ip = newIp;
        result.n_tests = nTests;
        result.testing_step = testingStep;
        result.testing_effort = testingEffort;
        result.actions = actions;

    catch ME
        fprintf("[Skipped] Failed to load %s, R0=%.1f, policy=%s: %s\n", ...
            variant, r0, policy, ME.message);
        result = [];
    end
end

%% =====================================================
% Metric preparation
% ======================================================
function T = prepare_state_metrics(T)
    T.hidden_EIpIa = T.E + T.Ip + T.Ia;
    T.hidden_IpIa = T.Ip + T.Ia;
    T.active_infectious = T.Ip + T.Ia + T.Is;
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

function T = build_efficiency_share_table(nTests, testingStep)
    T = testingStep;

    totalTestsByStep = nTests(:, ["rollout", "time", "day", "n_pcr", "n_ag"]);
    totalTestsByStep.actual_total_tests = totalTestsByStep.n_pcr + totalTestsByStep.n_ag;
    totalTestsByStep.pcr_share = totalTestsByStep.n_pcr ./ max(totalTestsByStep.actual_total_tests, 1e-12);
    totalTestsByStep.ag_share = totalTestsByStep.n_ag ./ max(totalTestsByStep.actual_total_tests, 1e-12);

    T = outerjoin(T, totalTestsByStep(:, ["rollout", "time", "actual_total_tests", "pcr_share", "ag_share"]), ...
        "Keys", ["rollout", "time"], ...
        "MergeKeys", true, ...
        "Type", "left");

    T.detected_per_test = T.detected_hidden ./ max(T.actual_total_tests, 1e-12);
end

%% =====================================================
% Trade-off metric builders
% ======================================================
function rolloutDf = build_rollout_metric_table_all_policies()
    vars = evalin("base", "VARIANTS");
    r0s = evalin("base", "TARGET_R0_VALUES");
    policies = evalin("base", "POLICIES");

    rolloutDf = table();

    for i = 1:numel(vars)
        for rr = 1:numel(r0s)
            for pp = 1:numel(policies)
                result = load_scenario(vars(i), r0s(rr), policies(pp), false);
                if isempty(result)
                    continue;
                end

                metrics = extract_rollout_metrics(result);
                rolloutDf = [rolloutDf; metrics]; %#ok<AGROW>
            end
        end
    end

    if height(rolloutDf) == 0
        error("No valid scenario results found.");
    end
end

function out = extract_rollout_metrics(result)
    state = result.state;
    newIp = result.new_ip;
    nTests = result.n_tests;
    testingStep = result.testing_step;

    cumInf = final_by_rollout(newIp, "cum_infections");
    cumCost = final_by_rollout(nTests, "cum_testing_cost");
    cumPcr = final_by_rollout(nTests, "cum_pcr");
    cumAg = final_by_rollout(nTests, "cum_ag");

    hiddenBurden = groupsummary(state, "rollout", "sum", "hidden_EIpIa");
    hiddenBurden = hiddenBurden(:, ["rollout", "sum_hidden_EIpIa"]);
    hiddenBurden = renamevars(hiddenBurden, "sum_hidden_EIpIa", "hidden_burden");

    activeBurden = groupsummary(state, "rollout", "sum", "active_infectious");
    activeBurden = activeBurden(:, ["rollout", "sum_active_infectious"]);
    activeBurden = renamevars(activeBurden, "sum_active_infectious", "active_burden");

    peakHiddenInf = groupsummary(state, "rollout", "max", "hidden_IpIa");
    peakHiddenInf = peakHiddenInf(:, ["rollout", "max_hidden_IpIa"]);
    peakHiddenInf = renamevars(peakHiddenInf, "max_hidden_IpIa", "peak_hidden_infectious");

    peakHiddenAll = groupsummary(state, "rollout", "max", "hidden_EIpIa");
    peakHiddenAll = peakHiddenAll(:, ["rollout", "max_hidden_EIpIa"]);
    peakHiddenAll = renamevars(peakHiddenAll, "max_hidden_EIpIa", "peak_hidden_EIpIa");

    out = innerjoin(cumInf, cumCost, "Keys", "rollout");
    out = innerjoin(out, cumPcr, "Keys", "rollout");
    out = innerjoin(out, cumAg, "Keys", "rollout");
    out = innerjoin(out, hiddenBurden, "Keys", "rollout");
    out = innerjoin(out, activeBurden, "Keys", "rollout");
    out = innerjoin(out, peakHiddenInf, "Keys", "rollout");
    out = innerjoin(out, peakHiddenAll, "Keys", "rollout");

    if ~isempty(testingStep)
        detected = final_by_rollout(testingStep, "cum_detected_hidden");
        out = outerjoin(out, detected, ...
            "Keys", "rollout", ...
            "MergeKeys", true, ...
            "Type", "left");
    else
        out.cum_detected_hidden = nan(height(out), 1);
    end

    totalTests = out.cum_pcr + out.cum_ag;
    out.pcr_fraction_total = out.cum_pcr ./ max(totalTests, 1e-12);
    out.detection_efficiency_total = out.cum_detected_hidden ./ max(totalTests, 1e-12);

    out.figure = repmat("All", height(out), 1);
    out.variant = repmat(result.variant, height(out), 1);
    out.R0 = repmat(result.R0, height(out), 1);
    out.policy = repmat(result.policy, height(out), 1);
end

function comparisonDf = add_no_testing_comparison_metrics(rolloutDf)
    policies = evalin("base", "POLICIES");

    baseline = rolloutDf(rolloutDf.policy == "No testing", :);
    baseline = baseline(:, [
        "variant", "R0", "rollout", ...
        "cum_infections", ...
        "hidden_burden", ...
        "active_burden", ...
        "peak_hidden_infectious", ...
        "peak_hidden_EIpIa"
    ]);

    baseline = renamevars(baseline, ...
        ["cum_infections", "hidden_burden", "active_burden", "peak_hidden_infectious", "peak_hidden_EIpIa"], ...
        ["baseline_cum_infections", "baseline_hidden_burden", "baseline_active_burden", ...
         "baseline_peak_hidden_infectious", "baseline_peak_hidden_EIpIa"]);

    comparisonDf = table();

    for pp = 1:numel(policies)
        policy = policies(pp);
        policyDf = rolloutDf(rolloutDf.policy == policy, :);

        merged = innerjoin(policyDf, baseline, "Keys", ["variant", "R0", "rollout"]);

        if height(merged) == 0
            continue;
        end

        merged.infections_averted = merged.baseline_cum_infections - merged.cum_infections;
        merged.hidden_burden_reduction = merged.baseline_hidden_burden - merged.hidden_burden;
        merged.active_burden_reduction = merged.baseline_active_burden - merged.active_burden;
        merged.peak_hidden_infectious_reduction = merged.baseline_peak_hidden_infectious - merged.peak_hidden_infectious;
        merged.peak_hidden_EIpIa_reduction = merged.baseline_peak_hidden_EIpIa - merged.peak_hidden_EIpIa;

        denom = merged.cum_testing_cost;
        denom(denom == 0) = NaN;
        merged.infections_averted_per_cost = merged.infections_averted ./ denom;
        merged.hidden_burden_reduction_per_cost = merged.hidden_burden_reduction ./ denom;

        comparisonDf = [comparisonDf; merged]; %#ok<AGROW>
    end
end

function summary = summarize_tradeoff_values(comparisonDf)
    metricList = [
        "cum_infections"
        "cum_testing_cost"
        "cum_pcr"
        "cum_ag"
        "cum_detected_hidden"
        "pcr_fraction_total"
        "detection_efficiency_total"
        "infections_averted"
        "hidden_burden_reduction"
        "active_burden_reduction"
        "peak_hidden_infectious_reduction"
        "peak_hidden_EIpIa_reduction"
        "infections_averted_per_cost"
        "hidden_burden_reduction_per_cost"
    ];

    [G, variant, R0, policy] = findgroups(comparisonDf.variant, comparisonDf.R0, comparisonDf.policy);

    summary = table();
    summary.figure = repmat("Figure5", max(G), 1);
    summary.variant = variant;
    summary.R0 = R0;
    summary.policy = policy;
    summary.n_rollouts = splitapply(@(x) numel(unique(x)), comparisonDf.rollout, G);

    for m = 1:numel(metricList)
        metric = metricList(m);
        if ~ismember(metric, string(comparisonDf.Properties.VariableNames))
            continue;
        end

        meanVals = splitapply(@(x) tci_mean_low_high_n(x, 1), comparisonDf.(metric), G);
        lowVals  = splitapply(@(x) tci_mean_low_high_n(x, 2), comparisonDf.(metric), G);
        highVals = splitapply(@(x) tci_mean_low_high_n(x, 3), comparisonDf.(metric), G);
        nVals    = splitapply(@(x) tci_mean_low_high_n(x, 4), comparisonDf.(metric), G);

        summary.(metric + "_mean") = meanVals;
        summary.(metric + "_low") = lowVals;
        summary.(metric + "_high") = highVals;
        summary.(metric + "_n") = nVals;
    end
end

function summary = add_cost_effectiveness_summary(summary)
    minCost = evalin("base", "MIN_COST_FOR_COST_EFFECTIVENESS");

    summary.infections_averted_per_1B_mean = nan(height(summary), 1);
    valid = isfinite(summary.infections_averted_mean) & ...
            isfinite(summary.cum_testing_cost_mean) & ...
            summary.cum_testing_cost_mean >= minCost;
    summary.infections_averted_per_1B_mean(valid) = ...
        summary.infections_averted_mean(valid) ./ summary.cum_testing_cost_mean(valid) .* 1e9;

    summary.hidden_burden_reduction_per_1B_mean = nan(height(summary), 1);
    valid = isfinite(summary.hidden_burden_reduction_mean) & ...
            isfinite(summary.cum_testing_cost_mean) & ...
            summary.cum_testing_cost_mean >= minCost;
    summary.hidden_burden_reduction_per_1B_mean(valid) = ...
        summary.hidden_burden_reduction_mean(valid) ./ summary.cum_testing_cost_mean(valid) .* 1e9;
end

%% =====================================================
% Action helpers
% ======================================================
function actions = load_actions(outDir, variant)
    actionCols = evalin("base", "ACTION_COLS");
    daysInStep = evalin("base", "DAYS_IN_STEP");
    maxInterval = evalin("base", "MAX_TEST_INTERVAL");

    arrInterp = load_txt(outDir, "actions_interpreted", variant, false);
    if ~isempty(arrInterp)
        actions = txt_to_table(arrInterp, actionCols, daysInStep);
        return;
    end

    arrRaw = load_txt(outDir, "actions_raw", variant, true);
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
% Plotting helpers
% ======================================================
function [summary, h] = plot_mean_tci_color(ax, T, valueCol, labelText, xCol, color, lineWidth, showCI)
    summary = summarize_by_time_tci(T, valueCol, xCol);
    h = plot_summary_line_ci(ax, summary, labelText, color, lineWidth, showCI, "-");
end

function h = plot_summary_line_ci(ax, summary, labelText, color, lineWidth, showCI, lineStyle)
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

function row = summarize_policy_bar_row(variant, r0, policy, metricName, values)
    [m, lo, hi] = t_based_mean_ci(values);
    row = table();
    row.figure = "SupplementPolicyPerformance";
    row.variant = variant;
    row.R0 = r0;
    row.policy = policy;
    row.metric = metricName;
    row.mean = m;
    row.low = lo;
    row.high = hi;
    row.n = sum(isfinite(values));
end

%% =====================================================
% CI and table helpers
% ======================================================
function [meanVal, lowVal, highVal] = t_based_mean_ci(vals)
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

function out = tci_mean_low_high_n(vals, whichVal)
    vals = double(vals(:));
    vals = vals(isfinite(vals));
    n = numel(vals);

    if n == 0
        valsOut = [NaN, NaN, NaN, 0];
    else
        [m, lo, hi] = t_based_mean_ci(vals);
        valsOut = [m, lo, hi, n];
    end

    out = valsOut(whichVal);
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
        [m, lo, hi] = t_based_mean_ci(vals);
        summary.mean(i) = m;
        summary.low(i) = lo;
        summary.high(i) = hi;
        summary.n(i) = sum(isfinite(vals));
    end
end

function summary = summarize_by_time_tci_nonnegative(T, valueCol, xCol)
    summary = summarize_by_time_tci(T, valueCol, xCol);
    summary.low = max(summary.low, 0);
    summary.high = max(summary.high, summary.mean);
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

%% =====================================================
% I/O helpers
% ======================================================
function outDir = build_result_dir(variant, r0, policy)
    resultRoot = evalin("base", "RESULT_ROOT");
    policyTags = evalin("base", "POLICY_TAGS");

    outDir = fullfile( ...
        resultRoot, ...
        sprintf("saved_rollout_%s_R0_%s_%s_100runs", ...
        variant_tag(variant), r0_tag(r0), policyTags(char(policy))) ...
    );
end

function tag = variant_tag(variant)
    tag = lower(char(variant));
end

function tag = r0_tag(r0)
    tag = strrep(sprintf("%.1f", r0), ".", "p");
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

function arr = load_txt(outDir, prefix, variant, required)
    path = latest_file(outDir, prefix, variant);

    if strlength(path) == 0
        if required
            error("No file found: prefix=%s, variant=%s, dir=%s", prefix, variant, outDir);
        else
            arr = [];
            return;
        end
    end

    arr = readmatrix(path);
    if isvector(arr)
        arr = reshape(arr, 1, []);
    end

    fprintf("[Loaded] %s, shape=(%d,%d)\n", path, size(arr, 1), size(arr, 2));
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

function save_figure(fig, pathWithoutExt)
    savefig(fig, pathWithoutExt + ".fig");
    exportgraphics(fig, pathWithoutExt + ".png", "Resolution", 300);
    exportgraphics(fig, pathWithoutExt + ".pdf", "ContentType", "vector");

    try
        exportgraphics(fig, pathWithoutExt + ".svg", "ContentType", "vector");
    catch
        warning("SVG export failed. FIG, PNG, and PDF were saved.");
    end

    fprintf("[Saved] %s.fig\n", pathWithoutExt);
    fprintf("[Saved] %s.png\n", pathWithoutExt);
    fprintf("[Saved] %s.pdf\n", pathWithoutExt);
    close(fig);
end

%% =====================================================
% Color helpers
% ======================================================
function c = get_r0_color(r0)
    if abs(r0 - 2.5) < 1e-12
        c = [0.45, 0.65, 0.85];
    elseif abs(r0 - 3.5) < 1e-12
        c = [0.93, 0.63, 0.28];
    elseif abs(r0 - 4.5) < 1e-12
        c = [0.82, 0.32, 0.28];
    else
        c = [0.60, 0.60, 0.60];
    end
end


function c = get_variant_r0_color(variant, r0)
    % Variant is encoded by hue and target R0 is encoded by shade intensity.
    % Lower transmission intensity is lighter; higher transmission intensity is darker.
    base = get_variant_color(variant, 0);

    if abs(r0 - 2.5) < 1e-12
        c = lighten(base, 0.42);
    elseif abs(r0 - 3.5) < 1e-12
        c = base;
    elseif abs(r0 - 4.5) < 1e-12
        c = darken(base, 0.26);
    else
        c = base;
    end
end

function c = get_r0_intensity_legend_color(r0)
    % Neutral legend swatches for the R0 intensity scale.
    base = [0.42, 0.42, 0.42];

    if abs(r0 - 2.5) < 1e-12
        c = lighten(base, 0.48);
    elseif abs(r0 - 3.5) < 1e-12
        c = lighten(base, 0.18);
    elseif abs(r0 - 4.5) < 1e-12
        c = darken(base, 0.24);
    else
        c = base;
    end
end

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

function c = get_action_color(actionName)
    actionName = string(actionName);
    switch actionName
        case "coverage"
            c = [0.25, 0.47, 0.72];
        case "pcr"
            c = [0.60, 0.40, 0.75];
        case "ag"
            c = [0.90, 0.65, 0.18];
        case "retest"
            c = [0.32, 0.32, 0.32];
        otherwise
            c = [0.55, 0.55, 0.55];
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

function cmap = make_pastel_autumn_cmap(n)
    raw = autumn(n);
    % Pastel version of MATLAB autumn: blend with white while retaining the
    % yellow-to-red ordering of the original colormap.
    pastelStrength = 0.58;
    cmap = (1 - pastelStrength) .* raw + pastelStrength .* ones(size(raw));
    cmap = min(max(cmap, 0), 1);
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

%% =====================================================
% Legend and label helpers
% ======================================================
function add_scatter_legend(ax, vars, policies, r0s)
    hold(ax, "on");
    h = gobjects(0);
    labels = strings(0);

    % Variant hue legend: blue, red, and yellow correspond to variants.
    for i = 1:numel(vars)
        c = get_variant_color(vars(i), 0);
        hh = scatter(ax, nan, nan, 62);
        hh.Marker = 'o';
        hh.MarkerFaceColor = c;
        hh.MarkerEdgeColor = darken(c, 0.25);
        hh.LineWidth = 1.0;
        h(end + 1) = hh; %#ok<AGROW>
        labels(end + 1) = vars(i); %#ok<AGROW>
    end

    % R0 intensity legend: shade intensity, not hue, represents target R0.
    for i = 1:numel(r0s)
        c = get_r0_intensity_legend_color(r0s(i));
        hh = scatter(ax, nan, nan, 60);
        hh.Marker = 'o';
        hh.MarkerFaceColor = c;
        hh.MarkerEdgeColor = darken(c, 0.25);
        h(end + 1) = hh; %#ok<AGROW>
        labels(end + 1) = sprintf("R0 %.1f shade", r0s(i)); %#ok<AGROW>
    end

    % Policy marker legend.
    for i = 1:numel(policies)
        marker = get_policy_marker(policies(i));
        hh = scatter(ax, nan, nan, 55);
        hh.Marker = marker;
        hh.MarkerFaceColor = [0.86 0.86 0.86];
        hh.MarkerEdgeColor = [0.25 0.25 0.25];
        h(end + 1) = hh; %#ok<AGROW>
        labels(end + 1) = policy_display_label(policies(i)); %#ok<AGROW>
    end

    legend(ax, h, labels, ...
        "Location", "eastoutside", ...
        "Box", "off", ...
        "FontSize", 7);
end



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
            label = "Half PCR/Ag";
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
            label = "Ag";
        case "Half PCR/Ag"
            label = "Half";
        case "No testing"
            label = "None";
        otherwise
            label = char(policy);
    end
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

function add_bar_value_labels(ax, x, values)
    vals = double(values(:));
    finiteVals = vals(isfinite(vals));
    if isempty(finiteVals)
        return;
    end

    yMax = max(finiteVals);
    if ~isfinite(yMax) || yMax <= 0
        yMax = 1;
    end
    yOffset = 0.025 * yMax;

    for i = 1:numel(vals)
        if ~isfinite(vals(i))
            continue;
        end
        yText = vals(i) + yOffset;
        if vals(i) < 0.03 * yMax
            yText = max(yText, 0.055 * yMax);
        end
        text(ax, x(i), yText, format_bar_value(vals(i)), ...
            "HorizontalAlignment", "center", ...
            "VerticalAlignment", "bottom", ...
            "FontSize", 6.8, ...
            "Color", [0.15 0.15 0.15], ...
            "Rotation", 0);
    end
end

function label = format_bar_value(v)
    if ~isfinite(v)
        label = "";
    elseif abs(v) < 10
        label = sprintf("%.1f", v);
    elseif abs(v) < 100
        label = sprintf("%.0f", v);
    else
        label = sprintf("%.0f", v);
    end
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
