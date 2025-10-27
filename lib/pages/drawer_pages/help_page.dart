import 'package:flutter/material.dart';
import 'package:iot_v3/constants/routes.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  // Example FAQs with categories
  final List<Map<String, dynamic>> _faqs = [
    {
      'category': 'Account',
      'icon': Icons.person,
      'color': Colors.blue,
      'question': 'How do I update my profile?',
      'answer': 'Go to the drawer menu from the home page, select "Profile", and update your information.'
    },
    {
      'category': 'Account',
      'icon': Icons.email,
      'color': Colors.blue,
      'question': 'How do I change my email address?',
      'answer': 'Navigate to Profile in the drawer menu. You can update your email there after verifying your current email.'
    },
    {
      'category': 'Security',
      'icon': Icons.lock,
      'color': Colors.red,
      'question': 'How do I change my password?',
      'answer': 'Go to Profile from the drawer menu and enter a new password in the password field.'
    },
    {
      'category': 'Settings',
      'icon': Icons.notifications,
      'color': Colors.orange,
      'question': 'How do I change my notification settings?',
      'answer': 'Open Settings from the drawer menu to customize your notification preferences.'
    },
    {
      'category': 'Settings',
      'icon': Icons.palette,
      'color': Colors.purple,
      'question': 'How do I change my theme?',
      'answer': 'Go to Settings in the drawer menu and toggle between Light and Dark mode.'
    },
    {
      'category': 'Support',
      'icon': Icons.support_agent,
      'color': Colors.green,
      'question': 'How can I contact customer support?',
      'answer': 'Use the "Contact Support" button below to send us an email directly.'
    },
    {
      'category': 'Account',
      'icon': Icons.delete,
      'color': Colors.red,
      'question': 'How do I delete my account?',
      'answer': 'Please contact customer support to request account deletion.'
    },
    {
      'category': 'Support',
      'icon': Icons.bug_report,
      'color': Colors.amber,
      'question': 'I found a bug. How do I report it?',
      'answer': 'Contact customer support with detailed information about the bug. Screenshots are helpful!'
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
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Icon(Icons.help_outline, size: 60, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    'How can we help you?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Find answers to common questions below',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section Title
            Row(
              children: [
                Icon(Icons.question_answer, color: Theme.of(context).primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Frequently Asked Questions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // FAQs with Modern Cards
            ..._faqs.map((faq) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
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
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (faq['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        faq['icon'] as IconData,
                        color: faq['color'] as Color,
                        size: 24,
                      ),
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          faq['category'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          faq['question'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 20,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                faq['answer'] as String,
                                style: const TextStyle(fontSize: 14, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 24),

            // Contact Support Button
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, customerSupportPage);
                },
                icon: const Icon(Icons.support_agent, size: 24),
                label: const Text(
                  'Contact Support',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
