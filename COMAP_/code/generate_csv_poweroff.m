% =========================================================================
% 脚本名称：generate_csv_poweroff.m
% 功能：生成模拟"手机关机"状态的 data.csv 和 auto.csv
%       (模拟关机漏电/电池自放电场景)
% =========================================================================
clear; clc;

%% 1. 生成 data.csv (参数设置)
% 注意：即使是关机，硬件的物理属性（如 P_max）不变，
% 但我们需要确保计算逻辑中用到的"底噪"参数符合关机特征。
% 在此模型中，主要靠 auto.csv 的控制变量来"关闭"设备。

data.P_disp_max = 1200;
data.P_disp_min = 0;
data.GAMMA = 2.0;

% [关键点] 
% 在严格的物理模型中，关机时的 P_cpu_idle 应该接近 0.1mW (漏电)。
% 但如果沿用原公式 P_cpu = P_idle + (Max-Idle)*U，
% 我们需要在 auto.csv 中将 U_cpu 设为 0，并且这里的 P_cpu_idle 
% 可能需要被理解为"关机后的主板漏电"。
% 为了严谨，这里保留硬件参数，但在 auto.csv 中彻底切断负载。
data.P_cpu_idle = 100; % 这里的 100 是开机空闲。关机时其实用不到这个值，或者我们假设关机=0
data.P_cpu_max = 3000;

data.P_idle_WiFi = 200;
data.P_idle_4G = 500;
data.P_idle_5G = 1000;
% [关键点] 关机状态对应 Mode 0，其功耗应为极微小的电路漏电
data.P_idle_none = 0.5; 

data.alpha_DL = 1.5;
data.alpha_UL = 2.5;
data.P_cam_active = 1100;
data.P_gps_base = 400;
data.LAMBDA = 0.5;

% [关键点] 关机时没有守护进程
data.P_daemon = 0.1; 

data.I_bg_save = 0;    
data.I_bg_idle = 0.1;
data.I_bg_on = 0.8;
data.P_active_burst = 300;

% 转换为 Table 并写入 CSV
T_data = struct2table(data);
writetable(T_data, 'data.csv');
fprintf('成功生成 data.csv (关机参数适配)\n');

%% 2. 生成 auto.csv (关机状态时序数据)
% 模拟 100 个时间点
N = 96; 

% --- 屏幕模块 ---
auto.S_disp = zeros(N, 1);          % 强制关闭：0
auto.B = zeros(N, 1);               % 亮度：0

% --- CPU 模块 ---
% 关机状态下 CPU 不运行。
% 注意：如果原来的计算公式是 P_idle + ...，
% 那么即使 U=0，也会算出 100mW 的 P_idle。
% *为了在不修改计算代码的前提下模拟关机*，
% 我们需要意识到原模型可能只适用于"开机状态"。
% 但我们可以通过将 U_cpu 设置为 0 (或者负数/特殊处理，但这需要改计算代码)。
% 假设：这是一个"假关机"或者我们仅仅模拟漏电。
auto.U_cpu = zeros(N, 1); 

% --- 网络模块 ---
auto.P_idle_mode = zeros(N, 1);     % 强制 Mode 0 (P_idle_none)
auto.R_DL = zeros(N, 1);            % 下载速率：0
auto.R_UL = zeros(N, 1);            % 上传速率：0

% --- 相机模块 ---
auto.S_cam = zeros(N, 1);           % 强制关闭：0

% --- GPS 模块 ---
auto.S_gps = zeros(N, 1);           % 强制关闭：0
auto.Q_sat = ones(N, 1);            % 信号质量无意义，设为1避免计算分母为0

% --- 后台模块 ---
auto.I_bg_mode = zeros(N, 1);       % 强制 Mode 0 (I_bg_save = 0)

% 转换为 Table 并写入 CSV
T_auto = struct2table(auto);
writetable(T_auto, 'auto.csv');

fprintf('成功生成 auto.csv (全零/关机状态)\n');
fprintf('------------------------------------------------------\n');
fprintf('注意：直接运行原计算脚本时，P_cpu 仍会计算出 P_cpu_idle 的值。\n');
fprintf('如果 P_cpu_idle 代表"唤醒但空闲"(100mW)，则这不符合关机物理事实。\n');
fprintf('建议：在 data.csv 中临时将 P_cpu_idle 修改为 0.1 (漏电值)。\n');
fprintf('本脚本已在 data.csv 生成部分保留了原值，请根据需要手动调整或在下方逻辑覆盖。\n');

%% [修正逻辑] 覆盖 data.csv 中的 idle 值以模拟真实断电
% 为了让计算结果真实反映"关机"，我们需要 hack 一下 data.csv
% 因为原公式 P_cpu = P_idle + ... 导致只要运行就有 P_idle。
data.P_cpu_idle = 0.2; % 将 CPU 待机功耗设为 0.2mW (模拟漏电)
T_data_fixed = struct2table(data);
writetable(T_data_fixed, 'data.csv');
fprintf('[修正] 已更新 data.csv 中的 P_cpu_idle = 0.2mW 以匹配关机状态。\n');