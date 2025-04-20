import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/home/domain/entities/skill.dart';
import '../../../../features/home/presentation/widgets/skill_card.dart';
import '../../../../features/home/data/repositories/skill_repository.dart';
import '../widgets/search_suggestions.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: const Center(
        child: Text('Search Page Coming Soon'),
      ),
    );
  }
}
