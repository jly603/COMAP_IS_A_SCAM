clear; clc; close all;

%% 1. 导入原始测量数据 (根据您提供的 CSV)
% SOC (百分比)
SOC_pct = [0.0, 2.0, 4.0, 6.0, 8.0, 10.0, 12.0, 14.0, 16.0, 18.0, ...
           20.0, 22.0, 24.0, 26.0, 28.0, 30.0, 32.0, 34.0, 36.0, 38.0, ...
           40.0, 42.0, 44.0, 46.0, 48.0, 50.0, 52.0, 54.0, 56.0, 58.0, ...
           60.0, 62.0, 64.0, 66.0, 68.0, 70.0, 72.0, 74.0, 76.0, 78.0, ...
           80.0, 82.0, 84.0, 86.0, 88.0, 90.0, 92.0, 94.0, 96.0, 98.0, 100.0]';

% OCV (电压 V)
OCV_meas = [3.0000, 3.1254, 3.2185, 3.2956, 3.3612, 3.4140, 3.4568, 3.4912, 3.5205, 3.5461, ...
            3.5692, 3.5902, 3.6095, 3.6275, 3.6442, 3.6601, 3.6753, 3.6899, 3.7041, 3.7179, ...
            3.7314, 3.7447, 3.7578, 3.7708, 3.7837, 3.7966, 3.8095, 3.8225, 3.8357, 3.8491, ...
            3.8628, 3.8768, 3.8913, 3.9063, 3.9219, 3.9382, 3.9554, 3.9734, 3.9924, 4.0125, ...
            4.0336, 4.0556, 4.0784, 4.1017, 4.1251, 4.1481, 4.1699, 4.1895, 4.2057, 4.2168, 4.2200]';

% 将 SOC 转换为 0-1 区间 (建模通常用 0-1)
SOC_norm = SOC_pct / 100;

%% 2. 进行多项式拟合
% 使用 6 阶多项式拟合数据，以复刻图片中的“波浪”残差特征
% 如果用原来的 5 阶或更低，误差会更大；6 阶通常能把误差控制在 mV 级别
poly_order = 6;
p_coeffs = polyfit(SOC_norm, OCV_meas, poly_order);

% 计算拟合出来的电压值
OCV_model = polyval(p_coeffs, SOC_norm);

%% 3. 计算残差 (Residual Analysis)
% 真实值 - 拟合值
residual_V = OCV_meas - OCV_model; 

% 转换为毫伏 (mV)
residual_mV = residual_V * 1000;

% 计算标准差 (RMSE 也可以，但图片用的是 Sigma)
sigma_val = std(residual_mV);
rmse_val = rms(residual_mV);

fprintf('拟合阶数: %d\n', poly_order);
fprintf('残差标准差 (Sigma): %.4f mV\n', sigma_val);
fprintf('均方根误差 (RMSE):  %.4f mV\n', rmse_val);

%% 4. 绘图 (复刻风格)
figure('Color', 'w', 'Position', [300, 200, 700, 600]);

% 创建坐标轴对象
ax = gca;

% --- 样式设置 ---
% 设置背景颜色 (淡蓝色)
set(ax, 'Color', [0.92, 0.95, 0.98]); 
hold on;

% 1. 绘制零刻度线 (基准线)
yline(0, 'k-', 'LineWidth', 1.2); 

% 2. 绘制残差散点
% 颜色: 钢蓝色 [0.2, 0.4, 0.6]
scatter(SOC_norm, residual_mV, 60, [0.25, 0.45, 0.65], 'filled', ...
    'MarkerEdgeColor', [0.2, 0.4, 0.6], ...
    'MarkerFaceAlpha', 0.8); % 稍微透明一点更有质感

% --- 装饰设置 ---
grid on;
box on;

% 设置网格线样式
ax.GridAlpha = 0.4;     % 网格透明度
ax.LineWidth = 1.2;     % 边框粗细
ax.FontSize = 12;       % 坐标轴字号
ax.FontName = 'Times New Roman'; % 字体 (类似学术论文)

% 标签与标题
xlabel('SOC', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('拟合残差 (mV)', 'FontSize', 14, 'FontWeight', 'bold');

% 动态标题 (显示计算出的 Sigma)
title(sprintf('(c) OCV 残差分析 (\\sigma = %.2f mV)', sigma_val), ...
    'FontSize', 16, 'FontWeight', 'bold', 'Interpreter', 'tex');

% 坐标轴范围限制 (让图看起来紧凑)
xlim([0 1]);
% 根据数据的最大误差自动调整Y轴范围，稍微留点余量
y_limit = max(abs(residual_mV)) * 1.2; 
ylim([-y_limit, y_limit]);

hold off;

%% 5. (可选) 输出拟合参数供后续使用
fprintf('\n拟合得到的系数 (可以直接复制回 SOCsolution.m 使用):\n');
fprintf('coeffs = [');
fprintf('%.4f; ', p_coeffs);
fprintf('];\n');