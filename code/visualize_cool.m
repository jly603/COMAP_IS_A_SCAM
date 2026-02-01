% =========================================================================
% 脚本名称：visualize_paper.m
% 功能：生成符合学术发表标准的论文配图 (Paper-Ready Visualization)
% 前置条件：工作区中必须包含 P_total, P_disp, P_cpu 等计算结果变量
% =========================================================================

%% 1. 准备数据与配色
% 汇总各模块数据 (无相机版)
y_matrix = [P_disp, P_cpu, P_net, P_gps, P_bg];
module_names = {'Display', 'CPU', 'Network', 'GPS', 'Background'};
total_energy_per_module = sum(y_matrix, 1); 

% 定义学术配色 (基于 RGB，柔和且区分度高)
% 顺序：蓝色(Disp), 橙色(CPU), 黄色(Net), 紫色(GPS), 绿色(BG)
colors = [
    0.00, 0.45, 0.74; % Blue
    0.85, 0.33, 0.10; % Orange
    0.93, 0.69, 0.13; % Yellow-Gold
    0.49, 0.18, 0.56; % Purple
    0.47, 0.67, 0.19; % Green
];

% 创建图形窗口 (设置默认尺寸，接近 A4 纸半页宽度)
fig = figure('Name', 'Paper Ready Plot', 'Color', 'w', ...
    'Units', 'centimeters', 'Position', [2, 2, 18, 12]); % 18cm x 12cm

% 使用 TiledLayout 布局 (更紧凑，减少留白)
t = tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

%% 2. 图表 A：堆叠面积图 (时间序列分析)
ax1 = nexttile([1, 2]); % 跨两列
h_area = area(y_matrix);

% 设置颜色与线型
for i = 1:5
    h_area(i).FaceColor = colors(i, :);
    h_area(i).EdgeColor = 'none'; % 去掉边缘线，使图表更干净
    h_area(i).FaceAlpha = 0.8;    % 轻微透明，便于观察叠加关系
end

hold on;
% 添加总功耗曲线 (细黑线勾勒轮廓)
plot(P_total, 'k-', 'LineWidth', 1.0);

% 坐标轴��置 (Box on, Grid on)
set(ax1, 'Box', 'on', 'LineWidth', 1.0, 'FontSize', 10, 'FontName', 'Arial');
grid(ax1, 'on');
ax1.Layer = 'top'; % 网格线置于图层下方

xlim([1, length(P_total)]);
ylabel('Power (mW)', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('Time Sample (t)', 'FontSize', 11, 'FontWeight', 'bold');
title('(a) Real-time Power Consumption Profile', 'FontSize', 12, 'FontWeight', 'normal');

% 图例设置 (放在图表外部或内部空白处)
legend(module_names, 'Location', 'eastoutside', 'Box', 'off', 'FontSize', 9);

%% 3. 图表 B：总能耗占比 (饼图)
ax2 = nexttile;
p = pie(ax2, total_energy_per_module);

% 美化饼图
cnt = 1;
for i = 1:2:length(p)
    p(i).FaceColor = colors(cnt, :);
    p(i).EdgeColor = 'w';       % 白色分割线
    p(i).LineWidth = 1.5;
    
    % 设置文字标签
    p(i+1).FontSize = 9;
    p(i+1).FontName = 'Arial';
    p(i+1).Color = 'k';
    
    % 如果占比小于 5%，隐藏标签防止重叠
    if total_energy_per_module(cnt)/sum(total_energy_per_module) < 0.05
        p(i+1).String = ''; 
    end
    cnt = cnt + 1;
end
title('(b) Total Energy Breakdown', 'FontSize', 11, 'FontWeight', 'normal', 'FontName', 'Arial');

%% 4. 图表 C：概率密度分布 (直方图/核密度)
ax3 = nexttile;
h_hist = histogram(P_total, 20, 'Normalization', 'probability');

% 样式设置
h_hist.FaceColor = [0.5 0.5 0.5]; % 中性灰
h_hist.EdgeColor = 'w';
h_hist.FaceAlpha = 0.7;

% 添加平均线
avg_val = mean(P_total);
xline(avg_val, '--r', 'LineWidth', 1.5);
text(avg_val, max(h_hist.Values)*0.9, sprintf(' Mean: %.0f mW', avg_val), ...
    'Color', 'r', 'FontSize', 9, 'FontName', 'Arial');

% 坐标轴设置
set(ax3, 'Box', 'on', 'LineWidth', 1.0, 'FontSize', 10, 'FontName', 'Arial');
grid(ax3, 'on');
xlabel('Power (mW)', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Probability', 'FontSize', 11, 'FontWeight', 'bold');
title('(c) Power Distribution', 'FontSize', 11, 'FontWeight', 'normal');

%% 5. 导出设置 (可选)
% 如果需要保存为高清图片，取消下面这行的注释
% exportgraphics(fig, 'Power_Analysis_Paper.png', 'Resolution', 300);
fprintf('学术风格图表已生成。\n');