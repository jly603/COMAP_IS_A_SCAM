clear; clc; close all;

%% 1. 参数设置
% ---------------------------------------------------------
dt = 60;             % 时间步长 (s)
C_nominal_Ah = 12.0; % 电池【标称】容量 (Ah)
C_nominal_Coulomb = C_nominal_Ah * 3600; 

% 电池内阻与极化参数
R0 = 0.04;          % 欧姆内阻 (Ohm)
Rp = 0.02;          % 极化电阻 (Ohm)
Cp = 2000;           % 极化电容 (F)

% --- 温度修正参数 ---
T_ref = 25.0;       % 参考温度 (摄氏度)
alpha_temp = 0.0002; % 温度敏感系数

% 初始状态
SOC_init = 1.0;     
Up_init = 0;        

% OCV - SOC 拟合系数
coeffs_raw = [3.31; 2.38; -9.55; 21.02; -20.32; 7.34];
p_ocv = flipud(coeffs_raw); 

%% 2. 加载数据
% ---------------------------------------------------------
% 2.1 加载功率
if isfile('P_total_only.csv')
    P_data = readmatrix('P_total_only.csv');
    P_seq = P_data(:, 1)/1000; 
else
    % 默认：生成随机功率
    P_seq = 2 + 13 * rand(100, 1); 
end
N = length(P_seq);

% 2.2 加载温度
if isfile('Temp_data.csv')
    T_data = readmatrix('Temp_data.csv');
    T_seq = T_data(:, 1);
    if length(T_seq) < N, error('温度数据长度不够'); end
else
    T_seq = linspace(25, 25, N)'; 
end

%% 3. 初始化
% ---------------------------------------------------------
SOC_hist = zeros(N, 1);
I_hist = zeros(N, 1);
V_term_hist = zeros(N, 1);
Up_hist = zeros(N, 1);
C_eff_hist = zeros(N, 1);
Total_Endurance_hist = zeros(N, 1); % [修改] 改为记录总续航时间

current_SOC = SOC_init;
current_Up = Up_init;

% 功率滑动平均窗口
window_size = 15; 
P_buffer = zeros(window_size, 1);

%% 4. 核心循环
% ---------------------------------------------------------
for k = 1:N
    P_now = P_seq(k);
    T_now = T_seq(k);
    
    % --- 功率滑动窗口更新 ---
    P_buffer = [P_buffer(2:end); P_now];
    if k < window_size
        P_avg = mean(P_seq(1:k));
    else
        P_avg = mean(P_buffer);
    end
    P_avg = max(P_avg, 0.1); 
    
    % --- 温度修正 ---
    if T_now < T_ref
        mu = 1 - alpha_temp * (T_ref - T_now)^2;
        mu = max(0.1, mu);
    else
        mu = 1.0;
    end
    C_eff_now = C_nominal_Coulomb * mu;
    
    % --- OCV 计算 ---
    V_ocv = polyval(p_ocv, current_SOC);
    
    % --- 电流求解 ---
    delta = (V_ocv - current_Up)^2 - 4 * R0 * P_now;
    if delta < 0, error('Power too high at step %d', k); end
    I_now = ((V_ocv - current_Up) - sqrt(delta)) / (2 * R0);
    
    % --- [核心修改] 预测总续航时间 ---
    % 1. 计算过去已经用的时间 (小时)
    time_elapsed = k * dt / 3600;
    
    % 2. 计算还能用多久 (小时)
    I_avg_est = P_avg / V_ocv; 
    C_remaining = C_eff_now * current_SOC;
    time_remaining = (C_remaining / I_avg_est) / 3600;
    
    % 3. 总续航 = 过去 + 未来
    total_endurance = time_elapsed + time_remaining;
    
    % --- 状态更新 ---
    V_term = V_ocv - I_now * R0 - current_Up;
    tau = Rp * Cp;
    exp_factor = exp(-dt / tau);
    current_Up = current_Up * exp_factor + I_now * Rp * (1 - exp_factor);
    
    dSOC = -I_now / C_eff_now;
    current_SOC = current_SOC + dSOC * dt;
    current_SOC = max(0, min(1, current_SOC));
    
    % --- 存储数据 ---
    SOC_hist(k) = current_SOC;
    I_hist(k) = I_now;
    V_term_hist(k) = V_term;
    Up_hist(k) = current_Up;
    C_eff_hist(k) = C_eff_now / 3600;
    Total_Endurance_hist(k) = total_endurance; % [修改] 存储总时间
end

%% 5. 可视化结果
% ---------------------------------------------------------
t_hours = (0:N-1)' * dt / 3600; 
t_max = max(t_hours); 

% 平滑处理
N_smooth = (N-1) * 10 + 1;
t_smooth = linspace(min(t_hours), max(t_hours), N_smooth);

