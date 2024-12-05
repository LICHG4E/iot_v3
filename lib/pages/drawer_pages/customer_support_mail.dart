import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:iot_v3/pages/drawer_pages/user_provider.dart';
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

      // Show success message.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email sent successfully!')),
      );

      if (mounted) {
        FocusScope.of(context).unfocus();
      }

      _subjectController.clear();
      _bodyController.clear();
    } catch (e) {
      // Handle errors (e.g., failed email sending).
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send email: $e')),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Support'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a subject';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _bodyController,
                decoration: const InputDecoration(
                  labelText: 'Body',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 10,
                textAlign: TextAlign.start,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the email body';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _isSending
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          sendEmail(_bodyController.text, _subjectController.text);
                        }
                      },
                child: _isSending
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text('Send Email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
