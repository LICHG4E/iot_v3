import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:iot_v3/pages/providers/settings_provider.dart';
import 'package:iot_v3/widgets/app_widgets.dart';
import 'package:provider/provider.dart';

class DeviceDataPage extends StatefulWidget {
  final String? deviceId;

  const DeviceDataPage({super.key, required this.deviceId});

  @override
  State<DeviceDataPage> createState() => _DeviceDataPageState();
}

class _DeviceDataPageState extends State<DeviceDataPage> {
  late List<Map<String, dynamic>> deviceData;
  Map<String, dynamic>? latestData;
  bool isLoading = true;
  String currentChart = 'humidity_percent';
  String currentChartTitle = 'Humidity';
  Timer? _timer;
  int chartPoints = 6;

  @override
  void initState() {
    super.initState();
    fetchDeviceData();
    _timer = Timer.periodic(Duration(minutes: Provider.of<SettingsProvider>(context, listen: false).getChartUpdateInterval, seconds: 1), (timer) {
      debugPrint('Fetching data...');
      fetchDeviceData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchDeviceData() async {
    try {
      chartPoints = Provider.of<SettingsProvider>(context, listen: false).getChartPoints;
      debugPrint("Chart Points: $chartPoints");
      final querySnapshot =
          await FirebaseFirestore.instance.collection('beaglebones').doc(widget.deviceId).collection('data').orderBy('timestamp', descending: true).limit(chartPoints).get();
      setState(() {
        debugPrint("Data fetched successfully");
        deviceData = querySnapshot.docs.map((doc) => doc.data()).toList();
        latestData = deviceData.isNotEmpty ? deviceData.first : null;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        AppWidgets.showSnackBar(
          context: context,
          message: 'Failed to fetch device data: ${e.toString()}',
          type: SnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final int divisor = isPortrait ? 250 : 200;
    final currentCount = (MediaQuery.of(context).size.width ~/ divisor).toInt();
    const minCount = 2;
    final crossAxisCount = max(currentCount, minCount);
    final theme = Theme.of(context);
    final isFireDetected = latestData?['fire_status'] == "Fire Detected!" || latestData?['fire_status'] == null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Device: ${widget.deviceId}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => fetchDeviceData(),
            tooltip: 'Refresh data',
          ),
        ],
      ),
      body: isLoading
          ? Center(child: AppWidgets.loadingIndicator())
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: fetchDeviceData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                      // Fire Status Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isFireDetected ? [Colors.red.shade600, Colors.red.shade800] : [Colors.green.shade400, Colors.green.shade600],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isFireDetected ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              )
                            ],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isFireDetected ? Icons.whatshot : Icons.fire_extinguisher,
                                  size: 32,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Fire Status',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      latestData?['fire_status'] ?? 'Unknown',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isFireDetected)
                                Icon(
                                  Icons.warning,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  size: 28,
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Light Status Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).shadowColor.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  getTimeIcon(latestData?['light_description']),
                                  size: 28,
                                  color: theme.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ambient Light',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      latestData?['light_description'] ?? 'Unknown',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Sensor Cards Grid
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GridView.count(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12.0,
                          mainAxisSpacing: 12.0,
                          childAspectRatio: 1.0,
                          children: [
                            GestureDetector(
                              onTap: () => changeChart('humidity_percent'),
                              child: ModernDataCard(
                                title: 'Humidity',
                                value: '${formatValue(latestData?['humidity_percent'])}%',
                                icon: Icons.water_drop,
                                isSelected: currentChart == 'humidity_percent',
                                gradient: LinearGradient(
                                  colors: [Colors.blue.shade300, Colors.blue.shade500],
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => changeChart('pressure_hpa'),
                              child: ModernDataCard(
                                title: 'Pressure',
                                value: '${formatValue(latestData?['pressure_hpa'])} hPa',
                                icon: Icons.compress,
                                isSelected: currentChart == 'pressure_hpa',
                                gradient: LinearGradient(
                                  colors: [Colors.purple.shade300, Colors.purple.shade500],
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => changeChart('temperature_celsius'),
                              child: ModernDataCard(
                                title: 'Temperature',
                                value: '${formatValue(latestData?['temperature_celsius'])}°C',
                                icon: Icons.thermostat,
                                isSelected: currentChart == 'temperature_celsius',
                                gradient: LinearGradient(
                                  colors: [Colors.orange.shade300, Colors.orange.shade500],
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => changeChart('light_intensity_percent'),
                              child: ModernDataCard(
                                title: 'Light Intensity',
                                value: '${formatLightValue(latestData?['light_intensity_percent'])}%',
                                icon: Icons.lightbulb,
                                isSelected: currentChart == 'light_intensity_percent',
                                gradient: LinearGradient(
                                  colors: [Colors.amber.shade300, Colors.amber.shade600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Chart Section
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).shadowColor.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.show_chart, size: 24, color: theme.primaryColor),
                                const SizedBox(width: 8),
                                Text(
                                  '$currentChartTitle Over Time',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 280,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: LineChart(
                                  getLineChart(currentChart),
                                  duration: const Duration(milliseconds: 300),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  List<FlSpot> getLineChartData(String dataKey) {
    return deviceData.map((data) {
      var timestamp = (data['timestamp'] as Timestamp).seconds;
      double value = double.parse(data[dataKey].toDouble().toStringAsFixed(2));
      return FlSpot(timestamp.toDouble(), value);
    }).toList();
  }

  IconData? getTimeIcon(String description) {
    if (description == "Afternoon") {
      return FontAwesomeIcons.sun;
    } else if (description == "Sunrise/Sunset") {
      return Icons.wb_twilight;
    } else if (description == "Morning") {
      return Icons.circle;
    } else if (description == "Night") {
      return FontAwesomeIcons.moon;
    }
    return null;
  }

  String formatValue(dynamic value) {
    try {
      return double.parse(value.toString()).toStringAsFixed(1);
    } catch (e) {
      return "N/A";
    }
  }

  String formatLightValue(dynamic value) {
    try {
      return (100 - double.parse(value.toString())).toStringAsFixed(1);
    } catch (e) {
      return "N/A";
    }
  }

  void changeChart(String key) {
    setState(() {
      currentChart = key;
      if (key == 'humidity_percent') {
        currentChartTitle = 'Humidity';
      } else if (key == 'pressure_hpa') {
        currentChartTitle = 'Pressure';
      } else if (key == 'temperature_celsius') {
        currentChartTitle = 'Temperature';
      } else if (key == 'light_intensity_percent') {
        currentChartTitle = 'Light Intensity';
      }
    });
  }

  LineChartData getLineChart(String dataKey) {
    double minValue = deviceData.map((data) => data[dataKey]?.toDouble() ?? 0.0).reduce((a, b) => a < b ? a : b);
    double maxValue = deviceData.map((data) => data[dataKey]?.toDouble() ?? 0.0).reduce((a, b) => a > b ? a : b);

    double padding = (maxValue - minValue) * 0.1;
    double adjustedMinY = minValue - padding;
    double adjustedMaxY = maxValue + padding;

    return LineChartData(
      lineTouchData: const LineTouchData(enabled: true),
      gridData: const FlGridData(
        show: true,
        drawHorizontalLine: true,
        drawVerticalLine: true,
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            minIncluded: false,
            maxIncluded: false,
            getTitlesWidget: (value, meta) {
              DateTime date = DateTime.fromMillisecondsSinceEpoch(value.toInt() * 1000);

              return SideTitleWidget(
                axisSide: meta.axisSide,
                space: 5,
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${date.hour}:${date.minute.toString().padLeft(2, '0')}\n',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      TextSpan(
                        text: '${date.month}/${date.day}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
          ),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(
            showTitles: false, // Disable titles on the right side
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            maxIncluded: false,
            minIncluded: false,
            reservedSize: 60,
            getTitlesWidget: (value, meta) {
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 12),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xff37434d)),
      ),
      minX: deviceData.last['timestamp'].seconds.toDouble(),
      maxX: deviceData.first['timestamp'].seconds.toDouble(),
      minY: adjustedMinY,
      maxY: adjustedMaxY,
      lineBarsData: [
        LineChartBarData(
          preventCurveOverShooting: true,
          spots: getLineChartData(dataKey),
          isCurved: true,
          curveSmoothness: 1,
          isStrokeJoinRound: true,
          gradient: const LinearGradient(
            colors: [Colors.green, Colors.greenAccent],
          ),
          barWidth: 5,
          isStrokeCapRound: true,
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                Colors.green.withOpacity(0.3),
                Colors.lightGreenAccent.withOpacity(0.3),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ModernDataCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isSelected;
  final Gradient gradient;

  const ModernDataCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.isSelected = false,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: isSelected ? gradient : null,
        color: isSelected ? null : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isSelected ? null : Border.all(color: Colors.grey.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: isSelected ? gradient.colors.first.withOpacity(0.3) : Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: isSelected ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.2) : theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: isSelected ? Theme.of(context).colorScheme.onPrimary : theme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Theme.of(context).colorScheme.onPrimary : theme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
