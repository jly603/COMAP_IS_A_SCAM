clear; clc; close all;

%% 1. 参数设置
% ---------------------------------------------------------
dt = 900;             % 时间步长 (s)
C_nominal_Ah = 12.0; % 电池【标称】容量 (Ah)
C_nominal_Coulomb = C_nominal_Ah * 3600; 

% 电池内阻与极化参数
R0 = 0.04;          % 欧姆内阻 (Ohm)
Rp = 0.02;          % 极化电阻 (Ohm)
Cp = 2000;           % 极化电容 (F)

% --- 温度修正参数 (根据文档第三部分) ---
T_ref = 25.0;       % 参考温度 (摄氏度)
alpha_temp = 0.0002; % 温度敏感系数 (需要根据实际电池特性调整)
% 说明：假设 alpha=0.001，温差20度时，(20^2)*0.001 = 0.4，容量衰减40%，这是一个比较显著的低温影响

% 初始状态
SOC_init = 1.0;     
Up_init = 0;        

% OCV - SOC 拟合系数 (a0 ... a8)
% U = a0 + a1*x + ...
coeffs_raw = [3.31; 2.38; -9.55; 21.02; -20.32; 7.34];
p_ocv = flipud(coeffs_raw); % 翻转为 MATLAB 格式

%% 2. 加载数据 (功率 P 和 温度 T)
% ---------------------------------------------------------
% 2.1 加载功率
if isfile('P_total_only.csv')
    P_data = readmatrix('P_total_only.csv');
    P_seq = P_data(:, 1)/1000; 
else
    % 默认：生成随机功率 2W - 15W
    P_seq = 2 + 13 * rand(100, 1); 
end

N = length(P_seq);

% 2.2 加载或生成温度数据
if isfile('Temp_data.csv')
    T_data = readmatrix('Temp_data.csv');
    T_seq = T_data(:, 1);
    % 确保长度一致
    if length(T_seq) < N
        error('温度数据长度小于功率数据长度');
    end
else
    % 默认：模拟一个低温环境，演示修正效果
    % 假设温度从 0度 慢慢下降到 -15度
    fprintf('提示：未找到 Temp_data.csv，生成模拟低温数据 (-15°C 左右) 以演示修正效果。\n');
    T_seq = linspace(25, 25, N)';       % 温度为20度
end

%% 3. 初始化
% ---------------------------------------------------------
SOC_hist = zeros(N, 1);
I_hist = zeros(N, 1);
V_term_hist = zeros(N, 1);
Up_hist = zeros(N, 1);
C_eff_hist = zeros(N, 1); % 记录有效容量的变化

current_SOC = SOC_init;
current_Up = Up_init;

%% 4. 核心循环
% ---------------------------------------------------------
for k = 1:N
    P_now = P_seq(k);
    T_now = T_seq(k); % 获取当前温度
    
    % --- 温度修正 (文档第三部分) ---
    % μ(T) = 1 - α * (T_ref - T)^2   (当 T < T_ref)
    if T_now < T_ref
        mu = 1 - alpha_temp * (T_ref - T_now)^2;
        % 保护：防止 mu 变成负数或过小
        if mu < 0.1
            mu = 0.1; 
        end
    else
        mu = 1.0;
    end
    
    % 计算当前有效容量 (换算为库伦)
    C_eff_now = C_nominal_Coulomb * mu;
    
    % --- OCV 计算 ---
    V_ocv = polyval(p_ocv, current_SOC);
    
    % --- 电流求解 ---
    delta = (V_ocv - current_Up)^2 - 4 * R0 * P_now;
    if delta < 0
        error('Step %d: Power too high, calculation failed.', k);
    end
    I_now = ((V_ocv - current_Up) - sqrt(delta)) / (2 * R0);
    
    % --- 电压计算 ---
    V_term = V_ocv - I_now * R0 - current_Up;
    
    % --- 存储数据 ---
    SOC_hist(k) = current_SOC;
    I_hist(k) = I_now;
    V_term_hist(k) = V_term;
    Up_hist(k) = current_Up;
    C_eff_hist(k) = C_eff_now / 3600; % 存为 Ah 方便查看
    
    % --- 状态更新 ---
    
    % 1. 更新 SOC (使用修正后的 C_eff_now) !!! 核心修改点
    dSOC = -I_now / C_eff_now;
    current_SOC = current_SOC + dSOC * dt;
    
    % 2. 更新极化电压 Up (使用指数离散化，无条件稳定)
