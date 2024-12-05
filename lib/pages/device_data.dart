import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import 'drawer_pages/settings_provider.dart';

class DeviceDataPage extends StatefulWidget {
  final String? deviceId;

  const DeviceDataPage({super.key, required this.deviceId});

  @override
  State<DeviceDataPage> createState() => _DeviceDataPageState();
}

class _DeviceDataPageState extends State<DeviceDataPage> {
  late List<Map<String, dynamic>> deviceData;
  late Map<String, dynamic>? latestData;
  bool isLoading = true;
  String currentChart = 'humidity_percent';
  String currentChartTitle = 'Humidity';
  Timer? _timer;
  int chartPoints = 6;

  @override
  void initState() {
    super.initState();
    fetchDeviceData();
    _timer = Timer.periodic(
        Duration(minutes: Provider.of<SettingsProvider>(context, listen: false).getChartUpdateInterval, seconds: 1), (timer) {
      print('Fetching data...');
      fetchDeviceData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchDeviceData() async {
    chartPoints = Provider.of<SettingsProvider>(context, listen: false).getChartPoints;
    print("Chart Points: $chartPoints");
    final querySnapshot = await FirebaseFirestore.instance
        .collection('beaglebones')
        .doc(widget.deviceId)
        .collection('data')
        .orderBy('timestamp', descending: true)
        .limit(chartPoints)
        .get();
    setState(() {
      print("Data fetched successfully");
      deviceData = querySnapshot.docs.map((doc) => doc.data()).toList();
      latestData = deviceData.first;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Device : ${widget.deviceId}')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: latestData?['fire_status'] == "Fire Detected!" || latestData?['fire_status'] == null
                              ? Colors.red
                              : Theme.of(context).cardColor,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            )
                          ],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.fire_extinguisher, size: 32),
                            const SizedBox(width: 8),
                            Text('Fire Status : ${latestData?['fire_status']}', style: Theme.of(context).textTheme.titleLarge),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            )
                          ],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(getTimeIcon(latestData?['light_description']), size: 32),
                            const SizedBox(width: 8),
                            Text('Light : ${latestData?['light_description']}', style: Theme.of(context).textTheme.titleLarge),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.count(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        crossAxisCount: 2,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                        children: [
                          GestureDetector(
                            onTap: () => changeChart('humidity_percent'),
                            child: DataCard(
                              title: 'Humidity',
                              value: '${formatValue(latestData?['humidity_percent'])}%',
                              icon: Icons.water_drop,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => changeChart('pressure_hpa'),
                            child: DataCard(
                              title: 'Pressure',
                              value: '${formatValue(latestData?['pressure_hpa'])} hPa',
                              icon: Icons.compress,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => changeChart('temperature_celsius'),
                            child: DataCard(
                              title: 'Temperature',
                              value: '${formatValue(latestData?['temperature_celsius'])}°C',
                              icon: Icons.thermostat,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => changeChart('light_intensity_percent'),
                            child: DataCard(
                              title: 'Light Intensity',
                              value: '${formatLightValue(latestData?['light_intensity_percent'])}%',
                              icon: Icons.lightbulb,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.data_usage, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          currentChartTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      height: 300,
                      padding: const EdgeInsets.only(left: 16, right: 40, top: 20, bottom: 20),
                      child: LineChart(
                        getLineChart(currentChart),
                        duration: const Duration(milliseconds: 300),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
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

class DataCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const DataCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
