import 'package:flutter/material.dart';
import 'package:skill_hub/features/home/domain/entities/skill.dart';
import 'package:skill_hub/features/home/presentation/widgets/skill_list_item.dart';

class SkillList extends StatelessWidget {
  final List<Skill> skills;
  final void Function(Skill skill)? onSkillTap;
  final bool isLoading;
  final bool showEmpty;

  const SkillList({
    super.key,
    required this.skills,
    this.onSkillTap,
    this.isLoading = false,
    this.showEmpty = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingList();
    }

    if (skills.isEmpty && showEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      itemCount: skills.length,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        return SkillListItem(
          skill: skills[index],
          onTap: onSkillTap != null ? () => onSkillTap!(skills[index]) : null,
        );
      },
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      itemCount: 5,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        return _buildShimmerItem(context);
      },
    );
  }

  Widget _buildShimmerItem(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Profile image placeholder
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),

            // Skill info placeholders
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title placeholder
                  Container(
                    height: 16,
                    width: 150,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Provider name placeholder
                  Container(
                    height: 12,
                    width: 100,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Category placeholder
                  Container(
                    height: 12,
                    width: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),

            // Rating placeholder
            Container(
              width: 40,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.amber.shade100.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 80,
            color: theme.colorScheme.primary.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No skills found',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'We couldn\'t find any skills matching your criteria',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
