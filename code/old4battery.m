function BatteryAgingSimulation_Final()
    % --- Setup Environment ---
    close all; clear; clc;
    
    % --- 颜色配置 (保持现代配色，但用于线条) ---
    c_blue = [0, 114, 189] / 255; 
    c_red = [217, 83, 25] / 255; 
    
    % 全局字体设置
    set(0, 'DefaultAxesFontName', 'Arial');
    set(0, 'DefaultAxesFontSize', 11);
    set(0, 'DefaultLineLineWidth', 2.5); % 线条加粗
    
    % --- 物理参数 (经过调整，使曲线更陡峭) ---
    R_gas = 8.314; T_ref = 298.15; E_a = 24000;
    
    % [关键调整]: 增大了 K 值，让老化显更明显
    % 之前的 1.5e-11 太保守，现在改为 7.0e-11，模拟"加速老化"或更真实的劣质电池/极端工况
    K_cal = 7.0e-11;  
    beta = 2.5;
    
    K_cyc = 9.0e-11;  
    k_I = 0.5; gamma = 1.8;
    
    % 创建画布
    figure('Color', 'w', 'Position', [100, 100, 1400, 450]);
    
    %% 图表 1: 日历老化 (Calendar Aging)
    T_celsius = linspace(15, 45, 200); 
    T_kelvin = T_celsius + 273.15;
    SOC_levels = [0.2, 0.5, 0.8, 1.0]; 
    
    subplot(1, 3, 1); hold on;
    grad_colors = parula(length(SOC_levels));
               
    for i = 1:length(SOC_levels)
        soc = SOC_levels(i);
        D_cal = K_cal * exp((E_a/R_gas) * (1/T_ref - 1./T_kelvin)) * exp(beta * soc);
        % 显示年化衰减率 (%)
        y_data = D_cal * 3600 * 24 * 365 * 100; 
        plot(T_celsius, y_data, 'Color', grad_colors(i,:), 'DisplayName', sprintf('SOC = %.1f', soc));
    end
    
    % 样式美化
    add_black_border(); % 调用自定义黑边函数
    grid on;
    xlabel('Temperature (°C)', 'FontWeight', 'bold');
    ylabel('Annual Decay (% / year)', 'FontWeight', 'bold');
    title('Fig 1: Calendar Aging Rate', 'FontSize', 12, 'FontWeight', 'bold');
    legend('Location', 'northwest', 'Box', 'on', 'EdgeColor', 'k'); % 图例也加黑框
    xlim([15, 45]);

    %% 图表 2: 循环老化 (Cycle Aging)
    Current = linspace(0, 3, 200); 
    T_cyc_levels = [25, 35, 45];
    
    subplot(1, 3, 2); hold on;
    grad_colors_2 = autumn(length(T_cyc_levels));
    
    for i = 1:length(T_cyc_levels)
        T_k = T_cyc_levels(i) + 273.15;
        D_cyc = K_cyc .* abs(Current) .* (1 + k_I .* Current.^2) .* exp((E_a/R_gas) * (1/T_ref - 1/T_k));
        % 显示每1000小时衰减 (%)
        y_data = D_cyc * 3600 * 1000 * 100;
        plot(Current, y_data, 'Color', grad_colors_2(i,:), 'DisplayName', sprintf('Temp = %d°C', T_cyc_levels(i)));
    end
    
    add_black_border();
    grid on;
    xlabel('Current (C-rate)', 'FontWeight', 'bold');
    ylabel('Decay per 1000h (%)', 'FontWeight', 'bold');
    title('Fig 2: Cycle Aging Rate', 'FontSize', 12, 'FontWeight', 'bold');
    legend('Location', 'northwest', 'Box', 'on', 'EdgeColor', 'k');
    
    %% 图表 3: 长期演变 (Long-term Evolution)
    days = linspace(0, 730, 500); % 2年
    
    % 用户配置
    UserA = [25+273.15, 0.5, 0.5]; % 轻度
    UserB = [35+273.15, 0.9, 1.5]; % 重度
    
    % 计算速率
    calc_rate = @(u) (K_cal * exp((E_a/R_gas)*(1/T_ref - 1/u(1))) * exp(beta * u(2))) + ...
                     (K_cyc * u(3) * (1 + k_I * u(3)^2) * exp((E_a/R_gas)*(1/T_ref - 1/u(1))));
    
    rate_A = calc_rate(UserA);
    rate_B = calc_rate(UserB);
    
    % SOH 计算
    SOH_A = 1.0 - rate_A * days * 24 * 3600;
    SOH_B = 1.0 - rate_B * days * 24 * 3600;
    
    ax3 = subplot(1, 3, 3);
    
    % --- 左轴: 容量 ---
    yyaxis left;
    h1 = plot(days, SOH_A * 100, '-', 'Color', c_blue, 'LineStyle', '-'); hold on;
    h2 = plot(days, SOH_B * 100, '-', 'Color', [0.3 0.7 0.9], 'LineStyle', '--');
    ylabel('Capacity (SOH %)', 'FontWeight', 'bold', 'Color', 'k'); % 强制黑色字体
    set(gca, 'YColor', c_blue); % 轴线蓝色
    ylim([70, 100]); % 范围调整到70，适应更陡峭的曲线
    
    % --- 右轴: 内阻 ---
    yyaxis right;
    R_norm_A = 1 + gamma * (1 - SOH_A);
    R_norm_B = 1 + gamma * (1 - SOH_B);
    
    h3 = plot(days, R_norm_A, '-', 'Color', c_red, 'LineStyle', '-');
    h4 = plot(days, R_norm_B, '-', 'Color', [0.9 0.6 0.1], 'LineStyle', '--');
    ylabel('Relative Resistance (R/R_{new})', 'FontWeight', 'bold', 'Color', 'k');
    set(gca, 'YColor', c_red); % 轴线红色
    
    % 这里的 Box 处理比较特殊，yyaxis 需要特殊处理才能显全黑框
    % 但最简单且有效的方法是开启 Box on 并加粗
    box on; 
    set(gca, 'LineWidth', 1.2); 
    grid on;
    
    xlabel('Time (Days)', 'FontWeight', 'bold');
    title('Fig 3: Long-term Prediction', 'FontSize', 12, 'FontWeight', 'bold');
    
    % 图例
    legend([h1, h2, h3, h4], 'SOH (Light)', 'SOH (Heavy)', 'R (Light)', 'R (Heavy)', ...
           'Location', 'southwest', 'Box', 'on', 'EdgeColor', 'k', 'FontSize', 9);
       
    sgtitle('Battery Aging Dynamics (Accelerated View)', 'FontSize', 14, 'FontWeight', 'bold');
end

function add_black_border()
    % 强制添加黑色粗边框的辅助函数
    box on;
    set(gca, 'LineWidth', 1.5);      % 边框加粗
    set(gca, 'XColor', 'k');         % X轴黑色
    set(gca, 'YColor', 'k');         % Y轴黑色
    set(gca, 'GridAlpha', 0.15);     % 网格淡一点
end