P_smooth      = interp1(t_hours, P_seq,       t_smooth, 'pchip');
T_smooth      = interp1(t_hours, T_seq,       t_smooth, 'pchip');
I_smooth      = interp1(t_hours, I_hist,      t_smooth, 'pchip');
C_eff_smooth  = interp1(t_hours, C_eff_hist,  t_smooth, 'pchip');
SOC_smooth    = interp1(t_hours, SOC_hist,    t_smooth, 'pchip');
% [修改] 平滑总续航数据
Endurance_smooth = interp1(t_hours, Total_Endurance_hist, t_smooth, 'pchip');

% 配色
color_power = [0.2, 0.4, 0.7];
color_temp  = [0.85, 0.33, 0.1];
color_curr  = [0.3, 0.3, 0.3];
color_cap   = [0.6, 0.4, 0.7];
color_soc   = [0.0, 0.65, 0.55];
color_time  = [0.8, 0.2, 0.4]; 

hFig = figure('Color', 'w', 'Position', [150, 100, 1000, 850]);
axis_font = 'Helvetica'; font_size = 11;

% === 子图 1: 输入条件 ===
ax1 = subplot(3,1,1);
yyaxis left; 
area(t_smooth, P_smooth, 'FaceColor', color_power, 'FaceAlpha', 0.15, 'EdgeColor', color_power);
ylabel('Power (W)', 'FontWeight', 'bold');
ax1.YColor = color_power;

yyaxis right; 
plot(t_smooth, T_smooth, '-', 'Color', color_temp, 'LineWidth', 2); 
ylabel('Temp (°C)', 'FontWeight', 'bold');
ax1.YColor = color_temp;
title('Input Conditions', 'FontSize', 13);
grid on; ax1.GridAlpha = 0.15; 
xlim([0 t_max]); box off;

% === 子图 2: 电池响应 ===
ax2 = subplot(3,1,2);
yyaxis left
plot(t_smooth, I_smooth, '-', 'Color', color_curr, 'LineWidth', 1.5);
ylabel('Current (A)', 'FontWeight', 'bold');
ax2.YColor = color_curr; 
yyaxis right
plot(t_smooth, C_eff_smooth, '-', 'Color', color_cap, 'LineWidth', 2);
ylabel('Capacity (Ah)', 'FontWeight', 'bold');
ax2.YColor = color_cap; 
title('Battery Response', 'FontSize', 13);
grid on; ax2.GridAlpha = 0.15; 
xlim([0 t_max]); box off;

% === 子图 3: SOC 与 总续航预测 ===
ax3 = subplot(3,1,3);

% --- 左轴: SOC ---
yyaxis left
plot(t_smooth, SOC_smooth * 100, '-', 'Color', color_soc, 'LineWidth', 2.5);
hold on;
fill([t_smooth, fliplr(t_smooth)], [SOC_smooth*100, zeros(size(SOC_smooth))], ...
    color_soc, 'FaceAlpha', 0.1, 'EdgeColor', 'none');
ylabel('SOC (%)', 'FontWeight', 'bold');
ax3.YColor = color_soc;
ylim([0 105]);

% --- 右轴: 总续航时间 (Est. Total Runtime) ---
yyaxis right
plot(t_smooth, Endurance_smooth, '--', 'Color', color_time, 'LineWidth', 2);
ylabel('Est. Total Runtime (hrs)', 'FontWeight', 'bold');
ax3.YColor = color_time;

% 自动设置Y轴范围 (以最大预测值的1.2倍为上限，或至少显示到当前时间)
max_est_total = max(Endurance_smooth);
ylim([0 max(max_est_total*1.2, t_max*1.1)]);

% 标注最终时间点
final_val = Endurance_smooth(end);
plot(t_hours(end), final_val, 'o', 'MarkerSize', 6, 'MarkerFaceColor', color_time, 'MarkerEdgeColor', 'none');
text(t_hours(end), final_val + 0.5, sprintf('Total: %.1fh', final_val), ...
    'Color', color_time, 'FontWeight', 'bold', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom');

title('SOC Trajectory & Total Endurance Prediction', 'FontSize', 13);
grid on; ax3.GridAlpha = 0.15; 
box off;

xlabel('Time (Hours)', 'FontWeight', 'bold');
xlim([0 t_max]); 

% 添加图例
legend(ax3, {'SOC (%)', '', 'Est. Total Runtime (h)'}, ...
    'Location', 'southwest', 'Orientation', 'horizontal', 'Box', 'off');

% 统一设置字体
set(findall(gcf,'-property','FontSize'),'FontSize', font_size);
set(findall(gcf,'-property','FontName'),'FontName', axis_font);