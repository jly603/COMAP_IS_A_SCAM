clear; clc; close all;

%% 1. 参数设置 (保持不变)
% ---------------------------------------------------------
dt = 1;               
T_total_min = 65;     
N = T_total_min * 60; 

C_Ah = 2.0;           
C_total = C_Ah * 3600;

R0 = 0.08;            
Rp = 0.05;            
Cp = 1000;            

SOC = 1.0;            
Up = 0;               

coeffs_raw = [3.536; -3.299; 41.62; -194.8; 458.9; -574.8; 368.7; -97.2; 1.488];
p_ocv = flipud(coeffs_raw);

%% 2. 构造“恒流”控制信号 (保持不变)
% ---------------------------------------------------------
I_target = 2.0;       
cutoff_min = 56;      
cutoff_step = cutoff_min * 60;

I_seq = zeros(N, 1);
I_seq(1:cutoff_step) = I_target; 
I_seq(cutoff_step+1:end) = 0;    

%% 3. 循环计算 (保持不变)
% ---------------------------------------------------------
V_term_hist = zeros(N, 1);
SOC_hist = zeros(N, 1);
Up_hist = zeros(N, 1);

current_SOC = SOC;
current_Up = Up;

for k = 1:N
    I_now = I_seq(k);
        % 2. 查表 OCV
    V_ocv = polyval(p_ocv, current_SOC);
    
    % ---【新增修复代码】防止低SOC时多项式飞升---
    % 如果计算出的OCV不合理(比如大于4.5V或突然升高)，强制压住
    if current_SOC < 0.1
        % 当电量很低时，电压应该很低，而不是飞升。
        % 这里用一个简单的线性衰减来替代多项式，避免发散
        % 假设 0.1 SOC 时电压约为 3.2V
        V_ocv = 3.2 + (current_SOC - 0.1) * 1.5; 
        
        % 再次兜底，不能小于 2.0V
        if V_ocv < 2.0, V_ocv = 2.0; end
    end
    % -----------------------------------------
    dUp = -(current_Up / (Rp * Cp)) + (I_now / Cp);
    current_Up = current_Up + dUp * dt;
    V_term = V_ocv - I_now * R0 - current_Up;
    dSOC = -I_now / C_total;
    current_SOC = current_SOC + dSOC * dt;
    
    if current_SOC < 0.01 && I_now > 0
        V_term = V_term - 0.5 * (0.01 - current_SOC); 
    end
    
    V_term_hist(k) = V_term;
    SOC_hist(k) = current_SOC;
    Up_hist(k) = current_Up;
end

%% 4. 现代风格绘图 (修正版：全实线)
% ---------------------------------------------------------
t_min = (1:N) / 60; 

% --- 定义现代配色 (RGB) ---
color_volt = [0.05, 0.45, 0.65];  % 深海蓝 (Deep Teal)
color_curr = [0.93, 0.40, 0.30];  % 珊瑚橙 (Coral Orange)

% 创建图形窗口
fig = figure('Color', 'w', 'Position', [100, 100, 800, 500]);
set(fig, 'Renderer', 'painters'); 

% --- 1. 绘制右轴：电流 (红色系，实线) ---
yyaxis right
% 背景填充 (更淡一点，不抢戏)
h_area = area(t_min, I_seq, 'FaceColor', color_curr, 'EdgeColor', 'none');
h_area.FaceAlpha = 0.12; 
hold on;
% 【修改点】 显式指定为实线 '-'，并加粗
plot(t_min, I_seq, '-', 'LineWidth', 2.0, 'Color', color_curr); 

ylabel('Current (A)', 'FontSize', 12, 'FontWeight', 'bold');
ylim([0 3.0]); 
ax = gca;
ax.YColor = color_curr; 

% --- 2. 绘制左轴：电压 (蓝色系，实线) ---
yyaxis left
h_line = plot(t_min, V_term_hist, '-', 'LineWidth', 2.5, 'Color', color_volt);
h_line.LineJoin = 'round'; 

ylabel('Voltage (V)', 'FontSize', 12, 'FontWeight', 'bold');
ylim([2.5 4.3]);
ax.YColor = color_volt;

% --- 3. 全局美化设置 ---
set(gca, 'FontName', 'Arial', 'FontSize', 11, 'LineWidth', 1.2); 
grid on;
% 【修改点】 将网格线样式从虚线 '--' 改为实线 '-'
ax.GridLineStyle = '--';  
ax.GridAlpha = 0.11;      % 实线网格要更淡一点才好看
ax.Layer = 'top';        
box off;                  

xlabel('Time (min)', 'FontSize', 12, 'FontWeight', 'bold');
title('Battery Discharge & Recovery Analysis', 'FontSize', 14, 'FontWeight', 'normal');

% --- 4. 标注 (Annotation) ---
x_focus = cutoff_min + 2; 
y_focus = V_term_hist(cutoff_min*60) + 0.3;

% 文本框
text(x_focus, y_focus, {'Voltage Recovery', '\DeltaV due to polarization'}, ...
    'Color', color_volt, 'FontSize', 10, 'FontName', 'Arial', ...
    'BackgroundColor', [1 1 1 0.9], 'EdgeColor', 'none', ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');

% 圆点标注
plot(cutoff_min, V_term_hist(cutoff_min*60+10), 'o', ...
    'MarkerSize', 8, 'MarkerFaceColor', 'w', 'MarkerEdgeColor', color_volt, 'LineWidth', 1.5);

% 图例
legend({'Voltage (V)'}, 'Location', 'northwest', 'Box', 'off');

drawnow;