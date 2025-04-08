import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/custom_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),

              // App Logo and Name
              Icon(
                Icons.handyman_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Find skilled professionals or share your skills',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),

              const Spacer(),

              // Feature highlights
              _buildFeatureItem(
                context,
                Icons.workspace_premium,
                'Discover Skilled Professionals',
                'Find experts for all your needs',
              ),
              const SizedBox(height: 24),
              _buildFeatureItem(
                context,
                Icons.handshake,
                'Share Your Skills',
                'Offer your services and earn',
              ),
              const SizedBox(height: 24),
              _buildFeatureItem(
                context,
                Icons.location_on,
                'Local & Remote Work',
                'Connect with nearby or online professionals',
              ),

              const Spacer(),

              // Action buttons
              CustomButton(
                text: 'Get Started',
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/signin'),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Already have an account? Sign In',
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/signin'),
                isOutlined: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
