%% Initialization
clc; clear; close all;

% Set global font to Arial as requested
set(0, 'DefaultAxesFontName', 'Arial'); 
set(0, 'DefaultTextFontName', 'Arial');

%% 1. Simulate Data (Data Generation)
% Time axis: 0 to 10 hours
t = linspace(0, 10, 100)'; 

% (1) Simulated Current: Base + Sine wave + Noise
current_sim = 0.8 + 0.15 * sin(2*pi*t/2.5) + 0.05 * randn(size(t));

% (2) Simulated Temperature: Base + Trend + Noise
temp_sim = 45 + 5 * sin(2*pi*t/5) + 0.5 * randn(size(t));

% (3) Battery SOH: Linear degradation + Noise
soh_sim = linspace(0.85, 0.6, length(t))' + 0.01 * randn(size(t));

% (4) True SOC: High SOC fluctuation
soc_sim = 99 + 1.2 * sin(3*t) .* cos(5*t) - 0.5 * rand(size(t));
soc_sim =  rescale(soc_sim, 97.2, 100); 

%% 2. Visualization
figure('Color', 'w', 'Position', [100, 100, 1200, 600]);

% Main Title
sgtitle('Figure 1: Input Feature Visualization Based on Actual Data', ...
    'FontSize', 14, 'FontWeight', 'bold', 'FontName', 'Arial');

% --- Plot 1: Simulated Current Variation ---
subplot(2, 3, 1);
plot(t, current_sim, 'b-', 'LineWidth', 1.5); 
title('Simulated Current Variation');
xlabel('Time (h)');
ylabel('Current (A)');
grid on;
axis tight; 

% --- Plot 2: Simulated Temperature Variation ---
subplot(2, 3, 2);
plot(t, temp_sim, 'r-', 'LineWidth', 1.5); 
title('Simulated Temperature Variation');
xlabel('Time (h)');
ylabel('Temperature (°C)');
grid on;
axis tight;

% --- Plot 3: Battery SOH Variation ---
subplot(2, 3, 3);
plot(t, soh_sim, 'g-', 'LineWidth', 1.5); 
title('Battery State of Health Variation');
xlabel('Time (h)');
ylabel('SOH');
grid on;
axis tight;

% --- Plot 4: True SOC Variation ---
subplot(2, 3, 4);
plot(t, soc_sim, 'k-', 'LineWidth', 1.5); 
title('True SOC Variation');
xlabel('Time (h)');
ylabel('True SOC (%)');
grid on;
ylim([97 100]); 

% --- Plot 5: Current-SOC Relationship ---
subplot(2, 3, 5);
scatter(current_sim, soc_sim, 25, t, 'filled'); 
title('Current-SOC Relationship');
xlabel('Current (A)');
ylabel('SOC (%)');
grid on;
box on;
colormap(gca, 'parula'); 
c = colorbar; 
% c.Label.String = 'Time (h)'; % Optional label for colorbar

% --- Plot 6: Temperature-SOC Relationship ---
subplot(2, 3, 6);
scatter(temp_sim, soc_sim, 25, t, 'filled');
title('Temperature-SOC Relationship');
xlabel('Temperature (°C)');
ylabel('SOC (%)');
grid on;
box on;
colormap(gca, 'parula');
c = colorbar;

%% 3. Adjust Layout
set(gcf, 'Units', 'normalized');