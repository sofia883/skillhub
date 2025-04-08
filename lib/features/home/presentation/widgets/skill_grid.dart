import 'package:flutter/material.dart';
import 'package:skill_hub/features/home/domain/entities/skill.dart';
import 'package:skill_hub/features/home/presentation/widgets/skill_card.dart';

class SkillGrid extends StatelessWidget {
  final List<Skill> skills;
  final Function(Skill) onSkillTap;

  const SkillGrid({
    Key? key,
    required this.skills,
    required this.onSkillTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 16,
      ),
      itemCount: skills.length,
      itemBuilder: (context, index) {
        final skill = skills[index];
        return SkillCard(
          skill: skill,
          onTap: () => onSkillTap(skill),
        );
      },
    );
  }
}
