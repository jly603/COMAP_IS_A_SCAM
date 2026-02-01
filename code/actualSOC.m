%% Initialization
clc; clear; close all;

% Set global settings
set(0, 'DefaultAxesFontName', 'Arial'); 
set(0, 'DefaultTextFontName', 'Arial');
set(0, 'DefaultAxesFontSize', 10);
set(0, 'DefaultLineLineWidth', 2);

%% 1. Simulate Data (Data Generation)
% Time axis: 0 to 18 hours
t = linspace(0, 18, 900)'; 

% (1) Simulated Current
raw_noise_curr = 0.05 * randn(size(t));
current_sim = 0.8 + 0.15 * sin(2*pi*t/2.5) + raw_noise_curr;
current_plot = smoothdata(current_sim, 'gaussian', 15);

% (2) Simulated Temperature
raw_noise_temp = 0.5 * randn(size(t));
temp_sim = 45 + 5 * sin(2*pi*t/6) + raw_noise_temp; 
temp_plot = smoothdata(temp_sim, 'gaussian', 20);

% (3) Battery SOH [FIXED LOGIC]
% Reality Check: SOH changes very slowly. 
% We simulate a high-precision estimation where SOH drops very slightly 
% (e.g., from 0.9500 to 0.9495) plus measurement noise.
% Or if this represents a stress test, we drop it slightly more visibly but realistically.
% Let's drop 0.1% over 18 hours (still fast, but better for visualization)
base_soh = linspace(0.95, 0.948, length(t))'; 
noise_soh = 0.0005 * randn(size(t)); % Very small noise
soh_sim = base_soh + noise_soh;
soh_plot = smoothdata(soh_sim, 'movmean', 50); % Stronger smoothing for slow variable

% (4) True SOC
soc_sim = 99 + 1.2 * sin(3*t) .* cos(0.8*t) - 0.5 * rand(size(t));
soc_sim = rescale(soc_sim, 96.5, 100); 
soc_plot = smoothdata(soc_sim, 'gaussian', 10);

%% 2. Visualization Setup
% High Contrast Modern Palette
c_blue   = [0.00, 0.30, 0.55]; % Prussian Blue
c_red    = [0.75, 0.15, 0.15]; % Brick Red
c_green  = [0.13, 0.55, 0.13]; % Forest Green
c_purple = [0.45, 0.10, 0.55]; % Royal Purple
c_gray   = [0.10, 0.10, 0.10]; % Almost Black
bg_alpha = 0.4; 

figure('Color', 'w', 'Position', [100, 100, 1200, 650]);


apply_style = @(ax) set(ax, 'Box', 'on', 'TickDir', 'in', ...
    'XColor', 'k', 'YColor', 'k', 'LineWidth', 1.5, ...
    'GridColor', [0.6 0.6 0.6], 'GridAlpha', 0.4, 'GridLineStyle', ':');

%% 3. Plotting

% --- Plot 1: Temperature-SOC Relationship ---
subplot(2, 3, 1);
s2 = scatter(temp_sim, soc_sim, 30, t, 'filled');
s2.MarkerFaceAlpha = 0.7; s2.MarkerEdgeColor = 'none';
title('Temperature-SOC Relationship', 'Color', c_gray, 'FontWeight', 'bold');
xlabel('Temperature (°C)'); ylabel('SOC (%)');
grid on; colormap(gca, 'parula');
c = colorbar; c.Color = 'k'; c.LineWidth = 1.2; ylabel(c, 'Time (h)');
apply_style(gca);

% --- Plot 2: Current-SOC Relationship ---
subplot(2, 3, 2);
s1 = scatter(current_sim, soc_sim, 30, t, 'filled'); 
s1.MarkerFaceAlpha = 0.7; s1.MarkerEdgeColor = 'none';
title('Current-SOC Relationship', 'Color', c_gray, 'FontWeight', 'bold');
xlabel('Current (A)'); ylabel('SOC (%)');
grid on; colormap(gca, 'parula'); 
c = colorbar; c.Color = 'k'; c.LineWidth = 1.2; ylabel(c, 'Time (h)');
apply_style(gca);

% --- Plot 3: True SOC Variation ---
subplot(2, 3, 3);
plot(t, soc_sim, 'Color', [c_purple, bg_alpha], 'LineWidth', 0.8, 'HandleVisibility', 'off'); hold on;
plot(t, soc_plot, 'Color', c_purple); 
title('True SOC Variation', 'Color', c_gray, 'FontWeight', 'bold');
xlabel('Time (h)'); ylabel('True SOC (%)');
grid on; axis tight; ylim([96 100]);
apply_style(gca);

% --- Plot 4: Battery SOH Variation (FIXED) ---
subplot(2, 3, 4);
% Note: Since change is small, we adjust Y-lim to see the trend
plot(t, soh_sim, 'Color', [c_green, bg_alpha], 'LineWidth', 0.8, 'HandleVisibility', 'off'); hold on;
plot(t, soh_plot, 'Color', c_green); 
title('Battery SOH Variation', 'Color', c_gray, 'FontWeight', 'bold');
xlabel('Time (h)'); ylabel('SOH');
grid on; axis tight; 
% Manually set ylim to focus on the small change (e.g., 0.94 to 0.96)
ylim([0.945 0.955]); 
% Format Y-tick to show precision
ytickformat('%.3f'); 
apply_style(gca);

% --- Plot 5: Simulated Temperature Variation ---
subplot(2, 3, 5);
plot(t, temp_sim, 'Color', [c_red, bg_alpha], 'LineWidth', 0.8, 'HandleVisibility', 'off'); hold on;
plot(t, temp_plot, 'Color', c_red); 
title('Simulated Temperature Variation', 'Color', c_gray, 'FontWeight', 'bold');
xlabel('Time (h)'); ylabel('Temperature (°C)');
grid on; axis tight;
apply_style(gca);

% --- Plot 6: Simulated Current Variation ---
subplot(2, 3, 6);
plot(t, current_sim, 'Color', [c_blue, bg_alpha], 'LineWidth', 0.8, 'HandleVisibility', 'off'); hold on;
plot(t, current_plot, 'Color', c_blue); 
title('Simulated Current Variation', 'Color', c_gray, 'FontWeight', 'bold');
xlabel('Time (h)'); ylabel('Current (A)');
grid on; axis tight;
apply_style(gca);

%% 4. Final Adjustments
set(gcf, 'Units', 'normalized');