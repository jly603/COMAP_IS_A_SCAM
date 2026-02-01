% =========================================================================
% Script Name: Visualize_OCV_Relations.m
% Description: 深度解剖 OCV-SOC 曲线与内阻、极化及端电压的关系
% =========================================================================
clear; clc; close all;

%% 1. 参数定义 (保持与原代码一致)
% ---------------------------------------------------------
% OCV - SOC 拟合系数 (a0 ... a5)
coeffs_raw = [3.31; 2.38; -9.55; 21.02; -20.32; 7.34];
p_ocv = flipud(coeffs_raw); % 翻转为 polyval 可用的格式

% 电池物理参数
R0 = 0.04;          % 欧姆内阻 (Ohm)
Rp = 0.02;          % 极化电阻 (Ohm)
% 假设一个恒定电流来演示压降关系 (放电)
I_discharge = 10.0; % 10 Amps

%% 2. 生成分析数据
% ---------------------------------------------------------
% 生成从 0% 到 100% SOC 的序列
soc_axis = linspace(0, 1, 1000); 

% A. 计算基础 OCV 曲线
V_ocv = polyval(p_ocv, soc_axis);

% B. 计算各部分电压损耗 (假设稳态放电)
% 欧姆压降 (V_ohm) = I * R0
V_ohm_drop = I_discharge * R0 * ones(size(soc_axis));

% 极化电压 (V_pol) = I * Rp (稳态最大值)
V_pol_drop = I_discharge * Rp * ones(size(soc_axis));

% C. 计算负载端电压 (Terminal Voltage)
% V_term = V_ocv - V_ohm - V_pol
V_term = V_ocv - V_ohm_drop - V_pol_drop;

%% 3. 高级绘图：OCV 结构解剖图
% ---------------------------------------------------------
figure('Color', 'w', 'Position', [200, 100, 900, 700]);

% --- 配色方案 ---
color_ocv  = [0.2, 0.2, 0.2];      % 深灰 (基准)
color_term = [0.85, 0.33, 0.1];    % 橙色 (最终输出)
color_ohm  = [0.2, 0.6, 0.8];      % 蓝色 (欧姆损耗)
color_pol  = [0.4, 0.8, 0.4];      % 绿色 (极化损耗)

% 创建主坐标轴
ax = axes;
hold on;

% 1. 绘制最上层：开路电压 OCV
plot(soc_axis*100, V_ocv, 'LineWidth', 2.5, 'Color', color_ocv);

% 2. 绘制最下层：负载电压 V_term
plot(soc_axis*100, V_term, 'LineWidth', 2.5, 'Color', color_term);

% 3. 使用填充区展示“损耗去哪了”
% 区域 1: 欧姆损耗 (在 OCV 和 OCV-R0*I 之间)
V_after_ohm = V_ocv - V_ohm_drop;
fill([soc_axis*100, fliplr(soc_axis*100)], [V_ocv, fliplr(V_after_ohm)], ...
    color_ohm, 'FaceAlpha', 0.3, 'EdgeColor', 'none');

% 区域 2: 极化损耗 (在 V_after_ohm 和 V_term 之间)
fill([soc_axis*100, fliplr(soc_axis*100)], [V_after_ohm, fliplr(V_term)], ...
    color_pol, 'FaceAlpha', 0.3, 'EdgeColor', 'none');

% --- 标注与美化 ---
grid on;
xlabel('State of Charge (SOC, %)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Voltage (V)', 'FontSize', 12, 'FontWeight', 'bold');
title(sprintf('Relationship: OCV vs. Terminal Voltage (@ %.1f A Discharge)', I_discharge), ...
    'FontSize', 14);
xlim([0, 100]);

% 添加文本箭头标注，解释每一层
% 找一个中间点 (SOC=50%)
idx_mid = 500; 
x_pos = 50;
y_ocv = V_ocv(idx_mid);
y_ohm = V_after_ohm(idx_mid);
y_term = V_term(idx_mid);

% OCV 标注
text(x_pos, y_ocv + 0.05, 'Open Circuit Voltage (OCV)', 'Color', color_ocv, 'FontWeight', 'bold');

% 欧姆损耗标注
text(x_pos + 5, (y_ocv + y_ohm)/2, sprintf('Ohmic Drop (I \\times R_0 = %.2f V)', I_discharge*R0), ...
    'Color', [0.1 0.4 0.6], 'FontSize', 10);

% 极化损耗标注
text(x_pos + 5, (y_ohm + y_term)/2, sprintf('Polarization (I \\times R_p = %.2f V)', I_discharge*Rp), ...
    'Color', [0.2 0.5 0.2], 'FontSize', 10);

% 端电压标注
text(x_pos, y_term - 0.05, 'Terminal Voltage (V_{term})', 'Color', color_term, 'FontWeight', 'bold');

legend({'OCV Curve (Ideal)', 'Terminal Voltage (Actual)', 'Ohmic Loss', 'Polarization Loss'}, ...
    'Location', 'Southeast');

hold off;

%% 4. 补充图：导数分析 (dOCV/dSOC)
% ---------------------------------------------------------
% 这个图非常重要，它展示了 OCV 曲线的“平坦程度”。
% 在平坦区域 (斜率小)，电压对 SOC 不敏感，SOC 估算最难。
figure('Color', 'w', 'Position', [1150, 100, 600, 400]);

% 计算导数 (使用差分)
dOCV_dSOC = diff(V_ocv) ./ diff(soc_axis);
soc_mid = soc_axis(1:end-1) + diff(soc_axis)/2;

yyaxis left
plot(soc_axis*100, V_ocv, 'LineWidth', 2, 'Color', color_ocv);
ylabel('OCV (V)', 'FontWeight', 'bold');
ylim([2.5 4.5]);

yyaxis right
plot(soc_mid*100, dOCV_dSOC, 'LineWidth', 1.5, 'Color', 'm', 'LineStyle', '-.');
ylabel('Slope (dOCV / dSOC)', 'FontWeight', 'bold');
ylim([0 3]); % 限制范围以便观察

title('Sensitivity Analysis: OCV Slope');
xlabel('SOC (%)');
grid on;
legend({'OCV Curve', 'Slope (Sensitivity)'}, 'Location', 'North');

% 标注平坦区
text(30, 0.2, '\leftarrow Flat Region (Hard to estimate SOC)', 'FontSize', 9, 'Color', 'm');