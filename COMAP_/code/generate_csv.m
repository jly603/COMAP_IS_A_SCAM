% =========================================================================
% 脚本名称：generate_csv.m
% 功能：生成测试用的 data.csv (参数常量) 和 auto.csv (时序数据)
% =========================================================================
clear; clc;

%% 1. 生成 data.csv (硬件与模型参数)
% 定义参数结构体
data.P_disp_max = 1200;
data.P_disp_min = 0;
data.GAMMA = 2.0;
data.P_cpu_idle = 100;
data.P_cpu_max = 3000;
data.P_idle_WiFi = 200;
data.P_idle_4G = 500;
data.P_idle_5G = 1000;
data.P_idle_none = 10; % 飞行模式/无连接下的底噪
data.alpha_DL = 1.5;   % mW/Mbps
data.alpha_UL = 2.5;   % mW/Mbps
data.P_cam_active = 1100;
data.P_gps_base = 400;
data.LAMBDA = 0.5;
data.P_daemon = 20;
data.I_bg_save = 0;    % 省电模式系数
data.I_bg_idle = 0.1;  % 正常待机系数
data.I_bg_on = 0.8;    % 活跃后台系数
data.P_active_burst = 300;

% 转换为 Table 并写入 CSV
T_data = struct2table(data);
writetable(T_data, 'data.csv');
fprintf('成功生成 data.csv\n');

%% 2. 生成 auto.csv (时序模拟数据)
% 模拟 100 个时间点
N = 100; 
auto.S_disp = randi([0, 1], N, 1);          % 屏幕开关
auto.B = rand(N, 1);                        % 亮度 0~1
auto.U_cpu = randi([0, 1], N, 1);           % CPU 负载 0~1
auto.P_idle_mode = randi([0, 3], N, 1);     % 网络模式 0~3
auto.R_DL = rand(N, 1) * 50;                % 下载速率 0~50 Mbps
auto.R_UL = rand(N, 1) * 10;                % 上传速率 0~10 Mbps
auto.S_cam = randi([0, 1], N, 1) .* 0.2;    % 相机开关 (稀疏开启，模拟只需少量开启)
auto.S_cam(auto.S_cam > 0) = 1;             % 二值化
auto.S_gps = randi([0, 1], N, 1);           % GPS 开关
auto.Q_sat = 0.1 + rand(N, 1) * 0.9;        % 信号质量 0.1~1.0
auto.I_bg_mode = randi([0, 2], N, 1);       % 后台模式 0~2

% 转换为 Table 并写入 CSV
T_auto = struct2table(auto);
writetable(T_auto, 'auto.csv');
fprintf('成功生成 auto.csv (包含 %d 条记录)\n', N);