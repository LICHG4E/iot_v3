import 'package:flutter/material.dart';
import 'package:iot_v3/app_theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'settings_provider.dart';

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
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Settings',
        ),
      ),
      body: Consumer2<SettingsProvider, ThemeProvider>(
        builder: (context, settings, theme, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              SwitchListTile(
                title: const Text('Change Theme'),
                value: theme.isLight,
                onChanged: (value) {
                  theme.toggleTheme(value);
                },
                activeColor: Theme.of(context).primaryColor,
                thumbIcon: WidgetStatePropertyAll(theme.isLight ? const Icon(Icons.light_mode) : const Icon(Icons.dark_mode)),
              ),
              const SizedBox(height: 16),
              // Push Notifications Toggle
              SwitchListTile(
                title: const Text('Push Notifications'),
                value: settings.pushNotifications,
                onChanged: (value) {
                  settings.setPushNotifications(value);
                },
                activeColor: Theme.of(context).primaryColor,
                thumbIcon: WidgetStatePropertyAll(
                    settings.pushNotifications ? const Icon(Icons.notifications) : const Icon(Icons.notifications_off)),
              ),

              const SizedBox(height: 16),

              // Number of Minutes Selector
              _buildNumberSelector(
                title: 'Chart Update Interval (Minutes)',
                value: settings.chartUpdateInterval,
                onChanged: (value) {
                  settings.setNumberOfMinutes(value.toInt());
                },
              ),
              const SizedBox(height: 16),

              // Temperature Range
              _buildRangeSlider(
                title: 'Temperature Range (°C)',
                min: 0,
                max: 50,
                currentMin: settings.minTemperature,
                currentMax: settings.maxTemperature,
                onChanged: (start, end) {
                  settings.setMinTemperature(start);
                  settings.setMaxTemperature(end);
                },
                onInputChanged: (min, max) {
                  settings.setMinTemperature(min);
                  settings.setMaxTemperature(max);
                },
              ),
              const SizedBox(height: 16),

              // Humidity Range
              _buildRangeSlider(
                title: 'Humidity Range (%)',
                min: 0,
                max: 100,
                currentMin: settings.minHumidity,
                currentMax: settings.maxHumidity,
                onChanged: (start, end) {
                  settings.setMinHumidity(start);
                  settings.setMaxHumidity(end);
                },
                onInputChanged: (min, max) {
                  settings.setMinHumidity(min);
                  settings.setMaxHumidity(max);
                },
              ),
              const SizedBox(height: 16),

              // Pressure Range
              _buildRangeSlider(
                title: 'Pressure Range (hPa)',
                min: 900,
                max: 1100,
                currentMin: settings.minPressure,
                currentMax: settings.maxPressure,
                onChanged: (start, end) {
                  settings.setMinPressure(start);
                  settings.setMaxPressure(end);
                },
                onInputChanged: (min, max) {
                  settings.setMinPressure(min);
                  settings.setMaxPressure(max);
                },
              ),
              const SizedBox(height: 16),

              // Light Percentage Range
              _buildRangeSlider(
                title: 'Light Percentage Range (%)',
                min: 0,
                max: 100,
                currentMin: settings.minLightPercentage,
                currentMax: settings.maxLightPercentage,
                onChanged: (start, end) {
                  settings.setMinLightPercentage(start);
                  settings.setMaxLightPercentage(end);
                },
                onInputChanged: (min, max) {
                  settings.setMinLightPercentage(min);
                  settings.setMaxLightPercentage(max);
                },
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildNumberSelector({
    required String title,
    required int value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16)),
        SliderTheme(
          data: SliderThemeData(
            thumbColor: Colors.green,
            trackHeight: 16,
            activeTrackColor: Colors.green.withOpacity(0.5),
            inactiveTrackColor: Colors.grey.withOpacity(0.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Slider(
                  value: value.toDouble(),
                  min: 1,
                  max: 30,
                  divisions: 29,
                  label: '$value',
                  onChanged: onChanged,
                ),
              ),
              Text('$value', style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRangeSlider({
    required String title,
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
        Text(title, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 16),
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: minController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Min'),
                    onEditingComplete: handleInputChange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
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
      ],
    );
  }
}
