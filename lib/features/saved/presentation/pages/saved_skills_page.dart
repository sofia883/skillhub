import 'package:flutter/material.dart';
import 'package:skill_hub/core/theme/app_theme.dart';
import 'package:skill_hub/core/widgets/custom_button.dart';

class SavedSkillsPage extends StatelessWidget {
  const SavedSkillsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Skills'),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 100,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            const Text(
              'No Saved Skills Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Save skills you\'re interested in to view them later',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Explore Skills',
              onPressed: () {
                // Navigate back to home screen
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
