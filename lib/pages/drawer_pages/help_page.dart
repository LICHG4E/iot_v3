import 'package:flutter/material.dart';
import 'package:iot_v3/constants/routes.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  // Example FAQs
  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I update my profile?',
      'answer': 'Go to home page , in the drawer click on profile and update your profile.'
    },
    {
      'question': 'How do I change my email address?',
      'answer': 'Go to home page , in the drawer click on profile and update your email address.'
    },
    {
      'question': 'How do I change my password?',
      'answer': 'Go to home page , in the drawer click on profile and update your password.'
    },
    {
      'question': 'How can I contact customer support?',
      'answer': 'Use the "Contact Support" button on this page to reach out to us.'
    },
    {'question': 'How do I delete my account?', 'answer': 'Contact customer support to delete your account.'},
    {
      'question': 'How do I change my notification settings?',
      'answer': 'Go to home page , in the drawer click on settings and update your notification settings.'
    },
    {
      'question': 'How do I change my theme?',
      'answer': 'Go to home page , in the drawer click on settings and update your theme.'
    },
    {
      'question': 'I found a bug. How do I report it?',
      'answer': 'Contact customer support to report any bugs. Please provide as much detail as possible.'
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Title
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // FAQs with ExpansionTile
            ..._faqs.map((faq) {
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ExpansionTile(
                  title: Text(
                    faq['question']!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text(
                        faq['answer']!,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 20),

            // Contact Support Button
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, customerSupportPage);
                },
                icon: const Icon(Icons.support_agent),
                label: const Text('Contact Support'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
