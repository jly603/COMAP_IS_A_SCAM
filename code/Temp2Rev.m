% 清除工作区
clear; clc; close all;

%% 1. 参数设置 & 高分辨率数据生成
Tr_C = 25;              % 标准参考温度 (25°C)
Tr_K = 273.15 + Tr_C;   % 转换为开尔文
R0_ref = 0.05;          % 参考内阻 50 mOhm
B0_values = [2500, 3500, 4500]; % 三种不同的敏感度系数

% 1000个采样点保证曲线极其圆润
T_C = linspace(-20, 60, 1000); 
T_K = 273.15 + T_C;

%% 2. 现代配色方案
Color1 = [46, 134, 171] / 255;  % 海军蓝
Color2 = [246, 174, 45] / 255;  % 芥末黄
Color3 = [210, 97, 61] / 255;   % 陶土红
Colors = {Color1, Color2, Color3};

GrayText = [50, 50, 50] / 255;  % 字体深灰
GridColor = [200, 200, 200] / 255; % 网格浅灰

%% 3. 计算数据
R0_data = zeros(length(B0_values), length(T_K));
for i = 1:length(B0_values)
    R0_data(i, :) = R0_ref .* exp(B0_values(i) .* (1./T_K - 1./Tr_K));
end

%% 4. 绘图
fig = figure('Color', 'w', 'Position', [100, 100, 800, 600]); 
hold on;

% --- Layer 1: 背景高亮 "舒适温区" (0°C ~ 35°C) ---
ylims = [0, max(R0_data(3,:))*1000 * 1.05];
fill([0 35 35 0], [ylims(1) ylims(1) ylims(2) ylims(2)], ...
    [235, 242, 250]/255, 'EdgeColor', 'none', 'FaceAlpha', 0.6, ...
    'DisplayName', '常用工作温区');

% --- Layer 2: 坐标轴��网格 (修改重点：加黑框) ---
ax = gca;
ax.GridColor = GridColor;
ax.GridAlpha = 0.5;
ax.LineWidth = 1.5;      % 边框线条加粗，更有质感
ax.FontSize = 12;
ax.FontName = 'Arial';
ax.Color = 'none';

% [关键修改] 开启边框并设为纯黑
box on;                  
ax.XColor = [0 0 0];     % X轴和上下边框设为纯黑
ax.YColor = [0 0 0];     % Y轴和左右边框设为纯黑

grid on;

% --- Layer 3: 绘制主曲线 ---
lines = gobjects(3,1);
for i = 1:3
    lines(i) = plot(T_C, R0_data(i, :) * 1000, ...
        'Color', Colors{i}, ...
        'LineWidth', 3, ... 
        'DisplayName', ['B_0 = ' num2str(B0_values(i))]);
end

% --- Layer 4: 标注参考点 (25°C) ---
plot(Tr_C, R0_ref * 1000, 'o', ...
    'MarkerSize', 10, ...
    'MarkerFaceColor', [0.2 0.2 0.2], ...
    'MarkerEdgeColor', 'w', ...
    'LineWidth', 1.5, ...
    'HandleVisibility', 'off');

% 参考虚线
line([Tr_C Tr_C], [0, R0_ref * 1000], 'Color', [0.4 0.4 0.4], 'LineStyle', '--', 'LineWidth', 1.2);
line([-20 Tr_C], [R0_ref * 1000, R0_ref * 1000], 'Color', [0.4 0.4 0.4], 'LineStyle', '--', 'LineWidth', 1.2);

% 标注文本
text(Tr_C + 2, R0_ref * 1000 + 5, 'Reference (25°C)', ...
    'FontSize', 10, 'Color', 'k', 'FontName', 'Arial', 'FontWeight', 'bold');

%% 5. 装饰与标注
xlabel('Temperature (°C)', 'FontSize', 14, 'FontWeight', 'bold', 'Color', 'k');
ylabel('Internal Resistance R_0 (m\Omega)', 'FontSize', 14, 'FontWeight', 'bold', 'Color', 'k');

% 标题 (移回上方居中，适应有边框的风格)
title({'Effect of Temperature on Battery Internal Resistance'; '\rm\fontsize{12}\color[rgb]{0.4,0.4,0.4}Arrhenius Model Simulation'}, ...
    'FontSize', 16, 'FontWeight', 'bold', 'Color', 'k');

% 嵌入公式
formula_str = '$$ R_0(T) = R_{0|r} \cdot e^{ B_0 (\frac{1}{T} - \frac{1}{T_r}) } $$';
text(25, max(R0_data(3,:))*1000 * 0.75, formula_str, ...
    'Interpreter', 'latex', ...
    'FontSize', 17, ...
    'Color', [0.1 0.1 0.1]);

% 图例
lgd = legend([lines(3), lines(2), lines(1)], 'Location', 'NorthWest'); 
lgd.FontSize = 11;
lgd.EdgeColor = [0 0 0]; % 图例也加上黑框
lgd.LineWidth = 1;       % 图例框线宽度

% 调整坐标轴范围
xlim([-20 60]);
ylim([0, max(R0_data(3,:))*1000 * 1.05]);

% 保持刻度在框外 (TickDir) 看起来更整洁
set(gca, 'TickDir', 'in'); 