tau = Rp * Cp; % 时间常数
exp_factor = exp(-dt / tau);

% 公式物理含义：旧电压衰减 + 新电流产生的电压积累
current_Up = current_Up * exp_factor + I_now * Rp * (1 - exp_factor);
    
    % 边界限制
    current_SOC = max(0, min(1, current_SOC));
end

% ... (保留前面的第1-4部分代码不变) ...

%% 5. 可视化结果 (美化版)
% ---------------------------------------------------------
% 准备原始时间轴
t_hours = (0:N-1)' * dt / 3600; 

% --- 平滑处理设置 ---
% 为了让曲线圆润，我们将数据插值加密 10 倍
N_smooth = (N-1) * 10 + 1;
t_smooth = linspace(min(t_hours), max(t_hours), N_smooth);

% 使用 'pchip' (保形三次插值) 或 'spline' 进行平滑
% pchip 相比 spline 更不容易产生过冲 (overshoot)，适合物理量
P_smooth      = interp1(t_hours, P_seq,       t_smooth, 'pchip');
T_smooth      = interp1(t_hours, T_seq,       t_smooth, 'pchip');
I_smooth      = interp1(t_hours, I_hist,      t_smooth, 'pchip');
C_eff_smooth  = interp1(t_hours, C_eff_hist,  t_smooth, 'pchip');
SOC_smooth    = interp1(t_hours, SOC_hist,    t_smooth, 'pchip');

% --- 现代配色方案 (RGB归一化) ---
color_power = [0.2, 0.4, 0.7];      % 钢蓝色 (Power)
color_temp  = [0.85, 0.33, 0.1];    % 焦橙色 (Temperature)
color_curr  = [0.3, 0.3, 0.3];      % 深灰色 (Current)
color_cap   = [0.6, 0.4, 0.7];      % 柔紫色 (Capacity)
color_soc   = [0.0, 0.65, 0.55];    % 极光绿 (SOC)
bg_color    = [0.98, 0.98, 0.98];   % 极淡灰背景

% --- 绘图初始化 ---
hFig = figure('Color', 'w', 'Position', [150, 100, 1000, 850]);

% 定义公共字体和字号
axis_font = 'Helvetica'; % 或 'Arial'
font_size = 11;

% === 子图 1: 输入条件 (功率与温度) ===
ax1 = subplot(3,1,1);
yyaxis left; 
% 绘制面积图会让视觉重心更稳
area(t_smooth, P_smooth, 'FaceColor', color_power, 'FaceAlpha', 0.15, 'EdgeColor', color_power, 'LineWidth', 1.5);
ylabel('Power (W)', 'FontWeight', 'bold');
ylim([0 max(P_seq)*1.3]); 
ax1.YColor = color_power; % 设置轴颜色

yyaxis right; 
plot(t_smooth, T_smooth, '-', 'Color', color_temp, 'LineWidth', 2); 
ylabel('Temperature (°C)', 'FontWeight', 'bold');
ax1.YColor = color_temp;

title('Input Conditions: Load & Environment', 'FontSize', 13);
grid on; ax1.GridAlpha = 0.15; ax1.MinorGridAlpha = 0.1; % 让网格更淡雅
xlim([0 24]);
xticks(0:3:24); 
xticklabels({}); % 隐藏x轴标签
box off; % 去掉顶部和右侧的边框线

