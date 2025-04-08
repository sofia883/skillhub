import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _requestSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      // In a real app, you would implement password reset logic here
      setState(() {
        _isLoading = true;
      });

      // Simulate API call
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _isLoading = false;
          _requestSent = true;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: _requestSent
                ? _buildSuccessView(context)
                : _buildFormView(context),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Icon
        Icon(
          Icons.lock_reset,
          size: 80,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 24),

        // Title
        Text(
          'Reset Your Password',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 16),

        // Description
        Text(
          'Enter your email address and we\'ll send you instructions to reset your password.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 32),

        // Email Field
        CustomTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'Enter your email',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.validateEmail,
        ),
        const SizedBox(height: 32),

        // Submit Button
        CustomButton(
          text: 'Send Reset Link',
          onPressed: _handleSubmit,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 24),

        // Back to Login
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Back to Sign In',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Success Icon
        Icon(
          Icons.check_circle_outline,
          size: 100,
          color: Colors.green,
        ),
        const SizedBox(height: 24),

        // Success Title
        Text(
          'Email Sent!',
          style: Theme.of(context).textTheme.displayMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Success Message
        Text(
          'We have sent password reset instructions to\n${_emailController.text}',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Back to Login Button
        CustomButton(
          text: 'Back to Sign In',
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(height: 16),

        // Resend Button
        TextButton(
          onPressed: _handleSubmit,
          child: Text(
            'Didn\'t receive the email? Send again',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
