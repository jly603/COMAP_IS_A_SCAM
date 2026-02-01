% =========================================================================
% 脚本名称：generate_csv.m (真实生活模拟版)
% 功能：生成一整天每15分钟的数据，模拟真实用户行为
% =========================================================================
clear; clc;

%% 1. 生成 data.csv (保持不变，硬件物理参数)
data.P_disp_max = 1200;
data.P_disp_min = 0;
data.GAMMA = 2.0;
data.P_cpu_idle = 100;
data.P_cpu_max = 3000;
data.P_idle_WiFi = 200;
data.P_idle_4G = 500;
data.P_idle_5G = 1000;
data.P_idle_none = 10;
data.alpha_DL = 1.5;
data.alpha_UL = 2.5;
data.P_cam_active = 1100;
data.P_gps_base = 400;
data.LAMBDA = 0.5;
data.P_daemon = 20;
data.I_bg_save = 0;
data.I_bg_idle = 0.1;
data.I_bg_on = 0.8;
data.P_active_burst = 300;

writetable(struct2table(data), 'data.csv');
fprintf('data.csv 生成完毕。\n');

%% 2. 生成 auto.csv (基于时间轴的场景模拟)

% 定义时间轴：00:00 到 23:45，间隔 15 分钟
t_start = datetime('today');
t_end = datetime('today') + hours(23) + minutes(45);
time_vector = (t_start : minutes(15) : t_end)';
N = length(time_vector); % 应该 = 96 个点

% --- 初始化所有数据为“深度睡眠模式” (基准) ---
S_disp = zeros(N, 1);           % 屏幕关
B = zeros(N, 1);                % 亮度 0
U_cpu = ones(N, 1) * 0.01;      % CPU 极低负载
P_idle_mode = zeros(N, 1);      % 0: None (假设睡眠开飞行或不连网)
R_DL = zeros(N, 1);             % 无下载
R_UL = zeros(N, 1);             % 无上传
S_cam = zeros(N, 1);            % 相机关
S_gps = zeros(N, 1);            % GPS 关
Q_sat = ones(N, 1) * 1.0;       % 默认信号好
I_bg_mode = zeros(N, 1);        % 0: 省电模式

% 获取小时数用于逻辑判断
hours_vec = hour(time_vector) + minute(time_vector)/60;

for i = 1:N
    h = hours_vec(i);
    
    % === 场景 1: 睡眠 (00:00 - 07:00) ===
    if h < 7
        P_idle_mode(i) = 1; % 连着 WiFi 待机
        I_bg_mode(i) = 0;   % 省电
        
    % === 场景 2: 起床 + 通勤 (07:00 - 09:00) ===
    elseif h >= 7 && h < 9
        S_disp(i) = 1;
        B(i) = 0.8;         % 户外亮度高
        U_cpu(i) = 0.3;     % 听歌、导航
        P_idle_mode(i) = 3; % 5G 移动数据
        S_gps(i) = 1;       % 开导航
        Q_sat(i) = 0.5;     % 城市移动中信号一般
        R_DL(i) = 5.0;      % 听歌流媒体
        I_bg_mode(i) = 2;   % 后台活跃
        
    % === 场景 3: 上班工作 (09:00 - 12:00) ===
    elseif h >= 9 && h < 12
        % 随机偶尔看手机
        if rand > 0.7, S_disp(i) = 1; else, S_disp(i) = 0; end
        B(i) = 0.4;         % 室内亮度
        U_cpu(i) = 0.1;
        P_idle_mode(i) = 1; % 公司 WiFi
        I_bg_mode(i) = 1;   % 正常待机
        
    % === 场景 4: 午休游戏/视频 (12:00 - 13:30) ===
    elseif h >= 12 && h < 13.5
        S_disp(i) = 1;
        B(i) = 0.6;
        U_cpu(i) = 0.8;     % 游戏高负载
        P_idle_mode(i) = 2; % 没抢到 WiFi，用 4G
        R_DL(i) = 30;       % 高吞吐
        I_bg_mode(i) = 2;
        
    % === 场景 5: 下午工作 (13:30 - 18:00) ===
    elseif h >= 13.5 && h < 18
        if rand > 0.8, S_disp(i) = 1; else, S_disp(i) = 0; end
        B(i) = 0.4;
        P_idle_mode(i) = 1; % 公司 WiFi
        I_bg_mode(i) = 1;
        
    % === 场景 6: 下班通勤 (18:00 - 19:30) ===
    elseif h >= 18 && h < 19.5
        S_disp(i) = 1;
        S_gps(i) = 1;       % 导航
        P_idle_mode(i) = 3; % 5G
        U_cpu(i) = 0.4;
        
    % === 场景 7: 居家娱乐 (19:30 - 23:00) ===
    elseif h >= 19.5 && h < 23
        S_disp(i) = 1;      % 一直亮屏
        B(i) = 0.5;
        P_idle_mode(i) = 1; % 家里 WiFi
        U_cpu(i) = 0.6;     % 刷剧/短视频
        R_DL(i) = 15;       % 视频流
        
        % 模拟偶尔打开相机 (比如 21:00 左右视频通话)
        if h >= 21 && h < 21.5
            S_cam(i) = 1;
            U_cpu(i) = 0.9; % 视频通话 CPU 很高
        end
        
    % === 场景 8: 睡前 (23:00 - 24:00) ===
    else
        S_disp(i) = 0;
        P_idle_mode(i) = 1;
        I_bg_mode(i) = 0;
    end
    
    % 添加少量随机噪声，让数据不那么死板
    if S_disp(i) == 1
        B(i) = min(1, max(0.1, B(i) + randn*0.05));
    end
end

% 构建 Table
T_auto = table(S_disp, B, U_cpu, P_idle_mode, R_DL, R_UL, S_cam, S_gps, Q_sat, I_bg_mode);

% 我们可以把时间字符串也写进去，方便查看，虽然计算时不读它
TimeStr = string(time_vector, 'HH:mm');
T_auto.Time = TimeStr; 

% 调整列顺序，把 Time 放第一列 (可选)
T_auto = movevars(T_auto, 'Time', 'Before', 'S_disp');

writetable(T_auto, 'auto.csv');
fprintf('auto.csv 生成完毕 (包含 24 小时数据，共 %d 条)。\n', N);