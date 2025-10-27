import 'package:flutter/material.dart';
import 'package:iot_v3/app_theme/theme_provider.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: Consumer2<SettingsProvider, ThemeProvider>(
        builder: (context, settings, theme, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // GENERAL SETTINGS SECTION
              _buildSectionHeader(context, 'General', Icons.settings),
              const SizedBox(height: 12),
              _buildModernCard(
                context,
                child: Column(
                  children: [
                    _buildModernSwitchTile(
                      context: context,
                      title: 'Theme Mode',
                      subtitle: theme.isLight ? 'Light' : 'Dark',
                      icon: theme.isLight ? Icons.light_mode : Icons.dark_mode,
                      iconColor: theme.isLight ? Colors.amber : Colors.indigo,
                      value: theme.isLight,
                      onChanged: (value) {
                        theme.toggleTheme(value);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Theme changed to ${value ? 'Light' : 'Dark'} mode'),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _buildModernSwitchTile(
                      context: context,
                      title: 'Push Notifications',
                      subtitle: 'Receive alerts for your devices',
                      icon: Icons.notifications_active,
                      iconColor: Colors.blue,
                      value: settings.pushNotifications,
                      onChanged: (value) => settings.setPushNotifications(value),
                    ),
                    const Divider(height: 1),
                    _buildModernSwitchTile(
                      context: context,
                      title: 'Fire Alerts',
                      subtitle: 'Urgent fire detection notifications',
                      icon: Icons.local_fire_department,
                      iconColor: Colors.red,
                      value: settings.pushFireNotifications,
                      onChanged: (value) => settings.setPushFireNotifications(value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // CHART SETTINGS SECTION
              _buildSectionHeader(context, 'Chart Display', Icons.show_chart),
              const SizedBox(height: 12),
              _buildModernCard(
                context,
                child: _buildNumberSelector(
                  context: context,
                  title: 'Chart Data Points',
                  subtitle: 'Number of points displayed on charts',
                  icon: Icons.analytics,
                  iconColor: Colors.purple,
                  value: settings.chartPoints,
                  onChanged: (value) => settings.setChartPoints(value.toInt()),
                ),
              ),
              const SizedBox(height: 24),

              // SENSOR THRESHOLDS SECTION
              _buildSectionHeader(context, 'Sensor Thresholds', Icons.tune),
              const SizedBox(height: 12),

              // Temperature
              _buildModernCard(
                context,
                child: _buildThresholdExpansionTile(
                  context: context,
                  title: 'Temperature',
                  icon: Icons.thermostat,
                  iconColor: Colors.orange,
                  unit: '°C',
                  enabled: settings.isTemperatureRangeEnabled,
                  onEnabledChanged: (value) => settings.setIsTemperatureRangeEnabled(value),
                  min: 0,
                  max: 50,
                  currentMin: settings.minTemperature,
                  currentMax: settings.maxTemperature,
                  onRangeChanged: (start, end) {
                    settings.setMinTemperature(start);
                    settings.setMaxTemperature(end);
                  },
                  onInputChanged: (min, max) {
                    settings.setMinTemperature(min);
                    settings.setMaxTemperature(max);
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Humidity
              _buildModernCard(
                context,
                child: _buildThresholdExpansionTile(
                  context: context,
                  title: 'Humidity',
                  icon: Icons.water_drop,
                  iconColor: Colors.blue,
                  unit: '%',
                  enabled: settings.isHumidityRangeEnabled,
                  onEnabledChanged: (value) => settings.setIsHumidityRangeEnabled(value),
                  min: 0,
                  max: 100,
                  currentMin: settings.minHumidity,
                  currentMax: settings.maxHumidity,
                  onRangeChanged: (start, end) {
                    settings.setMinHumidity(start);
                    settings.setMaxHumidity(end);
                  },
                  onInputChanged: (min, max) {
                    settings.setMinHumidity(min);
                    settings.setMaxHumidity(max);
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Pressure
              _buildModernCard(
                context,
                child: _buildThresholdExpansionTile(
                  context: context,
                  title: 'Pressure',
                  icon: Icons.compress,
                  iconColor: Colors.purple,
                  unit: 'hPa',
                  enabled: settings.isPressureRangeEnabled,
                  onEnabledChanged: (value) => settings.setIsPressureRangeEnabled(value),
                  min: 900,
                  max: 1100,
                  currentMin: settings.minPressure,
                  currentMax: settings.maxPressure,
                  onRangeChanged: (start, end) {
                    settings.setMinPressure(start);
                    settings.setMaxPressure(end);
                  },
                  onInputChanged: (min, max) {
                    settings.setMinPressure(min);
                    settings.setMaxPressure(max);
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Light
              _buildModernCard(
                context,
                child: _buildThresholdExpansionTile(
                  context: context,
                  title: 'Light Level',
                  icon: Icons.lightbulb,
                  iconColor: Colors.amber,
                  unit: '%',
                  enabled: settings.isLightRangeEnabled,
                  onEnabledChanged: (value) => settings.setIsLightRangeEnabled(value),
                  min: 0,
                  max: 100,
                  currentMin: settings.minLightPercentage,
                  currentMax: settings.maxLightPercentage,
                  onRangeChanged: (start, end) {
                    settings.setMinLightPercentage(start);
                    settings.setMaxLightPercentage(end);
                  },
                  onInputChanged: (min, max) {
                    settings.setMinLightPercentage(min);
                    settings.setMaxLightPercentage(max);
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
        ),
      ],
    );
  }

  Widget _buildModernCard(BuildContext context, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildModernSwitchTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildThresholdExpansionTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required String unit,
    required bool enabled,
    required ValueChanged<bool> onEnabledChanged,
    required double min,
    required double max,
    required double currentMin,
    required double currentMax,
    required Function(double, double) onRangeChanged,
    required Function(double, double) onInputChanged,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          enabled ? '${currentMin.toStringAsFixed(1)} - ${currentMax.toStringAsFixed(1)} $unit' : 'Monitoring disabled',
          style: TextStyle(
            fontSize: 13,
            color: enabled ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        trailing: Switch(
          value: enabled,
          onChanged: onEnabledChanged,
          activeColor: Theme.of(context).primaryColor,
        ),
        children: [
          _buildRangeSlider(
            enabled: enabled,
            min: min,
            max: max,
            currentMin: currentMin,
            currentMax: currentMax,
            onChanged: onRangeChanged,
            onInputChanged: onInputChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildNumberSelector({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required int value,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              thumbColor: Theme.of(context).primaryColor,
              trackHeight: 4,
              activeTrackColor: Theme.of(context).primaryColor,
              inactiveTrackColor: Theme.of(context).primaryColor.withOpacity(0.2),
            ),
            child: Slider(
              value: value.toDouble(),
              min: 1,
              max: 30,
              divisions: 29,
              label: '$value points',
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeSlider({
    required bool enabled,
    required double min,
    required double max,
    required double currentMin,
    required double currentMax,
    required Function(double, double) onChanged,
    required Function(double, double) onInputChanged,
  }) {
    final minController = TextEditingController(text: currentMin.toStringAsFixed(1));
    final maxController = TextEditingController(text: currentMax.toStringAsFixed(1));

    void handleInputChange() {
      final inputMin = double.tryParse(minController.text) ?? min;
      final inputMax = double.tryParse(maxController.text) ?? max;

      // Clamp values to valid range
      final clampedMin = inputMin.clamp(min, max);
      final clampedMax = inputMax.clamp(min, max);

      if (clampedMin <= clampedMax) {
        onInputChanged(clampedMin, clampedMax);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AbsorbPointer(
          absorbing: !enabled,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      enabled: enabled,
                      controller: minController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Min'),
                      onEditingComplete: handleInputChange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      enabled: enabled,
                      controller: maxController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Max'),
                      onEditingComplete: handleInputChange,
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderThemeData(
                  thumbColor: Colors.green,
                  trackHeight: 16,
                  activeTrackColor: Colors.green.withOpacity(0.5),
                  inactiveTrackColor: Colors.grey.withOpacity(0.5),
                ),
                child: RangeSlider(
                  values: RangeValues(currentMin, currentMax),
                  min: min,
                  max: max,
                  divisions: 50,
                  labels: RangeLabels(
                    currentMin.toStringAsFixed(1),
                    currentMax.toStringAsFixed(1),
                  ),
                  onChanged: (values) {
                    onChanged(values.start, values.end);
                    minController.text = values.start.toStringAsFixed(1);
                    maxController.text = values.end.toStringAsFixed(1);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
