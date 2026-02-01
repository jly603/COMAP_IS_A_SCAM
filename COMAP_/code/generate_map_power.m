% =========================================================================
% 脚本名称：calc_power_elegant.m
% 功能：计算 P_total 并绘制全天功耗变化图（平滑曲线 + 现代配色版）
% =========================================================================
clear; clc; close all;

%% 1. 读取数据
if ~isfile('data.csv') || ~isfile('auto.csv')
    error('请先运行 generate_csv.m');
end

param = table2struct(readtable('data.csv'));
auto_data = readtable('auto.csv');

num_samples = height(auto_data);
% 原始时间轴 (15分钟间隔)
time_vector = datetime('today') + minutes(0 : 15 : (num_samples-1)*15)';

%% 2. 核心计��� (向量化 - 保持不变)

% --- Display ---
P_disp = auto_data.S_disp .* (param.P_disp_min + (param.P_disp_max - param.P_disp_min) .* (auto_data.B .^ param.GAMMA));

% --- CPU ---
P_cpu = param.P_cpu_idle + (param.P_cpu_max - param.P_cpu_idle) .* auto_data.U_cpu;

% --- Network ---
net_idle_lookup = [param.P_idle_none, param.P_idle_WiFi, param.P_idle_4G, param.P_idle_5G];
P_net_idle = net_idle_lookup(auto_data.P_idle_mode + 1)';
P_net = P_net_idle + param.alpha_DL .* auto_data.R_DL + param.alpha_UL .* auto_data.R_UL;

% --- Camera ---
P_cam = auto_data.S_cam .* param.P_cam_active;

% --- GPS ---
safe_Q = max(auto_data.Q_sat, 0.001);
P_gps = auto_data.S_gps .* param.P_gps_base .* (1 + param.LAMBDA .* (1 ./ safe_Q));

% --- Background ---
bg_lookup = [param.I_bg_save, param.I_bg_idle, param.I_bg_on];
current_I_bg = bg_lookup(auto_data.I_bg_mode + 1)';
P_bg = param.P_daemon + current_I_bg .* param.P_active_burst;

% --- Total ---
P_total = P_disp + P_cpu + P_net + P_cam + P_gps + P_bg;

%% 3. 结果保存
auto_data.P_total_mW = P_total;
writetable(auto_data, 'result_power_daily.csv');

%% 4. 专业绘图 (平滑曲线 + 现代配色)

% --- 4.1 数据平滑处理 (插值) ---
% 将时间转换为数值方便插值
x_orig = 1:num_samples;
% 创建更密集的时间轴 (例如：每1分钟一个点)
x_dense = linspace(1, num_samples, (num_samples-1)*15 + 1); 
time_dense = datetime('today') + minutes(0 : 1 : (num_samples-1)*15)';

% [关键修改] 提取时间部分，去掉日期
% 将 datetime 转换为 duration 类型，绘图时就不会自动附带日期了
time_plot = timeofday(time_dense); 

% 使用 'makima' 插值方法
interp_method = 'makima'; 

P_bg_smooth   = interp1(x_orig, P_bg,   x_dense, interp_method);
P_gps_smooth  = interp1(x_orig, P_gps,  x_dense, interp_method);
P_net_smooth  = interp1(x_orig, P_net,  x_dense, interp_method);
P_cpu_smooth  = interp1(x_orig, P_cpu,  x_dense, interp_method);
P_disp_smooth = interp1(x_orig, P_disp, x_dense, interp_method);
P_total_smooth= interp1(x_orig, P_total,x_dense, interp_method);

% 确保插值后没有负数
P_bg_smooth(P_bg_smooth<0) = 0;
P_gps_smooth(P_gps_smooth<0) = 0;
P_net_smooth(P_net_smooth<0) = 0;
P_cpu_smooth(P_cpu_smooth<0) = 0;
P_disp_smooth(P_disp_smooth<0) = 0;
P_total_smooth(P_total_smooth<0) = 0;

% --- 4.2 定义现代配色方案 (RGB) ---
color_bg   = [0.85, 0.85, 0.85]; % 浅灰
color_gps  = [0.47, 0.67, 0.53]; % 鼠尾草绿
color_net  = [0.39, 0.58, 0.93]; % 矢车菊蓝
color_cpu  = [0.96, 0.60, 0.45]; % 珊瑚橙
color_disp = [0.98, 0.82, 0.30]; % 暖黄
color_line = [0.20, 0.20, 0.20]; % 深灰

