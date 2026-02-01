% =========================================================================
% 脚本名称：calc_power.m
% 功能：读取 csv 数据，根据物理模型计算总功耗 P_total
% =========================================================================
clear; clc; close all;

%% 1. 读取参数文件 (data.csv)
if ~isfile('data.csv') || ~isfile('auto.csv')
    error('未找到 data.csv 或 auto.csv，请先运行 generate_csv.m 生成数据。');
end

% 读取参数表 (假定只有一行数据)
param_table = readtable('data.csv');

% 将参数提取为结构体以便调用 (例如 param.P_disp_max)
param = table2struct(param_table);

%% 2. 读取时序数据 (auto.csv)
auto_data = readtable('auto.csv');
num_samples = height(auto_data);

fprintf('正在处理 %d 条数据...\n', num_samples);

%% 3. 模块化计算 (向量化操作)

% ----------------------------------------------------------------
% 模块 1：屏幕显示模块 (P_disp)
% 公式：S * (Min + (Max - Min) * B^Gamma)
% ----------------------------------------------------------------
P_disp = auto_data.S_disp .* ...
    (param.P_disp_min + (param.P_disp_max - param.P_disp_min) .* (auto_data.B .^ param.GAMMA));


% ----------------------------------------------------------------
% 模块 2：处理器模块 (P_cpu)
% 公式：Idle + (Max - Idle) * U_cpu
% ----------------------------------------------------------------
P_cpu = param.P_cpu_idle + (param.P_cpu_max - param.P_cpu_idle) .* auto_data.U_cpu;


% ----------------------------------------------------------------
% 模块 3：网络连接模块 (P_net)
% 公式：P_idle_mode + a_DL*R_DL + a_UL*R_UL
% ----------------------------------------------------------------
% 准备基础功耗查找表：索引 1对应mode0, 2对应mode1 ...
net_idle_lookup = [param.P_idle_none, param.P_idle_WiFi, param.P_idle_4G, param.P_idle_5G];

% 根据 auto.csv 中的 mode (0,1,2,3) 查找对应的 idle 功耗
% 注意：MATLAB 索引从 1 开始，所以 mode 需要 +1
current_P_net_idle = net_idle_lookup(auto_data.P_idle_mode + 1)';

% 计算流量动态功耗
P_throughput = param.alpha_DL .* auto_data.R_DL + param.alpha_UL .* auto_data.R_UL;

% 网络总功耗 (假设 mode=0 时不进行数据传输，或者数据传输也产生功耗)
P_net = current_P_net_idle + P_throughput;


% ----------------------------------------------------------------
% 模块 5：定位导航模块 (P_gps)
% 公式：S_gps * Base * (1 + Lambda * (1/Q_sat))
% ----------------------------------------------------------------
% 防止除以 0 错误，限制 Q_sat 最小值
safe_Q_sat = max(auto_data.Q_sat, 0.001); 

P_gps = auto_data.S_gps .* param.P_gps_base .* ...
        (1 + param.LAMBDA .* (1 ./ safe_Q_sat));


% ----------------------------------------------------------------
% 模块 6：后台任务模块 (P_bg)
% 公式：P_daemon + I_bg(mode) * P_active_burst
% ----------------------------------------------------------------
% 准备后台系数查找表
bg_intensity_lookup = [param.I_bg_save, param.I_bg_idle, param.I_bg_on];

% 根据 mode (0,1,2) 查找对应的 intensity
% 索引同样 +1
current_I_bg = bg_intensity_lookup(auto_data.I_bg_mode + 1)';

P_bg = param.P_daemon + current_I_bg .* param.P_active_burst;


%% 4. 汇总计算 P_total
P_total = P_disp + P_cpu + P_net + P_gps + P_bg;

%% --- 将此代码块添加到 calc_power.m 的最后 ---

% 1. 创建一个只包含计算结果的表格
output_table = table(P_total);

% 2. (可选) 重命名列头，让 CSV 表头显示为 "P_total_mW"
output_table.Properties.VariableNames = {'P_total_mW'};

% 3. 写入文件 "P_total_only.csv"
writetable(output_table, 'P_total_only.csv');

fprintf('已生成纯数据文件: P_total_only.csv\n');

%% 5. 结果输出与可视化

% 将结果添加到原表格中
auto_data.P_total_mW = P_total;

% 保存结果到新文件
writetable(auto_data, 'result_power_analysis.csv');
fprintf('计算完成，结果已保存至 result_power_analysis.csv\n');

% 简单绘图展示
figure('Name', 'Power Consumption Model', 'Color', 'w');
subplot(2,1,1);
plot(P_total, 'LineWidth', 1.5, 'Color', [0.8500 0.3250 0.0980]);
title('Total Power Consumption (P_{total})');
ylabel('Power (mW)');
xlabel('Time Sample');
grid on;

subplot(2,1,2);
area_data = [P_disp, P_cpu, P_net, P_gps, P_bg];
area(area_data);
legend('Disp', 'CPU', 'Net', 'GPS', 'BG', 'Location', 'BestOutside');
title('Power Breakdown by Module');
ylabel('Power (mW)');
xlabel('Time Sample');
grid on;