% === 子图 2: 电池响应 (电流与容量对比) ===
ax2 = subplot(3,1,2);

% --- 左轴：电流 ---
yyaxis left
plot(t_smooth, I_smooth, '-', 'Color', color_curr, 'LineWidth', 1.5);
ylabel('Current (A)', 'FontWeight', 'bold');
ax2.YColor = color_curr; 

% --- 右轴：容量 ---
yyaxis right
hold on; 

% 1. 绘制标称容量 (虚线基准 + 数值标签)
% Label 格式: "Nominal: 12.0 Ah"
yline(C_nominal_Ah, '--', sprintf('Nominal: %.0f mAh', C_nominal_Ah * 1000), ...
    'Color', [0.5 0.5 0.5], ...       % 稍微深一点的灰色，保证字迹清晰
    'LineWidth', 1.2, ...
    'LabelHorizontalAlignment', 'right', ... % 标签靠右显示，避免遮挡左侧曲线
    'LabelVerticalAlignment', 'top', ...  % 标签显示在线的上方
    'FontSize', 10, ...
    'FontWeight', 'bold');

% 2. 绘制有效容量 (实线变化)
plot(t_smooth, C_eff_smooth, '-', 'Color', color_cap, 'LineWidth', 2);

hold off;

ylabel('Capacity (Ah)', 'FontWeight', 'bold');
ylim([0 C_nominal_Ah * 1.2]); %稍微增加顶部空间，给标签留位置
ax2.YColor = color_cap; 

title('Battery Response: Current & Capacity Degradation', 'FontSize', 13);
grid on; ax2.GridAlpha = 0.15;
xlim([0 24]);
xticks(0:3:24);
xticklabels({}); 
box off;

% 图例
legend({'Current', '', 'Effective Cap.'}, ... % 中间空字符串是为了跳过 yline 的图例(如果不想让参考线出现在图例里)
       'Location', 'northwest', 'Orientation', 'vertical', 'Box', 'on');

% === 子图 3: SOC 变化 (核心结果) ===
ax3 = subplot(3,1,3);
% 绘制 SOC 曲线，加阴影效果
plot(t_smooth, SOC_smooth * 100, '-', 'Color', color_soc, 'LineWidth', 2.5);
hold on;
% 添加渐变填充效果 (简单的透明填充)
fill([t_smooth, fliplr(t_smooth)], [SOC_smooth*100, zeros(size(SOC_smooth))], ...
    color_soc, 'FaceAlpha', 0.1, 'EdgeColor', 'none');

ylabel('SOC (%)', 'FontWeight', 'bold', 'Color', color_soc);
xlabel('Time of Day (HH:MM)', 'FontWeight', 'bold');

% 设置 X 轴为标准的 24 小时格式
xlim([0 24]);
xticks(0:3:24);
xticklabels({'00:00', '03:00', '06:00', '09:00', '12:00', '15:00', '18:00', '21:00', '24:00'});

title('State of Charge (SOC) Trajectory', 'FontSize', 13);
grid on; ax3.GridAlpha = 0.15;
ax3.YColor = color_soc; % 让左侧Y轴颜色跟随 SOC 颜色
box off;

% --- 最终剩余电量标注 ---
final_soc = SOC_hist(end) * 100;
% 画一个漂亮的标记点
plot(t_hours(end), final_soc, 'o', 'MarkerSize', 8, ...
    'MarkerFaceColor', 'w', 'MarkerEdgeColor', color_soc, 'LineWidth', 2);
% 添加文本
text(23.8, final_soc + 5, sprintf('Final: %.1f%%', final_soc), ...
    'Color', color_soc, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'right', 'FontSize', 10, 'BackgroundColor', 'w', 'EdgeColor', 'none');

% 统一设置所有坐标轴字体
set(findall(gcf,'-property','FontSize'),'FontSize', font_size);
set(findall(gcf,'-property','FontName'),'FontName', axis_font);