figure('Name', 'Daily Power Profile (Elegant)', 'Color', 'w', 'Position', [100, 100, 1000, 700]);

% --- 上图：堆叠面积图 (Stack Area) ---
subplot(2,1,1);
hold on;
% 准备堆叠数据
area_data_smooth = [P_bg_smooth', P_gps_smooth', P_net_smooth', P_cpu_smooth', P_disp_smooth'];
% [修改] 使用 time_plot 而不是 time_dense
h_area = area(time_plot, area_data_smooth);

% 应用配色并美化
colors = {color_bg, color_gps, color_net, color_cpu, color_disp};
for i = 1:5
    h_area(i).FaceColor = colors{i};
    h_area(i).EdgeColor = 'white';    
    h_area(i).FaceAlpha = 0.85;      
end

% 装饰
title('Stacked Distribution', 'FontSize', 18, 'FontWeight', 'bold', 'Color', [0.2 0.2 0.2]);
ylabel('P/mW', 'FontSize', 11);
leg = legend({'Bg', 'GPS', 'Net', 'CPU', 'Disp'}, ...
       'Location', 'NorthWest', 'Orientation', 'horizontal');
leg.EdgeColor = 'none'; 
leg.Color = 'none';     

grid on;
ax = gca;
ax.GridColor = [0.8 0.8 0.8]; 
ax.GridAlpha = 0.4;
ax.LineWidth = 1.2;
ax.FontSize = 10;
% [新增] 设置四周黑框
ax.Box = 'on';
ax.XColor = 'k'; % 黑色 X 轴线
ax.YColor = 'k'; % 黑色 Y 轴线

xlim([time_plot(1), time_plot(end)]); % [修改] 使用 time_plot
xtickformat('hh:mm'); % [修改] 格式化 duration

% --- 下图：总功耗曲线 (Line Plot) ---
subplot(2,1,2);
hold on;

% 创建填充多边形数据
% [修改] 使用 time_plot
x_fill = [time_plot; flipud(time_plot)];
y_fill = [P_total_smooth'; zeros(size(P_total_smooth'))];
fill(x_fill, y_fill, color_net, 'FaceAlpha', 0.1, 'EdgeColor', 'none'); 

% 绘制主曲线
% [修改] 使用 time_plot
plot(time_plot, P_total_smooth, 'LineWidth', 2.5, 'Color', '#D95319'); 

% ================= [新增部分] 添加均值红色虚线 =================
mean_val = mean(P_total);
yline(mean_val, '--r', sprintf('Mean: %.1f mW', mean_val), ...
    'LineWidth', 1.5, ...
    'LabelHorizontalAlignment', 'left', ...
    'LabelVerticalAlignment', 'bottom', ...
    'FontSize', 10, ...
    'Color', 'r'); 
% =============================================================

title('Total Power Consumption', 'FontSize', 18, 'FontWeight', 'bold', 'Color', [0.2 0.2 0.2]);
ylabel('P/mW', 'FontSize', 11);
xlabel('Time for the Day (24h)', 'FontSize', 11);

grid on;
ax2 = gca;
ax2.GridColor = [0.8 0.8 0.8];
ax2.GridAlpha = 0.4;
ax2.LineWidth = 1.2;
ax2.FontSize = 10;
% [新增] 设置四周黑框
ax2.Box = 'on';
ax2.XColor = 'k'; % 黑色 X 轴线
ax2.YColor = 'k'; % 黑色 Y 轴线

xlim([time_plot(1), time_plot(end)]); % [修改] 使用 time_plot
xtickformat('hh:mm'); % [修改] 格式化 duration

% 添加峰值标注
[max_p, idx] = max(P_total_smooth);
if max_p > 0
    % [修改] 使用 time_plot
    plot(time_plot(idx), max_p, 'o', 'MarkerSize', 6, 'MarkerFaceColor', 'w', 'MarkerEdgeColor', '#D95319', 'LineWidth', 2);
    text(time_plot(idx), max_p + max_p*0.05, sprintf('Max: %.0f mW', max_p), ...
        'HorizontalAlignment', 'center', 'FontSize', 9, 'Color', '#D95319', 'FontWeight', 'bold');
end

hold off;