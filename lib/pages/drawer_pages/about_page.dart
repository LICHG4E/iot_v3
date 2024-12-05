import 'package:flutter/material.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Overview Section
            Text(
              'App Overview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            const Text(
              'Our app is designed to revolutionize the way farmers and agricultural professionals monitor their fields and greenhouses. '
              'By connecting IoT devices, users can track environmental data like temperature, humidity, and soil moisture in real-time. '
              'It also provides plant disease detection capabilities to ensure healthier crops.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            // Features Section
            Text(
              'Key Features',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            const Text(
              '- IoT Integration: Monitor data from IoT devices placed in fields or greenhouses in real-time.\n'
              '- Threshold Alerts: Receive instant notifications if parameters like temperature or humidity exceed user-defined thresholds.\n'
              '- Plant Disease Scanner: Use the built-in scanner to identify potential diseases affecting your crops.\n'
              '- Data Insights: Visualize historical data trends to make informed decisions.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            // Developer Team Section
            Text(
              'Meet the Team',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            const Text(
              'This app was developed by a passionate team of software engineering students:\n\n'
              '- **Jasser Hamdi**\n'
              '- **Mohamed Taha Sta**\n'
              '- **Fares Makki**\n\n'
              'Our mission is to leverage technology to create efficient and sustainable solutions for modern agriculture.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            // Contact Information
            Text(
              'Get in Touch',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            const Text(
              'If you have any questions, feedback, or suggestions, feel free to reach out to us at:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            const SelectableText(
              'Email: plantCareSupport@gmail.com\nPhone: +216 12 345 678',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Version Info
            const Divider(),
            const Center(
              child: Text(
                'Version 1.0.0',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
