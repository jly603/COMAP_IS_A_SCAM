%% Initialization
clc; clear; close all;

% Set global settings for modern look
set(0, 'DefaultAxesFontName', 'Arial'); 
set(0, 'DefaultTextFontName', 'Arial');
set(0, 'DefaultAxesFontSize', 10);
set(0, 'DefaultLineLineWidth', 2);

%% 1. Simulate Data (Data Generation)
% Increase sampling rate for smoother curves
t = linspace(0, 10, 500)'; 

% (1) Simulated Current: Base + Sine wave + Noise
raw_noise_curr = 0.05 * randn(size(t));
current_sim = 0.8 + 0.15 * sin(2*pi*t/2.5) + raw_noise_curr;
current_plot = smoothdata(current_sim, 'gaussian', 15);

% (2) Simulated Temperature: Base + Trend + Noise
raw_noise_temp = 0.5 * randn(size(t));
temp_sim = 45 + 5 * sin(2*pi*t/5) + raw_noise_temp;
temp_plot = smoothdata(temp_sim, 'gaussian', 20);

% (3) Battery SOH: Linear degradation + Noise
soh_sim = linspace(0.85, 0.6, length(t))' + 0.005 * randn(size(t));
soh_plot = smoothdata(soh_sim, 'movmean', 20);

% (4) True SOC: High SOC fluctuation
soc_sim = 99 + 1.2 * sin(3*t) .* cos(5*t) - 0.5 * rand(size(t));
soc_sim = rescale(soc_sim, 97.2, 100); 
soc_plot = smoothdata(soc_sim, 'gaussian', 10);

%% 2. Visualization Setup (Modern Palette)
c_blue   = [0.00, 0.45, 0.74]; % Scientific Blue
c_red    = [0.85, 0.33, 0.10]; % Coral Red
c_green  = [0.47, 0.67, 0.19]; % Muted Green
c_purple = [0.49, 0.18, 0.56]; % Deep Purple
c_gray   = [0.20, 0.20, 0.20]; % Dark Gray

figure('Color', 'w', 'Position', [100, 100, 1200, 650]);

sgtitle('Input Feature Visualization', ...
    'FontSize', 16, 'FontWeight', 'bold', 'Color', c_gray);

% Helper function for axis styling
axis_style = @(ax) set(ax, 'Box', 'off', 'TickDir', 'out', ...
    'XColor', [0.3 0.3 0.3], 'YColor', [0.3 0.3 0.3], ...
    'LineWidth', 1, 'GridColor', [0.8 0.8 0.8], 'GridAlpha', 0.5, 'GridLineStyle', '--');

%% 3. Plotting (Reversed Order)

% --- Plot 1 (Old 6): Temperature-SOC Relationship ---
subplot(2, 3, 1);
s2 = scatter(temp_sim, soc_sim, 30, t, 'filled');
s2.MarkerFaceAlpha = 0.6;
s2.MarkerEdgeColor = 'none';
title('Temperature-SOC Relationship', 'Color', c_gray);
xlabel('Temperature (°C)'); ylabel('SOC (%)');
grid on; box on;
colormap(gca, 'parula');
c = colorbar; c.Color = [0.3 0.3 0.3];
set(gca, 'GridLineStyle', '--', 'GridAlpha', 0.4);

% --- Plot 2 (Old 5): Current-SOC Relationship ---
subplot(2, 3, 2);
s1 = scatter(current_sim, soc_sim, 30, t, 'filled'); 
s1.MarkerFaceAlpha = 0.6; 
s1.MarkerEdgeColor = 'none';
title('Current-SOC Relationship', 'Color', c_gray);
xlabel('Current (A)'); ylabel('SOC (%)');
grid on; box on;
colormap(gca, 'parula'); 
c = colorbar; c.Color = [0.3 0.3 0.3];
set(gca, 'GridLineStyle', '--', 'GridAlpha', 0.4);

% --- Plot 3 (Old 4): True SOC Variation ---
subplot(2, 3, 3);
plot(t, soc_sim, 'Color', [c_purple, 0.2], 'LineWidth', 0.5, 'HandleVisibility', 'off'); hold on;
plot(t, soc_plot, 'Color', c_purple); 
title('True SOC Variation', 'Color', c_gray);
xlabel('Time (h)'); ylabel('True SOC (%)');
grid on; axis tight; ylim([97 100]);
axis_style(gca);

% --- Plot 4 (Old 3): Battery SOH Variation ---
subplot(2, 3, 4);
plot(t, soh_sim, 'Color', [c_green, 0.2], 'LineWidth', 0.5, 'HandleVisibility', 'off'); hold on;
plot(t, soh_plot, 'Color', c_green); 
title('Battery SOH Variation', 'Color', c_gray);
xlabel('Time (h)'); ylabel('SOH');
grid on; axis tight;
axis_style(gca);

% --- Plot 5 (Old 2): Simulated Temperature Variation ---
subplot(2, 3, 5);
plot(t, temp_sim, 'Color', [c_red, 0.2], 'LineWidth', 0.5, 'HandleVisibility', 'off'); hold on;
plot(t, temp_plot, 'Color', c_red); 
title('Simulated Temperature Variation', 'Color', c_gray);
xlabel('Time (h)'); ylabel('Temperature (°C)');
grid on; axis tight;
axis_style(gca);

% --- Plot 6 (Old 1): Simulated Current Variation ---
subplot(2, 3, 6);
plot(t, current_sim, 'Color', [c_blue, 0.2], 'LineWidth', 0.5, 'HandleVisibility', 'off'); hold on;
plot(t, current_plot, 'Color', c_blue); 
title('Simulated Current Variation', 'Color', c_gray);
xlabel('Time (h)'); ylabel('Current (A)');
grid on; axis tight;
axis_style(gca);

%% 4. Final Adjustments
set(gcf, 'Units', 'normalized');