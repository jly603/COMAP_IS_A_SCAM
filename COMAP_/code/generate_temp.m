clear; clc; close all;

%% 1. 参数设置
% ---------------------------------------------------------
N = 96;                         % 数据点总数
dt_hours = 24 / N;              % 时间间隔 (小时) -> 0.25小时 (15分钟)
t_hours = (0:N-1)' * dt_hours;  % 时间轴: 0.00, 0.25, 0.50 ... 23.75

% 温度范围设定 (寒冷天气)
T_min = -5;   % 夜间最低温
T_max = 10;   % 白天最高温

%% 2. 温度生成算法
% ---------------------------------------------------------
T_mean = (T_max + T_min) / 2;
T_amp  = (T_max - T_min) / 2;

% 使用余弦函数模拟日温差
% 假设最高��出现在下午 14:00 (t=14)
% T ~ cos(2*pi * (t - 14) / 24)
T_base = T_mean + T_amp * cos(2 * pi * (t_hours - 14) / 24);

% 添加随机扰动 (范围约为 +/- 0.5度)
rng(100); % 固定随机种子
noise = 0.5 * randn(N, 1); 

T_final = T_base + noise;

%% 3. 导出与绘图
% ---------------------------------------------------------
filename = 'Temp_data.csv';
writematrix(T_final, filename);

fprintf('生成完成: %s\n', filename);
fprintf('数据点数: %d\n', length(T_final));
fprintf('时间间隔: %.2f 分钟\n', dt_hours * 60);

% 绘图预览
figure('Color', 'w', 'Position', [100, 100, 800, 400]);
plot(t_hours, T_final, 'o-', 'LineWidth', 1.5, 'MarkerSize', 4);
yline(0, 'r--', '0°C 结冰线');
xlabel('时间 (小时)');
ylabel('温度 (°C)');
title('24小时环境温度 (96个采样点)');
grid on;
xlim([0 24]);