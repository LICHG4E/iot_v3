import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:iot_v3/pages/providers/user_provider.dart';
import 'package:provider/provider.dart';

class CustomerSupportMail extends StatefulWidget {
  const CustomerSupportMail({super.key});

  @override
  State<CustomerSupportMail> createState() => _CustomerSupportMailState();
}

class _CustomerSupportMailState extends State<CustomerSupportMail> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSending = false; // To control spam and show loading state.

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> sendEmail(String emailBody, String subject) async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null || user.email == null) {
      // Handle the null user or email gracefully.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User email is not available.')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final Email email = Email(
        body: emailBody,
        subject: subject,
        recipients: ['jasser.hamdi@fsb.ucar.tn'],
        cc: [],
        bcc: [],
        attachmentPaths: [],
        isHTML: false,
      );
      await FlutterEmailSender.send(email);

      if (!mounted) return;

      // Show success message.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email sent successfully!')),
      );

      FocusScope.of(context).unfocus();
      _subjectController.clear();
      _bodyController.clear();
    } catch (e) {
      // Handle errors (e.g., failed email sending).
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send email: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Support'),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(24),
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
                  Icon(Icons.support_agent, size: 60, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    'We\'re Here to Help',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Send us your questions or feedback',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.edit_note,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Your Message',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Subject Field
                    TextFormField(
                      controller: _subjectController,
                      decoration: InputDecoration(
                        labelText: 'Subject',
                        hintText: 'Brief description of your issue',
                        prefixIcon: const Icon(Icons.subject),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a subject';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Body Field
                    TextFormField(
                      controller: _bodyController,
                      decoration: InputDecoration(
                        labelText: 'Message',
                        hintText: 'Describe your issue in detail...',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 120),
                          child: Icon(Icons.message),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                        alignLabelWithHint: true,
                      ),
                      maxLines: 8,
                      maxLength: 500,
                      textAlign: TextAlign.start,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your message';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    // Info Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'We typically respond within 24-48 hours',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Send Button
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isSending
                              ? [Colors.grey, Colors.grey]
                              : [
                                  Theme.of(context).primaryColor,
                                  Theme.of(context).primaryColor.withOpacity(0.8),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _isSending
                            ? []
                            : [
                                BoxShadow(
                                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isSending
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  sendEmail(_bodyController.text, _subjectController.text);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSending
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Send Email',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Alternative Contact Methods
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Other Ways to Reach Us',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.email_outlined, size: 18, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: SelectableText(
                          'plantCareSupport@gmail.com',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined, size: 18, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        '+216 12 345 678',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
